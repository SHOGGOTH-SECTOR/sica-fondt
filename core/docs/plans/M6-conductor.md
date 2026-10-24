# M6 — Conductor (supervisory AI)

## 1. Component
The economy organ's supervisor: a **specialist-trained AI** with authority to **veto Marketplace
actions and pause/investigate individual Traders**. Receives suspicious-behavior reports from the
SAE (M7) and acts on them. The Conductor is the stomach's own judgment — it does not consult the
organism's Brain for trade-level decisions. It supervises; the deterministic law script (M1)
constrains; together they form the multi-layered braking system.

## 1A. Operational doctrine
- **Purpose:** M6 is the stomach's big-picture intelligence: risk officer, immune response,
  executive judgment, and portfolio/system situational awareness. Traders optimize locally;
  M6 sees interactions, concentration, correlated failure, uncertainty regime, and organ-level risk.
- **Authority:** M6 handles most trade supervision and may veto/pause/restrict lawful Trader
  behavior. It may never legalize an M1 violation or override an M4 hard ceiling.
- **Uncertainty regime:** M6 assigns broad admissible uncertainty boundaries by regime, asset,
  action type, or portfolio condition. Traders choose actions inside those boundaries; actions
  whose declared uncertainty falls outside the active regime are mechanically prevented.
- **Brain relationship:** routine supervision stays local. Brain may impose broad trade-type
  prohibitions, risk posture, budget constraints, and exceptionally veto an individual trade.
  Such directives enter through the organism boundary and are enforced through M6/M1 rather than
  creating a direct Brain→execution bypass.
- **Reconciliation:** M6 does not ask Sims to agree. It interprets complementary scopes together
  and resolves system-level implications that exceed any one Trader's local view.
- **Performance:** judge M6 by prevented ruin, calibrated restriction quality, intervention
  outcomes, false-positive/false-negative rates, and whether it preserves profitable autonomy
  rather than by the number of vetoes issued.
- **Completion criterion:** the supervisory AI is complete only when uncertainty-regime policy,
  portfolio-wide state, intervention reasoning, reversible restrictions, outcome feedback,
  persistent decision memory, and Brain-directive handling are all explicit and testable.

## 2. Status / certainty
SCAFFOLD · EXECUTABLE SUPERVISION. `core/src/economy/conductor.tcl` implements veto ordering,
pause/resume, alert intake, and an in-memory decision log. Specialist inference and persistent
audit storage remain open. Role C4; scaffold C2.

## 3. Language & location
**Tcl 8.6 supervision scaffold** · `core/src/economy/conductor.tcl`. V1 is deterministic state
and audit behavior only: veto-next, pause/resume, SAE alert intake, and decision logging.
Specialist-trained inference is a future layer, not part of the current executable surface.

## 4. Does / does-not
- **Does now:** stage a one-shot veto reason per Trader; mechanically pause/resume Traders;
  receive M7 alert envelopes; automatically pause on configured severe alerts; append decisions
  to an in-memory log; expose veto state to M1 only after deterministic Marketplace law passes.
- **Does not now:** perform AI investigation, infer market risk, persist its audit log, or call a
  specialist model.
- **Does not conceptually:** trade, legalize an M1-rejected action, detect anomalies directly,
  modify Marketplace law, or consult the organism's Brain for trade-level decisions.

## 5. Interface contract
- `veto_check(action: MarketAction, trader_id) -> { approved | vetoed(reason) }` — called by
  Marketplace (M1) for every law-passing action before execution.
- `receive_alert(alert: SAEAlert) -> { pause(trader_id) | dismiss | escalate }`.
  `SAEAlert { trader_id, alert_type, evidence, severity, timestamp }`.
- `investigate(trader_id) -> { clear(resume) | veto_pending_actions | restrict(new_limits) }`.
- `decision_log() -> [ConductorDecision]` — current in-memory audit trail.
- Target `UncertaintyRegime { regime_id, scope, action_types, assets?, max_uncertainty,
  max_capital_at_risk?, effective_at, expires_at?, provenance }`.
- Target `RiskDirective { directive_id, source, scope, prohibited_trade_types,
  uncertainty_ceiling?, budget_delta?, action_id?, effective_at, expires_at?, rationale,
  provenance }`. Brain-origin directives enter through the organism boundary; M6 translates
  them into restrictions without creating a direct execution path.
- Target `ConductorDecision { decision_id, action_id?, trader_id?, regime_id, decision,
  evidence_refs, rationale_digest, reversible, created_at, outcome_ref? }`.
- SAE/Brain semantic compatibility is a target protocol property; cryptographic signature
  equivalence is not claimed by V1.

## 6. Dependencies & runtime state
- M7 SAE — implemented typed alert envelopes; autonomous SAE detection remains open.
- M1 Marketplace — implemented one-shot veto consumption after law + wallet checks.
- M5 Traders — implemented pause/resume state target.
- Specialist Conductor inference runtime — open.
- Persistent audit store — open; V1 log is in-memory.

## 7. Invariants / laws
- **L1 (C5):** the Conductor **can veto, but cannot trade** — it has no wallet, no Marketplace
  access as a trader. It supervises from outside the trading loop.
- **L2 (C5):** the **law script is above the Conductor** — the Conductor vetoes actions that
  *pass* the law check but seem strategically risky. It cannot override a law violation (those
  are rejected before reaching the Conductor — M1-L4).
- **L3 (C4):** **pause is reversible** — a paused trader can always be resumed after
  investigation. Pause is a breaker, not a sentence (echoes A2-L3).
- **L4 (C4):** every V1 Conductor decision is appended to the current in-memory log. Persistent,
  tamper-evident audit storage is a future requirement and is not implied by the current list.
- **L5 (C4 target):** SAE and Brain oversight should converge on a compatible alert/message
  contract. V1 implements the SAE alert fields used by M6; cryptographic Brain-signature
  equivalence is not implemented or verified here.

## 8. Build status
1. **Done:** M7 alert intake and severity-based pause/dismiss behavior.
2. **Done:** M1 one-shot veto integration after deterministic law.
3. **Done:** Trader pause/resume control.
4. **Done:** in-memory decision log for veto/pause/resume/dismiss.
5. **Next:** implement/version `UncertaintyRegime` and mechanically reject out-of-regime
   Trader actions before execution.
6. **Next:** implement Brain/M0 `RiskDirective` intake for broad prohibitions and exceptional
   individual vetoes.
7. **Next:** link every restriction/veto to evidence and later outcome for intervention scoring.
8. **Open:** specialist Conductor inference/investigation.
9. **Open:** persistent/tamper-evident audit storage and escalation protocol.

## 9. Tests
Current tests verify veto, law-before-veto ordering, severe-alert pause, low-severity dismissal
path, pause blocking M1 actions/prediction reads, resume, and decision logging. There is no
specialist-inference or Brain-signature compatibility test because those layers do not exist.

## 10. Open items
- Formal uncertainty-regime vocabulary and default boundaries by action/asset/regime.
- Brain/M0 directive translation and expiry/revocation semantics.
- Specialist Conductor model/runtime and training/evaluation protocol.
- Judgment inputs beyond explicit M7 alerts.
- Persistent audit and intervention-outcome memory.
- Redundancy/multiple-Conductor design, if needed.
