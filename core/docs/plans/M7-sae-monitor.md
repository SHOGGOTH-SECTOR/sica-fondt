# M7 — SAE monitor (trader surveillance)

## 1. Component
The economy organ's internal watchdog: a **sparse autoencoder pointed at every trader tool call**.
Monitors all Trader (M5) actions — Marketplace submissions, Sim queries, Data Feed reads, and
any other tool invocation — and reports **suspicious behavior** to the Conductor (M6). Messages
from the SAE share **identical format and signatures** with Brain messages, so the Conductor
processes them through the same pathway.

Extends the F2 (SAE monitor) pattern to the economy organ's internal domain. F2 watches
subagents at the organism level; M7 watches traders at the stomach level.

## 1A. Operational doctrine
- **Purpose:** M7 is an evidence-producing anomaly sensor and memory feeder, not a guilt engine.
- **Signal taxonomy:** unusualness, danger, suspected compromise, suspected deception,
  strategy/identity incoherence, and recurrence are distinct signals. They must not be collapsed
  into one undifferentiated anomaly score.
- **Anomaly is legitimate until interpreted:** a Trader may intentionally behave unusually because
  its specialization or market regime demands it. M7 reports the deviation and evidence; M6 decides
  whether the behavior is dangerous, adaptive, profitable, compromised, or benign.
- **Repetition matters:** recurring deviations, repeated failed predictions, repeated source/
  behavior couplings, and recurring precursors accumulate as durable economic memory. Frequency
  and recurrence are evidence, not automatic enforcement.
- **Separation of roles:** M7 detects and records; M6 interprets and restricts; M1/M4 enforce hard
  boundaries. M7 must not become a shadow policy engine.
- **Completion criterion:** trained M7 is complete only when observations are instrumented,
  embeddings/features are attributable, recurrence is represented, signal classes are separable,
  alert evidence is inspectable, feedback from M6/outcomes updates memory, and false-positive /
  false-negative behavior is measured over time.

## 2. Status / certainty
SCAFFOLD · PARTIAL. `core/src/economy/sae.tcl` records Marketplace-level trader calls and
constructs alert envelopes consumed by M6. Sparse-autoencoder inference/training remains open.
F2 still provides the architectural pattern: watch traders, never the Conductor. Role C3;
scaffold C2.

## 3. Language & location
**Tcl 8.6 observation scaffold** · `core/src/economy/sae.tcl`. V1 records Marketplace tool-call
events and constructs typed alert envelopes for M6. Sparse-autoencoder embeddings, inference,
training, learned anomaly thresholds, and model persistence remain future work.

## 4. Does / does-not
- **Does now:** record every Marketplace submission at the single action ingress; preserve Trader,
  tool, payload/result metadata in the monitor log; construct `SAEAlert` envelopes with Trader,
  alert type, evidence, severity, and timestamp for M6.
- **Does not now:** embed actions, run a sparse autoencoder, learn anomaly thresholds, or infer
  suspiciousness autonomously.
- **Does not conceptually:** block actions directly, watch the Conductor, correct Trader behavior,
  trade, or access wallets. Enforcement remains M6/M1/M4.

## 5. Interface contract
Implemented Tcl surface:
- `record_tool_call(trader_id, tool, payload, result, timestamp)` — append observation.
- `alert(trader_id, alert_type, evidence, severity, timestamp) -> SAEAlert`.
- `log()` — current in-memory observations.

Target evidence contract:
`AnomalySignal { signal_id, trader_id, signal_type, severity, confidence, recurrence_count,
expected_behavior_ref?, observed_behavior_ref, evidence_refs, regime, first_seen, last_seen }`,
where `signal_type` distinguishes at minimum `deviation`, `danger`, `suspected_compromise`,
`suspected_deception`, `strategy_incoherence`, and `recurrence`.

Future SAE inference may consume the same observation log, but V1 alerts are explicitly created
by callers/tests rather than autonomously inferred by a trained sparse autoencoder. M7 signal
records feed M0 durable economic memory; they never directly enforce.

## 6. Dependencies & runtime state
- M1 Marketplace — implemented observation point for action submissions and prediction queries.
- M6 Conductor — implemented alert consumer.
- Trader-action embedding model / trained SAE — absent.
- Persistent observation store — absent; V1 log is in-memory.

## 7. Invariants / laws
- **L1 (C5 scope):** M7 watches Trader activity at the stomach's Marketplace boundary; it does
  not watch the Conductor or unrelated organism processes.
- **L2 (C5 within current surface):** every Marketplace submission and Marketplace prediction
  query is logged. Future Trader tools must either route through an instrumented boundary or add
  equivalent M7 observation before this can truthfully extend to "every tool call."
- **L3 (C4):** **detection only, no enforcement** — the SAE reports to the Conductor; it never blocks, pauses, or modifies trader actions itself. Echoes F2-L2 (no closed elimination loop).
- **L4 (C4 target):** M7 alert structure should remain compatible with any future Brain oversight
  protocol. V1 implements the shared semantic fields, not cryptographic signature equivalence.
- **L5 (C3 target):** a future SAE model should learn normal Trader behavior and detect deviations
  rather than duplicate M1 law. No trained SAE exists in V1.

## 8. Build status
1. **Done:** Marketplace-level action/prediction-query logging.
2. **Done:** typed `SAEAlert` envelope with bounded severity.
3. **Done:** alert delivery path into M6.
4. **Next:** implement typed `AnomalySignal` records and recurrence counters.
5. **Next:** link M6 interpretation/outcomes back to signals so false positives, false negatives,
   and legitimate anomalous adaptations can be measured.
6. **Next:** persist repeated signal patterns into M0 economic memory.
7. **Open:** action embedding scheme.
8. **Open:** SAE training/inference, learned anomaly scoring, and thresholds.
9. **Open:** persistent observation/model state.

## 9. Tests
Current M0 tests verify pass/fail Marketplace submissions are logged, severe caller-created alerts
reach M6 and pause the target Trader, and severity is bounded. There is no learned-anomaly test
because no SAE inference exists.

## 10. Open items
- Action-sequence embedding representation.
- SAE architecture/training data and evaluation protocol.
- Learned anomaly threshold calibration.
- Persistent observation/model storage.
- Instrumentation contract for any future Trader tools outside the current Marketplace methods.
