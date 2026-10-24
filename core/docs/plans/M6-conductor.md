# M6 — Conductor (supervisory AI)

## 1. Component
The economy organ's supervisor: a **specialist-trained AI** with authority to **veto Marketplace
actions and pause/investigate individual Traders**. Receives suspicious-behavior reports from the
SAE (M7) and acts on them. The Conductor is the stomach's own judgment — it does not consult the
organism's Brain for trade-level decisions. It supervises; the deterministic law script (M1)
constrains; together they form the multi-layered braking system.

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
- `decision_log() -> [ConductorDecision]` — full audit trail of all veto/pause/resume/dismiss.
- **SAE/Brain message format compatibility:** the Conductor's incoming alert format is
  **identical in structure and signature** to Brain messages — SAE reports to the Conductor in
  the same shape it would report to the Brain. This means the Conductor can be swapped for Brain
  oversight without protocol changes (though the stomach normally operates autonomously).

## 6. Dependencies & stubs
- M7 SAE — anomaly reports; *stub:* no alerts (all clear).
- M1 Marketplace — veto check integration; *stub:* always-approve.
- M5 Traders — pause/resume control; *stub:* print pause/resume.

## 7. Invariants / laws
- **L1 (C5):** the Conductor **can veto, but cannot trade** — it has no wallet, no Marketplace
  access as a trader. It supervises from outside the trading loop.
- **L2 (C5):** the **law script is above the Conductor** — the Conductor vetoes actions that
  *pass* the law check but seem strategically risky. It cannot override a law violation (those
  are rejected before reaching the Conductor — M1-L4).
- **L3 (C4):** **pause is reversible** — a paused trader can always be resumed after
  investigation. Pause is a breaker, not a sentence (echoes A2-L3).
- **L4 (C4):** every Conductor decision is **logged** — vetoes, pauses, resumes, dismissals.
  The audit log is append-only (echoes M1-L2 / S3).
- **L5 (C4):** SAE alert format and Brain message format are **structurally identical** — same
  fields, same signatures. The Conductor processes them the same way the Brain would.

## 8. Build steps
1. Define the Conductor's LLM decision model (specialist-trained; rules are enforced by the
   Marketplace law script and wallet spending limits — the Conductor applies judgment).
2. Wire SAE alert intake (M7 → M6).
3. Wire Marketplace veto check (M1 → M6 → approve/veto).
4. Implement trader pause/investigate/resume flow.
5. Implement append-only decision log.

## 9. Tests
Veto: flagged action is vetoed; unflagged action approved. Pause: paused trader cannot submit
actions. Resume: cleared trader resumes normal operation. No trading: Conductor cannot submit
`MarketAction`. Law supremacy: Conductor cannot override a law violation (never reaches
Conductor). Audit: every decision appears in the log. Alert format: SAE alert parses identically
to Brain message structure.

## 10. Open items
- Conductor AI model selection and training data (what does "specialist training" look like?).
- Veto criteria beyond SAE alerts (does the Conductor have independent judgment, or only
  responds to SAE reports?).
- Escalation path — if the Conductor is uncertain, does it escalate to the organism's Brain?
  Or is the stomach fully autonomous? (Current design: fully autonomous.)
- Multiple Conductors for redundancy?
