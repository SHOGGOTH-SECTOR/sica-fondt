# M1 — Marketplace (multi-trader harness)

## 1. Component
The economy organ's trading floor: a **multi-trader harness** through which **all market actions
must route**. No trader may buy, sell, mint, or interact with any on-chain protocol except through
the Marketplace. Enforces a **deterministic law script** (scoped invariants — the marketplace's
own constitution) and integrates the **Conductor's veto** (M6) before execution.

## 1A. Operational doctrine
- **Purpose:** M1 is a constitution and execution harness, not a strategy engine. It makes some
  actions structurally unavailable; it does not decide which lawful action is economically wise.
- **Authority:** deterministic law is above Trader judgment, M6 judgment, and exceptional Brain
  vetoes. M6/Brain may further restrict lawful action but may not legalize a constitutional
  violation.
- **Scope of law:** encode catastrophic/constitutional prohibitions, capability boundaries,
  identity/binding requirements, and hard action constraints. Ordinary economic doctrine,
  opportunity selection, and uncertainty judgment belong to M5/M6.
- **Auditability:** every decision must be reproducible from the action, law version, M4 brake
  state, M6 veto state, and logged evidence. A future law DSL must produce a proof/violation trace.
- **Completion criterion:** M1 is complete for live execution only when the signed immutable law
  evaluator, M4-authorized signer path, M7 logging, M6 restriction ordering, and simulation/live
  parity tests all exist. Adding RPC alone is not completion.

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
- Implemented deterministic gate: required fields, action allowlist, chain allowlist, and numeric
  notional validation. The full startup-loaded S-expression constitution is **designed but not
  implemented**; see `M1-law-script-design.md`.
- Target law result:
  `LawDecision { action_id, law_version, pass, violation_id?, proof_trace, evaluated_at }`.
  This record must be stable enough for replay and audit; M6 veto state is deliberately outside
  the law proof.
- Implemented M4 brake: exact Trader↔wallet binding plus exposure checks.
- Implemented M6 gate: one-shot veto is consumed only after deterministic law and wallet checks.
- Implemented execution result: `{ status succeeded execution simulated tx_id simtx-* }`.
- Implemented M7 observation: every submission is logged before admission checks.
- Tax staging exists on M0 as `tax_event`; Marketplace does not currently calculate realized
  income or move value.

## 6. Dependencies & runtime state
- M4 Wallets — implemented binding + exposure brakes; no signer/custody.
- M5 Traders — registry/state exists; AI action generation is open.
- M6 Conductor — implemented deterministic veto/pause surface; AI judgment is open.
- M7 SAE — implemented logging + caller-created alert envelopes; SAE inference is open.
- M3 Sims — latest prediction reads are implemented through Marketplace.
- Blockchain RPC/signing/broadcast — deliberately absent.

## 7. Invariants / laws
- **L1 (C5):** **all market actions route through the Marketplace** — no direct on-chain
  execution by any trader. This is the economy organ's S1.
- **L2 (C5 target):** the future startup-loaded deterministic law script is immutable at runtime
  and dual-signed. **Current implementation note:** V1 uses hardcoded deterministic allowlists and
  field/notional validation; the signed fixed-combinator evaluator is still open.
- **L3 (C4):** **no wallet, no access** — a trader without a bound wallet cannot submit actions.
  The Marketplace enforces this before any other check.
- **L4 (C4):** **veto is checked after law, before execution** — law violations are rejected
  outright; Conductor veto applies only to law-passing actions. The law is above the Conductor.
- **L5 (C4):** **every action is logged** — SAE (M7) receives a record of every submitted
  action (including rejected ones) for behavioral analysis.

## 8. Build status
1. **Done:** `MarketAction` validation and deterministic hardcoded gate.
2. **Done:** M4 binding/exposure brake before execution.
3. **Done:** M6 veto ordering after deterministic law.
4. **Done:** M7 logging for pass/fail submissions.
5. **Done:** simulation-only execution receipts.
6. **Next:** implement `LawDecision` with versioned proof/violation traces.
7. **Next:** implement the signed fixed-combinator S-expression constitution against those traces.
8. **Open by design:** signer/RPC/broadcast execution and realized-income tax calculation.

## 9. Tests
The M0 contract suite verifies walletless rejection, wrong-wallet rejection, deterministic law
rejection, law-before-veto ordering, valid simulation-only execution, per-action/session brakes,
pass/fail M7 logging, pause/resume, and staged tax receipts. There is no live-chain execution test
because no live-chain execution surface exists.

## 10. Open items
- Implement the already-decided fixed-combinator S-expression evaluator and signature checks.
- Ratify M4 custody before choosing or exposing any chain execution adapter.
- Position/drawdown rules that belong in deterministic law versus M6 judgment.
- Realized-income accounting and tax calculation/transfer policy.
