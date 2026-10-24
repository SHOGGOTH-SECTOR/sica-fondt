# M1 — Marketplace (multi-trader harness)

## 1. Component
The economy organ's trading floor: a **multi-trader harness** through which **all market actions
must route**. No trader may buy, sell, mint, or interact with any on-chain protocol except through
the Marketplace. Enforces a **deterministic law script** (scoped invariants — the marketplace's
own constitution) and integrates the **Conductor's veto** (M6) before execution.

## 2. Status / certainty
SCAFFOLD · EXECUTABLE SIMULATION. `core/src/economy/marketplace.tcl` implements the single
action ingress, deterministic admission ordering, supervisor veto, monitor logging, and
simulation-only execution. The full law-script loader remains open. Role C4; scaffold C2.

## 3. Language & location
**Tcl 8.6** · `core/src/economy/marketplace.tcl`. The implemented surface is deterministic,
simulation-only, and has no RPC, signer, key, approval, or broadcaster. A future live execution
adapter may be added only after M4 custody is ratified and must remain downstream of the same
auditable admission ordering.

## 4. Does / does-not
- **Does now:** receive `MarketAction` requests; record every submission for M7; reject paused
  Traders; require exact M4 Trader↔wallet binding; apply deterministic action/chain/notional law;
  apply M4 exposure limits independently; consult M6 veto only after deterministic law passes;
  return a deterministic simulated `simtx-*` receipt for admitted actions; expose the latest M3
  prediction for a Trader.
- **Does not now:** contact a chain, sign, broadcast, hold keys, move assets, or collect real tax.
- **Does not conceptually:** decide what to trade; predict markets; supervise Traders; or let M6
  legalize an action rejected by deterministic law.

## 5. Interface contract
- `submit_action(trader_id, action: MarketAction, wallet_id) -> { succeeded | failed }`.
  Diagnostic reasons (law violation, veto, missing wallet) are internal — routed to Conductor
  (M6) for upstream output. Immune system is a separate organ (out of scope here).
  `MarketAction` ∈ { `buy`, `sell`, `mint`, `provide_liquidity`, `withdraw_liquidity`, `claim_rewards`, … }.
- `query_predictions(sim_type: SimType) -> [BoundedPrediction]` — traders read per-sim-type
  predictions through the Marketplace. The hub stores the latest published result per sim type.
  M3a/M3b/M3c/M3e currently publish when their calibrated facade query runs; a scheduler-driven
  continuous refresh loop is still open. Traders see individual sim results and decide how to
  weight them.
- `law_check(action: MarketAction) -> { pass | violation(rule_id, reason) }` — deterministic,
  pure function. The law script is loaded at startup and **immutable at runtime** (mirrors S3 /
  the COBOL vault pattern).
- `veto_check(action: MarketAction, trader_id) -> { approved | vetoed(reason) }` — calls M6
  Conductor.
- `execute(action: MarketAction, wallet_id) -> { tx_hash | error }` — on-chain execution via
  wallet API.
- `tax_event(trader_id, income_amount) -> receipt` — triggers tax collection.

## 6. Dependencies & stubs
- M4 Wallets — signing + execution; *stub:* "if finished, would sign and broadcast tx [details]".
- M5 Traders — action source; *stub:* "if finished, would submit [action] for [asset] at [price]".
- M6 Conductor — veto authority; *stub:* "if finished, would evaluate [action] against risk policy; approving".
- M7 SAE — action log consumer; *stub:* "if finished, would analyze [action] for behavioral anomalies".
- Blockchain RPCs — on-chain execution; *stub:* "if finished, would execute [action] on [chain], returning tx_hash".

## 7. Invariants / laws
- **L1 (C5):** **all market actions route through the Marketplace** — no direct on-chain
  execution by any trader. This is the economy organ's S1.
- **L2 (C5):** the **deterministic law script is immutable at runtime** — loaded at startup,
  never modified by traders, conductor, or sims. Changes require a restart with a new script
  version **and a pair of signatures from the operator and the Homunculus**. Mirrors the COBOL
  vault (S3).
- **L3 (C4):** **no wallet, no access** — a trader without a bound wallet cannot submit actions.
  The Marketplace enforces this before any other check.
- **L4 (C4):** **veto is checked after law, before execution** — law violations are rejected
  outright; Conductor veto applies only to law-passing actions. The law is above the Conductor.
- **L5 (C4):** **every action is logged** — SAE (M7) receives a record of every submitted
  action (including rejected ones) for behavioral analysis.

## 8. Build steps
1. Define `MarketAction` types and the law script format.
2. Implement the law checker (deterministic, pure, non-Turing).
3. Wire veto check to M6 Conductor.
4. Wire execution to M4 Wallet API.
5. Wire action logging to M7 SAE.
6. Implement tax collection on realized income.

## 9. Tests
Law enforcement: known violations rejected; valid actions pass. Veto: conductor veto blocks
execution. Wallet binding: walletless trader rejected. Logging: every action (pass + fail) logged.
Tax: income event triggers tax stub. Immutability: law script cannot be modified at runtime.

## 10. Open items
- The law script language/format (DSL? declarative rules? S-expressions?).
- Which blockchain protocols/RPCs to support initially.
- Position limits, drawdown stops, and other risk parameters — live in the law script or in the
  Conductor's judgment?
- Tax rate / calculation method (fixed %, tiered, per-asset?).
- Non-Turing law script design — to discuss (format, expressiveness, bounds).
