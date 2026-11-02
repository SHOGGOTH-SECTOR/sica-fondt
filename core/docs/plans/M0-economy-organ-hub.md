# M0 — Economy organ hub (the stomach)

## 1. Component
The economy organ — the organism's **stomach**. An **independent, self-governing system**: a
multi-agentic market prediction oracle and cryptocurrency trading engine. Houses the Marketplace
(M1), Data Feeds (M2), Sims (M3), Wallets (M4), Traders (M5), Conductor (M6), and SAE monitor
(M7). Communicates with the rest of the organism **via Ichor only** — reward signals back to the
organism are TBD and out of scope.

"A stomach rarely consults a brain for permission to digest." The economy organ operates with
**scoped autonomy** and **multiple layers of failsafe braking** — it does not ask the organism's
Brain for permission to trade.

## 1A. Operational doctrine
- **Purpose:** maximize durable profit locally. At organism scale, realized surplus is metabolic
  capacity - especially additional compute budget - rather than the Brain's terminal objective.
- **Authority:** scoped autonomy. Routine economic decisions remain inside the stomach. The Brain
  may set broad trade prohibitions, risk posture, budget envelopes, and exceptionally veto an
  individual action; ordinary supervision belongs to M6. M1 law and M4 hard ceilings remain
  non-overridable at action time.
- **Evidence:** M0 may consume M2 observations, M3 predictions/calibration, M5 outcomes, M6
  interventions, and M7 anomaly evidence, always retaining their provenance.
- **Permitted decisions:** compose the economy organ, route directives to the owning component,
  maintain shared economic memory, expose metabolic summaries, and coordinate component lifecycle.
- **Prohibited decisions:** M0 does not bypass M1/M4/M6/M7, does not create a Brain→execution
  shortcut, and does not silently convert derived belief into raw evidence.
- **Memory:** durable records accumulate source reliability, regime behavior, Sim bias, Trader
  calibration, repeated anomaly patterns, protocol precursors, and intervention outcomes.
  Repetition changes trust; source observations are linked, never rewritten.
- **Performance:** durable profit, capital survival, regime adaptation, improving allocation,
  retained optionality, competent Traders, and surplus sufficient to further organism compute.
- **Failure:** ruin, repeated uncorrected miscalibration, loss of scoped autonomy, or profitable
  behavior achieved by bypassing constitutional/braking/border constraints.
- **Completion criterion:** M0 is complete when all owned component contracts are runtime-wired,
  economic memory persists and replays, Brain directives enter only through the organism boundary,
  metabolic surplus is measurable, and no local execution path bypasses M1/M4/M6/M7.

## 2. Status / certainty
EXECUTABLE OUTER-ORGAN SCAFFOLD. `core/src/economy/` composes M1–M7, exposes normalized
feed/history surfaces, runs the M3 horizon clock, wires M3a/M3b/M3c/M3e through native runtimes,
stages tax receipts without moving value, and emits Ada-bound secretion metadata. M3d/M3f/M3g
remain native kernels without equivalent Tcl query bridges. Live custody, signing/broadcasting,
AI Trader inference, Conductor inference, SAE inference, and the Pony↔Tcl Ichor bridge remain
open. Role C4; scaffold/runtime implementation C3.

## 3. Language & location
**Tcl 8.6 orchestration** · `core/src/economy/`, with native M3 engines in R, ECLiPSe Prolog,
Solidity/Foundry, and Fortran 2018. Pony remains the Ichor-facing outer transport layer; the
runtime bridge between the Tcl economy facade and Ichor is still open.

## 4. Does / does-not
- **Implemented now:** compose M1–M7; accept normalized M2 data; expose bounded M3 predictions
  through Marketplace; enforce deterministic Marketplace admission, wallet binding/limits,
  Conductor pause/veto state, SAE call logging/alerts, and simulation-only execution; stage tax
  receipts; emit an Ada-bound `organ_secretion` summary.
- **Native M3 integration now:** M3a statistical, M3b sociological, M3c AMM/liquidity, and M3e
  tokenomics/macro have tested M2→native-runtime→Hub paths. M3d/M3f/M3g are registered native
  kernels but are not yet facade-queryable.
- **Does not currently:** hold private keys; sign or broadcast transactions; move tax value;
  autonomously run AI Trader/Conductor/SAE inference; continuously invoke every native sim from
  the scheduler; bypass Ada; or join the inner brain bus.
- **Target architecture:** scoped economic autonomy remains the design goal, but future live-money
  behavior must still pass M1 law, M4 brakes, M6 supervision, M7 observation, and D1 at the
  organism boundary.

## 5. Interface contract
- **Ichor interface (outbound):** `Envelope(Stomach, AdaBorder, OrganSecretion, payload)` — market
  state summaries, prediction digests, and tax receipts cross Ada to reach the inner brain.
- **Ichor interface (inbound):** organism directives arrive via Ichor. Target directive shape:
  `RiskDirective { directive_id, scope, prohibited_trade_types, uncertainty_ceiling?,
  budget_delta?, effective_at, expires_at?, rationale, provenance }`. Exceptional individual
  action vetoes use the same path and name the exact `action_id`; there is no Brain→execution
  shortcut.
- **Internal wiring:** Marketplace (M1) owns the action and prediction-read boundary. M2 stores
  normalized histories consumed by M3 native bridges. Wallets (M4) currently provide identity
  binding and exposure brakes only. Conductor (M6) owns veto/pause state. SAE (M7) records
  Marketplace-level tool calls and constructs alerts for M6. All Trader actions route through
  Marketplace.
- **Economic memory contract (target):**
  `EconomicMemoryRecord { subject_type, subject_id, regime, metric, value, recurrence,
  observation_refs, first_seen, last_seen, provenance }`. M0 owns persistence/lookup semantics;
  producers remain M2/M3/M5/M6/M7. Derived memory never rewrites source observations.
- **Tax stub:** `transfer_tax(amount, source_wallet, dest_wallet) -> receipt` — automation hook
  for Verschwörern Veregeister internal wallet-to-wallet transfer. **Out of scope** — stub only.

## 6. Dependencies & stubs
- Ichor bus (D2) — existing `Broker` + `Envelope`.
- Ada border (D1) — outbound economy envelopes cross here (S1); *stub:* Ichor `Barrier`.
- A2 energy — potential consumer of economic signals; *stub:* no integration initially.
- Verschwörern Veregeister wallets — tax destination; *stub:* log transfer, no real wallet.

## 7. Invariants / laws
- **L1 (C5):** the stomach is an **OUTER** organ — it rides Ichor, never the inner bus.
- **L2 (C5):** **scoped autonomy** — the organ trades without Brain permission, but within
  deterministic law constraints (M1) and Conductor oversight (M6).
- **L3 (C4):** **all market actions route through the Marketplace** (M1) — no trader may
  execute directly on-chain without the Marketplace harness.
- **L4 (C4):** **sovereign custody only** — all wallets are local-hosted, our keys, never
  delegated to exchanges or third parties (M4).
- **L5 (C4):** **multi-layered braking** — deterministic law script (M1), Conductor veto (M6),
  SAE surveillance (M7), and wallet-level limits (M4) each independently constrain risk.

## 8. Build steps
1. **Done:** executable M1–M7 Tcl scaffold and contract tests.
2. **Done:** M3 registry/scheduler plus native runtime bridges for M3a/M3b/M3c/M3e.
3. **Done:** simulation-only tax receipt staging.
4. **Next:** define and persist the M0 economic-memory record/lookup contract.
5. **Next:** define inbound `RiskDirective` handling and prove broad/individual Brain vetoes enter
   through M6/M1 without bypassing M4.
6. **Open:** runtime bridge between the economy facade and Pony/Ichor.
7. **Open:** M3d/M3f/M3g query bridges and scheduler-driven automatic refresh.
8. **Open by design:** live custody/signing/broadcast, Trader/Conductor inference, SAE inference.

## 9. Tests
Executable contract suite: `tclsh core/src/economy/tests/stomach.test`. The current 17
tests cover admission ordering, 1:1 binding, simulation-only execution, monitor logging,
supervisor pause/resume, bounded predictions, feed backpressure, exposure limits, tax staging,
Ada-bound secretion, all seven M3 engine registrations, source presence, the six horizon clocks,
and the running scheduler. Native simulator tests are driven by
`tclsh core/src/economy/sims/run_tests.tcl`. Ichor runtime bridging remains a separate
integration test.

## 10. Open items
- Define the outbound metabolic signal: realized surplus, available capital, compute-budget
  contribution, drawdown, and confidence in those quantities.
- Persistent economic-memory store and replay semantics.
- Brain `RiskDirective` ingress and exceptional action-veto routing.
- Pony↔Tcl process/FFI boundary for the outer-organ facade.
- Automatic M3 engine scheduling/refresh and failure isolation.
- Ratified M4 custody design before any signer or broadcaster exists.
