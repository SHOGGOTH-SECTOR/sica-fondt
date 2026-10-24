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
5. **Open:** specialist Conductor inference/investigation.
6. **Open:** persistent/tamper-evident audit storage and any escalation protocol.

## 9. Tests
Current tests verify veto, law-before-veto ordering, severe-alert pause, low-severity dismissal
path, pause blocking M1 actions/prediction reads, resume, and decision logging. There is no
specialist-inference or Brain-signature compatibility test because those layers do not exist.

## 10. Open items
- Specialist Conductor model/runtime and training/evaluation protocol.
- Judgment inputs beyond explicit M7 alerts.
- Persistent audit semantics.
- Escalation policy, if any, to the organism's Brain while preserving scoped stomach autonomy.
- Redundancy/multiple-Conductor design, if needed.
