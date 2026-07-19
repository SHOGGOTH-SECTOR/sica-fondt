# Trader-Wallet-Marketplace API Surface Designs

## Overview

Three radically different API shapes for how traders submit actions, receive predictions, and interact with wallet binding. Each prioritizes different architectural values: **A** minimizes attack surface and dependencies; **B** emphasizes auditability and replay; **C** optimizes for type safety and live data.

---

## Design A: Minimal Capability-Token Surface

**Philosophy:** Stateless, HMAC-authenticated, two core endpoints. Trader auth is unforgeable capability tokens. Predictions and state are ephemeral — traders make decisions from momentary snapshots. Simplicity is security.

### Method Signatures

```rust
// Core entry point: submit action with signed token
fn submit_action(
  token: CapabilityToken,        // HMAC(trader_id + wallet_id + action_hash + timestamp)
  action: MarketAction,
  wallet_id: WalletId,
) -> Result<ExecutionReceipt, ViolationOrVeto>

// Single query endpoint: predictions + wallet state
fn query_market_snapshot(
  token: CapabilityToken,
) -> Result<MarketSnapshot, TokenExpiredError>
```

### Token Structure

```
CapabilityToken = {
  trader_id: TradeId,
  wallet_id: WalletId,
  action_class: &str,            // "buy" | "sell" | "mint" | etc.
  nonce: u64,                    // prevents replay within TTL window
  issued_at: Timestamp,
  expires_at: Timestamp,         // 30s TTL
  signature: HmacSha256(
    concat(trader_id, wallet_id, action_class, nonce, issued_at, expires_at),
    shared_secret
  )
}
```

### Trader → Marketplace Flow

```
1. Trader generates CapabilityToken locally (has shared_secret, trader_id, wallet_id)
2. Trader calls query_market_snapshot(token)
   → Marketplace verifies HMAC(token)
   → Returns MarketSnapshot { predictions, wallet_balance, current_gas_price }
3. Trader formulates MarketAction offline
4. Trader generates new CapabilityToken(action_class = action.type())
5. Trader calls submit_action(token, action, wallet_id)
   → Marketplace verifies HMAC(token) and action.type matches token.action_class
   → law_check(action) → if fail: return ViolationError
   → veto_check(action, trader_id) → if fail: return VetoError
   → wallet.sign() → execute() on chain → return ExecutionReceipt or ExecutionError
6. No polling. Action is fire-and-forget; trader checks balance later if desired.
```

### Error Handling

```rust
pub enum MarketplaceError {
  TokenExpired,              // 30s window expired
  TokenInvalid,              // HMAC verification failed
  WalletNotBound,            // trader_id has no wallet
  LawViolation {
    rule_id: String,
    reason: String,          // e.g., "position_limit_exceeded"
  },
  VetoedByConduct {
    reason: String,          // e.g., "risk_score_exceeded"
  },
  WalletSignFailed,          // key management error
  ChainExecutionFailed {
    tx_hash: Option<Hash256>, // may have been broadcast
    reason: String,
  },
  Timeout,                   // RPC didn't respond
}
```

### Law Script Invocation

**In-process pure function.** Law script is loaded at startup as a compiled deterministic rule engine (no I/O, no loops). Invoked as:

```rust
fn law_check(action: &MarketAction) -> Result<(), LawViolation> {
  // Loaded once at startup; immutable at runtime
  LAW_ENGINE.evaluate(&action)
}
```

Law script format (declarative, non-Turing):
```
rule "position_limit" {
  when action.type == "buy" && action.quantity > 10
  then violation("P001", "position exceeds 10 units")
}
```

### Extensibility

**Adding new action types:**
1. Add variant to `MarketAction` enum
2. Update law script with new rules
3. Restart marketplace (law script is immutable; changes require restart + operator + Homunculus signatures)
4. Traders regenerate capability tokens with new `action_class`

**Adding new constraint:**
1. Edit law script file
2. Restart marketplace with signatures
3. Constraint applies to all future actions automatically (law engine re-evaluates)

**Limitations:**
- No runtime configuration
- Hard restart required for law changes
- Requires cryptographic coordination to restart with signatures

### Testability

```rust
#[cfg(test)]
mod tests {
  #[test]
  fn test_law_violation_blocks_action() {
    let action = MarketAction::Buy { quantity: 100, ... };
    let result = law_check(&action);
    assert!(matches!(result, Err(LawViolation { rule_id: "P001", ... })));
  }

  #[test]
  fn test_valid_capability_token() {
    let token = gen_token(trader_id, wallet_id, "buy", secret);
    assert!(verify_hmac(&token, secret));
  }

  #[test]
  fn test_expired_token_rejected() {
    let token = gen_token_with_expiry(issued_at, expires_at - 60s);
    assert!(matches!(
      submit_action(&token, action, wallet),
      Err(MarketplaceError::TokenExpired)
    ));
  }

  #[test]
  fn test_veto_blocks_approved_action() {
    let action = MarketAction::Buy { /* complies with law */ };
    let token = gen_token(...);
    // Mock Conductor veto
    conductor_mock.set_veto(true);
    let result = submit_action(&token, action, wallet_id);
    assert!(matches!(result, Err(MarketplaceError::VetoedByConduct)));
  }

  #[test]
  fn test_law_engine_deterministic() {
    // Same action, same law script, same result always
    for _ in 0..100 {
      assert_eq!(
        law_check(&action),
        law_check(&action)
      );
    }
  }

  // Unit test law script rules in isolation
  #[test]
  fn test_rule_position_limit() {
    let rule = law_engine.get_rule("position_limit");
    assert!(rule.evaluate(&big_action).is_err());
    assert!(rule.evaluate(&small_action).is_ok());
  }
}
```

**Strengths:**
- Minimal attack surface (2 endpoints)
- No session state → concurrent traders don't interfere
- HMAC is fast; verification is local
- Law engine is unit-testable in isolation
- Replay-protected by nonce + short TTL

---

## Design B: Full Request-Reply with Event-Sourced Ledger

**Philosophy:** Every action is an event. Traders submit, marketplace publishes, events are immutable. Replay and audit are first-class. Testability via event snapshots.

### Method Signatures

```rust
// Submit action, get action_id immediately
fn submit_action(
  trader_id: TradeId,
  wallet_id: WalletId,
  action: MarketAction,
) -> Result<ActionId, WalletNotBound>

// Poll for action status
fn get_action_status(
  action_id: ActionId,
  trader_id: TradeId,           // verify trader owns this action
) -> Result<ActionEvent, ActionNotFound>

// Stream events (trader sees own actions only)
fn subscribe_trader_events(
  trader_id: TradeId,
) -> EventStream<ActionEvent>

// Query predictions (snapshot at call time)
fn get_predictions(
  sim_type: Option<SimType>,
) -> Result<Vec<BoundedPrediction>, SimNotReady>

// Query wallet state (snapshot)
fn get_wallet_state(
  wallet_id: WalletId,
  trader_id: TradeId,
) -> Result<WalletState, WalletNotBound>

// Admin: replay events from ledger (for audit/reconstruction)
fn replay_events(
  from_action_id: ActionId,
  to_action_id: ActionId,
) -> Result<Vec<ActionEvent>, OutOfBounds>
```

### Event Ledger Structure

```rust
pub enum ActionEvent {
  Submitted {
    action_id: ActionId,
    trader_id: TradeId,
    wallet_id: WalletId,
    action: MarketAction,
    timestamp: Timestamp,
  },
  LawChecked {
    action_id: ActionId,
    passed: bool,
    violations: Vec<LawViolation>,
  },
  VetoChecked {
    action_id: ActionId,
    approved: bool,
    veto_reason: Option<String>,
  },
  WalletSigned {
    action_id: ActionId,
    tx_hash: Hash256,
  },
  ExecutedOnChain {
    action_id: ActionId,
    tx_hash: Hash256,
    block_number: u64,
    status: TxStatus,  // Confirmed | Failed | Pending
  },
  ActionFailed {
    action_id: ActionId,
    reason: ActionFailureReason,
  },
}

// Immutable append-only log
pub struct ActionLedger {
  events: Vec<ActionEvent>,  // written to durable store
}
```

### Trader → Marketplace Flow

```
1. Trader calls submit_action(trader_id, wallet_id, action)
   → Marketplace creates ActionId, logs Submitted event
   → Returns ActionId immediately (async processing begins)

2. Background: Marketplace processes in pipeline
   → law_check(action) → logs LawChecked event
   → If law fails: logs ActionFailed, done
   → veto_check(action, trader_id) → logs VetoChecked event
   → If veto fails: logs ActionFailed, done
   → wallet.sign() → logs WalletSigned event
   → execute_on_chain() → logs ExecutedOnChain event
   → All events appended to ActionLedger atomically per stage

3. Trader polls get_action_status(action_id)
   → Reads latest ActionEvent for action_id
   → Returns current state: Submitted | LawFailed | VetoFailed | Signing | Executing | Confirmed | Failed

4. Trader subscribes to subscribe_trader_events(trader_id)
   → Receives stream of ActionEvents filtered to this trader
   → Can react in real-time as pipeline progresses

5. To reconstruct history:
   → Admin calls replay_events(action_id_start, action_id_end)
   → Ledger returns all events in order
   → Can rebuild marketplace state at any point in history
```

### Error Handling

```rust
pub enum ActionFailureReason {
  WalletNotBound { trader_id: TradeId },
  LawViolated {
    violations: Vec<LawViolation>,
  },
  Vetoed {
    reason: String,
  },
  WalletSignFailed {
    reason: String,
  },
  ChainExecutionFailed {
    tx_hash: Hash256,
    reason: String,
  },
  Timeout,
}

// Errors returned immediately from submit_action
pub enum SubmitError {
  WalletNotBound,
  InvalidAction,  // serde fail, etc.
}
```

### Law Script Invocation

**In-process, but with event logging.** Law engine is the same deterministic evaluator, but each check is wrapped:

```rust
fn law_check_and_log(
  action_id: ActionId,
  action: &MarketAction,
  ledger: &mut ActionLedger,
) -> Result<(), LawViolation> {
  let result = LAW_ENGINE.evaluate(action);
  ledger.append(ActionEvent::LawChecked {
    action_id,
    passed: result.is_ok(),
    violations: result.err().unwrap_or_default(),
  });
  result
}
```

### Extensibility

**Adding new action types:**
1. Add variant to `MarketAction` enum
2. Update law script
3. Restart (law script immutable)
4. All existing event ledger still valid (events are self-describing)
5. New action_ids will log with new action type

**Adding new pipeline stages:**
1. Define new `ActionEvent` variant
2. Insert processing stage in pipeline
3. Append event to ledger on completion
4. Replay logic automatically includes new stage

**Adding constraints dynamically:**
1. Law script restart required (immutable at runtime)
2. BUT: can add inspection steps to pipeline without touching law script
   - E.g., add `ActionInspected { reason: String }` event
   - Pipeline can short-circuit on inspection without law violation

### Testability

```rust
#[cfg(test)]
mod tests {
  #[test]
  fn test_law_violation_logged() {
    let action = MarketAction::Buy { quantity: 100, ... };
    let mut ledger = ActionLedger::new();
    let action_id = ActionId::new();
    
    let result = law_check_and_log(action_id, &action, &mut ledger);
    
    assert!(result.is_err());
    let event = ledger.get(action_id);
    assert!(matches!(event, ActionEvent::LawChecked { passed: false, ... }));
  }

  #[test]
  fn test_replay_reconstructs_state() {
    let mut ledger = ActionLedger::new();
    // Simulate 10 actions
    for i in 0..10 {
      let action = MarketAction::Buy { quantity: i, ... };
      let action_id = ActionId::new();
      simulate_action_pipeline(action_id, action, &mut ledger);
    }
    
    // Replay from action 3 to 7
    let replayed = replay_events(3, 7, &ledger);
    assert_eq!(replayed.len(), 4);  // events for actions 3,4,5,6,7
  }

  #[test]
  fn test_action_pipeline_order() {
    let mut ledger = ActionLedger::new();
    let action_id = ActionId::new();
    let action = MarketAction::Buy { quantity: 5, ... };
    
    process_action(action_id, action, &mut ledger);
    
    let events = ledger.get_events_for(action_id);
    // Verify order: Submitted → LawChecked → VetoChecked → WalletSigned → ExecutedOnChain
    assert_eq!(events[0].variant(), "Submitted");
    assert_eq!(events[1].variant(), "LawChecked");
    assert_eq!(events[2].variant(), "VetoChecked");
    assert_eq!(events[3].variant(), "WalletSigned");
    assert_eq!(events[4].variant(), "ExecutedOnChain");
  }

  #[test]
  fn test_subscribe_filters_by_trader() {
    let mut marketplace = Marketplace::new();
    let trader_a = TradeId::new();
    let trader_b = TradeId::new();
    
    marketplace.submit_action(trader_a, wallet_a, action_a);
    marketplace.submit_action(trader_b, wallet_b, action_b);
    
    let events_a = marketplace.subscribe_trader_events(trader_a).collect();
    assert_eq!(events_a.len(), 1);
    assert_eq!(events_a[0].trader_id, trader_a);
  }

  #[test]
  fn test_event_immutability() {
    let mut ledger = ActionLedger::new();
    let action_id = ActionId::new();
    
    let event1 = ActionEvent::Submitted { action_id, ... };
    ledger.append(event1.clone());
    
    let retrieved = ledger.get(action_id);
    assert_eq!(retrieved, event1);
    
    // Ledger is append-only; no mutation
    // (Rust type system enforces this via &mut references)
  }

  #[test]
  fn test_concurrent_submits_order_preserved() {
    let marketplace = Arc::new(Marketplace::new());
    let handles: Vec<_> = (0..100)
      .map(|i| {
        let mp = Arc::clone(&marketplace);
        thread::spawn(move || {
          mp.submit_action(trader_id, wallet_id, action)
        })
      })
      .collect();
    
    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();
    
    // All ActionIds are unique
    let ids: HashSet<_> = results.iter().map(|r| r.action_id).collect();
    assert_eq!(ids.len(), 100);
    
    // Ledger maintains order
    for i in 0..100 {
      assert!(ledger.get_events_for(results[i].action_id)[0].timestamp 
              <= ledger.get_events_for(results[i+1].action_id)[0].timestamp);
    }
  }

  #[test]
  fn test_veto_blocks_at_veto_stage() {
    let mut ledger = ActionLedger::new();
    let action = MarketAction::Buy { quantity: 5, ... };
    let action_id = ActionId::new();
    
    // Mock Conductor to veto
    conductor_mock.set_veto(true);
    
    process_action(action_id, action, &mut ledger);
    
    let events = ledger.get_events_for(action_id);
    // Should have: Submitted, LawChecked (pass), VetoChecked (veto), ActionFailed
    assert!(events.iter().any(|e| matches!(e, ActionEvent::VetoChecked { approved: false, .. })));
    assert!(events.iter().any(|e| matches!(e, ActionEvent::ActionFailed { .. })));
    // Should NOT have WalletSigned or ExecutedOnChain
    assert!(!events.iter().any(|e| matches!(e, ActionEvent::WalletSigned { .. })));
  }
}
```

**Strengths:**
- Complete auditability via immutable ledger
- Replay enables reconstruction and testing
- Event streaming allows real-time trader feedback
- Pipeline stages are decoupled and testable in isolation
- Concurrent actions are ordered and non-interfering

---

## Design C: GraphQL-Style Query/Mutation with Subscriptions

**Philosophy:** Strong typing, introspectable schema, live data subscriptions. Traders issue mutations to submit actions, queries to read state, subscriptions to stream prediction updates in real-time.

### GraphQL Schema

```graphql
# Input Types
input MarketActionInput {
  type: ActionType!           # BUY | SELL | MINT | ...
  asset: String!
  quantity: Float!
  price: Float
  slippage: Float
  chainId: Int
}

input CapabilityCredential {
  traderId: String!
  walletId: String!
  nonce: String!
  signature: String!          # Ed25519(concat(traderId, walletId, nonce, timestamp))
}

# Scalar Types
scalar Timestamp
scalar Hash256
scalar TradeId
scalar WalletId
scalar ActionId

# Enum Types
enum ActionType {
  BUY
  SELL
  MINT
  PROVIDE_LIQUIDITY
  WITHDRAW_LIQUIDITY
  CLAIM_REWARDS
}

enum TxStatus {
  PENDING
  CONFIRMED
  FAILED
  TIMEOUT
}

enum PredictionSource {
  STATISTICAL_SIM
  AMM_LIQUIDITY_SIM
  MEV_ADVERSARIAL_SIM
  TOKENOMICS_MACRO_SIM
  SOCIOLOGICAL_SIM
  CONSENSUS_STAKING_SIM
  MICROSTRUCTURE_SIM
}

# Object Types
type MarketAction {
  id: ActionId!
  traderId: TradeId!
  walletId: WalletId!
  type: ActionType!
  asset: String!
  quantity: Float!
  price: Float
  slippage: Float
  submittedAt: Timestamp!
  executedAt: Timestamp
}

type ExecutionReceipt {
  actionId: ActionId!
  txHash: Hash256!
  blockNumber: Int!
  status: TxStatus!
  gasUsed: Int
  gasPrice: Float
  confirmedAt: Timestamp
}

type BoundedPrediction {
  source: PredictionSource!
  asset: String!
  predictedPrice: Float!
  confidence: Float!           # 0.0 to 1.0
  interval: PredictionInterval!
  generatedAt: Timestamp!
}

type PredictionInterval {
  lowerBound: Float!
  upperBound: Float!
  confidenceLevel: Float!       # e.g., 0.95 for 95%
}

type WalletState {
  walletId: WalletId!
  traderId: TradeId!
  chains: [ChainBalance!]!
  spendingLimitDaily: Float!
  spendingLimitPerTx: Float!
  usedTodayUSD: Float!
  lastUsedAt: Timestamp
}

type ChainBalance {
  chainId: Int!
  chainName: String!
  assets: [AssetBalance!]!
}

type AssetBalance {
  symbol: String!
  amount: Float!
  usdValue: Float!
}

type ActionValidationResult {
  valid: Boolean!
  lawViolations: [LawViolation!]
  vetoReason: String
}

type LawViolation {
  ruleId: String!
  description: String!
  severity: String!            # BLOCK | WARNING
}

type MarketSnapshot {
  timestamp: Timestamp!
  predictions: [BoundedPrediction!]!
  gasPrice: Float!
  slippageEstimate: Float!
}

# Root Query Type
type Query {
  # Get current market snapshot
  marketSnapshot: MarketSnapshot!
  
  # Get predictions for specific sim or all
  predictions(
    source: PredictionSource
    asset: String
    limit: Int = 10
  ): [BoundedPrediction!]!
  
  # Get wallet state for authenticated trader
  walletState(walletId: WalletId!): WalletState!
  
  # Get specific action status
  action(actionId: ActionId!): MarketAction
  
  # List trader's recent actions
  traderActions(
    traderId: TradeId!
    limit: Int = 50
    offset: Int = 0
    status: TxStatus
  ): [MarketAction!]!
  
  # Validate action before submission
  validateAction(
    action: MarketActionInput!
    traderId: TradeId!
  ): ActionValidationResult!
  
  # Check wallet binding
  isWalletBound(traderId: TradeId!): Boolean!
  
  # Get execution history
  executionHistory(
    traderId: TradeId!
    from: Timestamp
    to: Timestamp
  ): [ExecutionReceipt!]!
}

# Root Mutation Type
type Mutation {
  # Submit a market action
  submitAction(
    action: MarketActionInput!
    walletId: WalletId!
    credential: CapabilityCredential!
  ): SubmitActionResult!
  
  # Bind wallet to trader (admin/initialization only)
  bindWallet(
    traderId: TradeId!
    walletId: WalletId!
    adminSignature: String!
  ): BindWalletResult!
  
  # Pause trader (Conductor only)
  pauseTrader(
    traderId: TradeId!
    reason: String!
    adminSignature: String!
  ): PauseTraderResult!
  
  # Resume trader (Conductor only)
  resumeTrader(
    traderId: TradeId!
    adminSignature: String!
  ): ResumeTraderResult!
}

union SubmitActionResult = ExecutionReceipt | ActionError
union BindWalletResult = BindSuccess | BindError

type ActionError {
  code: String!                 # LAW_VIOLATION | VETO | WALLET_ERROR | TIMEOUT
  message: String!
  violations: [LawViolation!]
}

type BindSuccess {
  traderId: TradeId!
  walletId: WalletId!
  boundAt: Timestamp!
}

type BindError {
  code: String!
  message: String!
}

type PauseTraderResult {
  traderId: TradeId!
  pausedAt: Timestamp!
  reason: String!
}

type ResumeTraderResult {
  traderId: TradeId!
  resumedAt: Timestamp!
}

# Root Subscription Type
type Subscription {
  # Live predictions for asset (push to traders)
  predictionUpdates(
    source: PredictionSource
    asset: String!
  ): BoundedPrediction!
  
  # Action status changes (push to trader)
  actionStatus(
    actionId: ActionId!
  ): MarketAction!
  
  # Wallet balance changes (push to trader)
  walletBalanceChanged(
    walletId: WalletId!
  ): WalletState!
  
  # Marketplace events (admin only)
  marketplaceEvents(
    adminToken: String!
  ): MarketplaceEvent!
}

type MarketplaceEvent {
  timestamp: Timestamp!
  type: String!                # ActionSubmitted | LawViolation | Veto | ExecutionFailed
  actionId: ActionId
  details: String!
}
```

### Trader → Marketplace Flow (Example)

```graphql
# Step 1: Query current market state and predictions
query GetMarketSnapshot {
  marketSnapshot {
    timestamp
    predictions(asset: "ETH") {
      source
      predictedPrice
      confidence
      interval {
        lowerBound
        upperBound
      }
    }
    gasPrice
    slippageEstimate
  }
  walletState(walletId: "wallet_123") {
    chains {
      chainName
      assets {
        symbol
        amount
        usdValue
      }
    }
    spendingLimitDaily
    usedTodayUSD
  }
}

# Step 2: Validate action before submission
query ValidateAction {
  validateAction(
    action: {
      type: BUY
      asset: "ETH"
      quantity: 1.5
      price: 2500
      slippage: 0.01
      chainId: 1
    }
    traderId: "trader_456"
  ) {
    valid
    lawViolations {
      ruleId
      description
      severity
    }
    vetoReason
  }
}

# Step 3: Submit action (if validated)
mutation SubmitBuyAction {
  submitAction(
    action: {
      type: BUY
      asset: "ETH"
      quantity: 1.5
      price: 2500
      slippage: 0.01
      chainId: 1
    }
    walletId: "wallet_123"
    credential: {
      traderId: "trader_456"
      walletId: "wallet_123"
      nonce: "uuid_12345"
      signature: "ed25519_sig_..."
    }
  ) {
    ... on ExecutionReceipt {
      actionId
      txHash
      blockNumber
      status
      confirmedAt
    }
    ... on ActionError {
      code
      message
      violations {
        ruleId
        description
      }
    }
  }
}

# Step 4: Subscribe to live updates
subscription MonitorPredictions {
  predictionUpdates(asset: "ETH") {
    source
    predictedPrice
    confidence
    generatedAt
  }
}

# Step 5: Subscribe to action completion
subscription MonitorAction {
  actionStatus(actionId: "action_789") {
    id
    status
    executedAt
  }
}
```

### Error Handling

Errors are represented in the GraphQL schema:

```graphql
# Example error response to submitAction
{
  "data": {
    "submitAction": {
      "__typename": "ActionError",
      "code": "LAW_VIOLATION",
      "message": "Action violates marketplace law",
      "violations": [
        {
          "ruleId": "P001",
          "description": "position_limit_exceeded",
          "severity": "BLOCK"
        }
      ]
    }
  }
}

# Example for timeout
{
  "errors": [
    {
      "message": "Chain RPC timeout after 30s",
      "extensions": {
        "code": "RPC_TIMEOUT"
      }
    }
  ]
}

# Example for veto
{
  "data": {
    "submitAction": {
      "__typename": "ActionError",
      "code": "VETO",
      "message": "Action was vetoed by Conductor",
      "violations": null
    }
  }
}
```

### Law Script Invocation

**In-process + lazy validation.** When `validateAction` query is called:

```rust
fn validate_action_graphql(
  action: &MarketActionInput,
  trader_id: &TradeId,
) -> ActionValidationResult {
  let market_action = action.to_market_action();
  
  let law_result = LAW_ENGINE.evaluate(&market_action);
  let violations = match law_result {
    Ok(_) => vec![],
    Err(v) => v,
  };
  
  let conductor_result = conductor.check_veto(&market_action, trader_id).await;
  let veto_reason = match conductor_result {
    Ok(_) => None,
    Err(reason) => Some(reason),
  };
  
  ActionValidationResult {
    valid: violations.is_empty() && veto_reason.is_none(),
    lawViolations: violations,
    vetoReason: veto_reason,
  }
}
```

Then in `submitAction` mutation, law and veto checks are re-run (cannot bypass by skipping validation).

### Extensibility

**Adding new action types:**
1. Add variant to `ActionType` enum in GraphQL schema
2. Add to `MarketAction` enum in code
3. Update law script
4. GraphQL schema is versioned; can provide schema migration path
5. Clients are type-safe; old clients get schema validation error if they use removed types

**Adding new simulation:**
1. Add variant to `PredictionSource` enum
2. Sim hub publishes predictions via data feeds (M2)
3. Marketplace collects in memory
4. `predictions` query automatically includes new source
5. Subscriptions automatically include new source via existing `predictionUpdates` subscription

**Adding new constraints:**
1. Update law script
2. Restart (law immutable)
3. `validateAction` and `submitAction` automatically enforce
4. Optionally add new fields to `ActionValidationResult` for detailed reporting

### Testability

```rust
#[cfg(test)]
mod tests {
  use crate::graphql::*;

  #[tokio::test]
  async fn test_validate_action_law_violation() {
    let client = setup_test_client().await;
    
    let query = r#"
      query {
        validateAction(
          action: { type: BUY, asset: "ETH", quantity: 100, slippage: 0.01, chainId: 1 }
          traderId: "trader_1"
        ) {
          valid
          lawViolations { ruleId, description }
        }
      }
    "#;
    
    let response = client.query(query).await;
    assert_eq!(response.data.validate_action.valid, false);
    assert!(response.data.validate_action.law_violations.len() > 0);
    assert_eq!(response.data.validate_action.law_violations[0].rule_id, "P001");
  }

  #[tokio::test]
  async fn test_submit_action_success() {
    let client = setup_test_client().await;
    let credential = gen_credential("trader_1", "wallet_1");
    
    let mutation = r#"
      mutation {
        submitAction(
          action: { type: BUY, asset: "ETH", quantity: 1, slippage: 0.01, chainId: 1 }
          walletId: "wallet_1"
          credential: { ... }
        ) {
          ... on ExecutionReceipt {
            actionId
            txHash
            status
          }
          ... on ActionError {
            code
            message
          }
        }
      }
    "#;
    
    let response = client.mutation(mutation, credential).await;
    assert!(matches!(response.data.submit_action, ExecutionReceipt { .. }));
  }

  #[tokio::test]
  async fn test_veto_blocks_submission() {
    let client = setup_test_client().await;
    conductor_mock.set_veto(true);
    
    let response = client.mutation(submit_action_mutation, credential).await;
    
    assert!(matches!(response.data.submit_action, ActionError { code: "VETO", .. }));
  }

  #[tokio::test]
  async fn test_subscription_prediction_updates() {
    let client = setup_test_client().await;
    
    let subscription = r#"
      subscription {
        predictionUpdates(asset: "ETH") {
          source
          predictedPrice
          confidence
        }
      }
    "#;
    
    let mut stream = client.subscribe(subscription).await;
    
    // Sim hub publishes new prediction
    sim_hub.publish_prediction(Prediction { asset: "ETH", ... });
    
    // Marketplace forwards via subscription
    let event = stream.next().await.unwrap();
    assert_eq!(event.prediction_updates.asset, "ETH");
  }

  #[tokio::test]
  async fn test_subscription_action_status() {
    let client = setup_test_client().await;
    
    let subscription = r#"
      subscription {
        actionStatus(actionId: "action_1") {
          id
          status
          executedAt
        }
      }
    "#;
    
    let mut stream = client.subscribe(subscription).await;
    
    // Submit action (in parallel)
    client.mutation(submit_action_mutation, credential).await;
    
    // Subscription pushes updates as action progresses
    let update1 = stream.next().await.unwrap();
    assert_eq!(update1.action_status.status, "PENDING");
    
    let update2 = stream.next().await.unwrap();
    assert_eq!(update2.action_status.status, "CONFIRMED");
  }

  #[tokio::test]
  async fn test_wallet_not_bound_error() {
    let client = setup_test_client().await;
    
    let query = r#"
      query {
        isWalletBound(traderId: "unbound_trader") 
      }
    "#;
    
    let response = client.query(query).await;
    assert_eq!(response.data.is_wallet_bound, false);
  }

  #[tokio::test]
  async fn test_schema_introspection() {
    let client = setup_test_client().await;
    let schema = client.introspect().await;
    
    // Verify schema contains expected types
    assert!(schema.types.iter().any(|t| t.name == "ActionType"));
    assert!(schema.types.iter().any(|t| t.name == "BoundedPrediction"));
    assert!(schema.types.iter().any(|t| t.name == "MarketAction"));
  }

  #[tokio::test]
  async fn test_concurrent_mutations_ordered() {
    let client = setup_test_client().await;
    
    let futures = (0..10)
      .map(|i| {
        let credential = gen_credential(&format!("trader_{}", i), "wallet_1");
        client.mutation(submit_action_mutation, credential)
      })
      .collect::<Vec<_>>();
    
    let results = futures::future::join_all(futures).await;
    
    // All actions succeed and have unique actionIds
    let ids: HashSet<_> = results
      .iter()
      .filter_map(|r| match &r.data.submit_action {
        ExecutionReceipt { action_id, .. } => Some(action_id.clone()),
        _ => None,
      })
      .collect();
    
    assert_eq!(ids.len(), 10);
  }
}
```

**Strengths:**
- Type-safe schema; introspectable
- Live subscriptions for real-time prediction + action feedback
- Separation of query (read), mutation (write), subscription (stream) is semantic
- GraphQL client libraries available for multiple languages
- Testable via standard GraphQL testing libraries
- Strong validation at schema level

---

## Recommendation: Design B (Event-Sourced Ledger)

### Reasoning

**Design A** (capability tokens) is elegant for minimalist security: stateless, fast, HMAC-verified. However:
- No visibility into why actions fail during processing
- Traders must poll aggressively to learn outcome
- Audit trail is implicit; difficult for SAE (M7) to reconstruct behavior
- Hard to debug timing issues or predict when an action will complete

**Design C** (GraphQL) is powerful for type safety and real-time UX:
- Strong introspection and schema evolution
- Live subscriptions are a genuine win for trader feedback
- However, GraphQL adds complexity (parsing, validation, multiple HTTP/WS layers)
- For a marketplace that prioritizes **determinism and auditability** (S99 vault, immutable law), the schema-freedom of GraphQL is actually a liability
- Harder to ensure all transactions follow the exact same pipeline order

**Design B (Event-Sourced Ledger)** wins because:

1. **Auditability (S3 / Invariant Provenance):** Every action is logged as an immutable event. SAE (M7) receives not just action outcomes but the exact pipeline stage at which decisions were made.

2. **Replay & Reconstruction:** If a bug is discovered post-execution, the ledger can be replayed to understand state at any point. Critical for a marketplace handling real economic value.

3. **Trader Transparency:** Traders can poll `get_action_status(action_id)` to see exactly where their action is in the pipeline (Submitted → LawChecked → VetoChecked → Signing → Executing → Confirmed). No guessing.

4. **Concurrency-Safe:** Events are appended atomically. No race conditions on event order. Marketplace state can be reconstructed deterministically from the ledger.

5. **Law Immutability (S99):** Law changes require restart + signatures. Event ledger makes it obvious when law version changed (historical events reference rule versions).

6. **Extensibility via Events:** Adding new pipeline stages (e.g., "BalanceSnapshot" before veto, "GasEstimate" before signing) doesn't break existing API — new events just appear in the ledger.

7. **Natural Fit for M7 (SAE):** SAE is designed to analyze actions for behavioral anomalies. Event ledger is a SAE-friendly input: immutable, ordered, complete.

8. **Testability:** Each pipeline stage can be unit-tested by inspecting events. Concurrent submissions are serialized in the ledger for deterministic testing.

**Trade-offs:**
- Slightly higher latency than Design A (events are async-logged)
- More complex than Design A (multiple event types to manage)
- No live subscriptions out-of-the-box like Design C (but easily added via WebSocket stream on top of ledger)

**Hybrid option:** Add WebSocket subscriptions to Design B (stream ledger events) to get Design C's real-time feedback while keeping Design B's auditability. This is the "B+" approach.

### Implementation Path

1. **Phase 1 (MVP):** Implement Design B core:
   - `submit_action()` creates ActionId, logs Submitted event
   - Background pipeline processes synchronously for now
   - `get_action_status()` queries ledger
   - Ledger stored in-memory (persist to disk post-MVP)

2. **Phase 2 (Robustness):**
   - Persist ledger to durable store (RocksDB or SQLite)
   - Implement `replay_events()` for audit
   - Add admin replay tool

3. **Phase 3 (UX):**
   - Add WebSocket subscriptions on top (stream events as they arrive)
   - Traders can subscribe to `traderEvents` for live updates
   - Minimal API change; retroactively solves Design C's real-time requirement

---

## Summary Table

| Criterion | Design A (Tokens) | Design B (Ledger) | Design C (GraphQL) |
|-----------|-------------------|-------------------|--------------------|
| **Auditability** | Implicit | Explicit (ledger) | Query-based |
| **Replay** | None | Full (replay API) | None |
| **Latency** | Low (HMAC verify) | Medium (event log) | Medium (GQL parsing) |
| **Type Safety** | Weak (tokens are strings) | Medium (Rust enums) | Strong (GraphQL schema) |
| **Real-time UX** | Polling only | Polling + streams | Subscriptions (native) |
| **Concurrency Safety** | High (stateless) | High (atomic events) | Medium (query ordering) |
| **SAE Integration** | Hard (no trace) | Easy (event stream) | Medium (query state) |
| **Extensibility** | Restart required | Event types | Schema versioning |
| **Testability** | Unit-testable | Excellent (replay) | Schema-testable |
| **Fit with S3/S99** | Poor | **Excellent** | Good |
| **Recommendation** | Specialist use | **RECOMMENDED** | Alternative |

---
