# M7 — SAE monitor (trader surveillance)

## 1. Component
The economy organ's internal watchdog: a **sparse autoencoder pointed at every trader tool call**.
Monitors all Trader (M5) actions — Marketplace submissions, Sim queries, Data Feed reads, and
any other tool invocation — and reports **suspicious behavior** to the Conductor (M6). Messages
from the SAE share **identical format and signatures** with Brain messages, so the Conductor
processes them through the same pathway.

Extends the F2 (SAE monitor) pattern to the economy organ's internal domain. F2 watches
subagents at the organism level; M7 watches traders at the stomach level.

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

Future SAE inference may consume the same observation log, but V1 alerts are explicitly created
by callers/tests rather than autonomously inferred by a trained sparse autoencoder.

## 6. Dependencies & stubs
- 

## 7. Invariants / laws
- **L1 (C5):** the SAE watches everyone in the orgab.
- **L2 (C5):** **every tool call is logged** — no trader action escapes monitoring. This is enforced architecturally (tool call interception), not by policy.
- **L3 (C4):** **detection only, no enforcement** — the SAE reports to the Conductor; it never blocks, pauses, or modifies trader actions itself. Echoes F2-L2 (no closed elimination loop).
- **L4 (C4):** **alert format = Brain message format** — structurally identical, same signatures. This is not coincidental; it ensures the Conductor can be supervised by the Brain using the same protocol if the organism ever needs to override stomach autonomy.
- **L5 (C3):** the SAE model is **trained on normal trader behavior** — anomalies are deviations from the learned normal, not violations of predefined rules (those are the law script's job in M1).

## 8. Build steps
1. Implement action interception at the Marketplace level (M1).
2. Define the action embedding scheme (how tool calls are vectorized).
3. Train the SAE on normal trader behavior (bootstrapped from simulated trading).
4. Implement anomaly scoring and alert threshold.
5. Wire alerts to Conductor (M6) in Brain-compatible message format.

## 9. Tests

## 10. Open items
