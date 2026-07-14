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
DESIGN-FIRST · ABSENT. F2 SAE monitor provides the architectural pattern (watch the machinery,
never the homunculus — F2-L1). M7 adapts this: watch the **traders** (the machinery), never the
**Conductor** (the stomach's judgment). Role C3; implementation C1.

## 3. Language & location
TBD · `src/economy/sae/`. ML interpretability (sparse autoencoder over trader action embeddings).
Shares the architectural pattern with F2 but is a separate instance scoped to the economy organ.

## 4. Does / does-not
- **Does:** intercept and log **every trader tool call** (Marketplace, Sims, Feeds, internal);
  embed trader action sequences; run SAE anomaly detection over action embeddings; flag suspicious
  patterns (unusual trading frequency, outsized positions, coordinated behavior across traders,
  repeated failed actions, unusual Sim query patterns); report alerts to the Conductor (M6) with
  evidence; format alerts **identically to Brain messages** (same structure, same signatures).
- **Does-not:** block actions directly (Conductor decides); watch the Conductor (the stomach's
  "homunculus" — echoes F2-L1); correct trader behavior (detection only — F2-L2: no closed
  elimination loop); trade or access wallets.

## 5. Interface contract
- `log_tool_call(trader_id, tool_name, args, result, timestamp)` — called on every trader tool
  invocation. Synchronous interception (the call is logged before execution proceeds).
- `alert(trader_id, alert_type, evidence, severity) -> SAEAlert`.
  `alert_type` ∈ { `unusual_frequency`, `outsized_position`, `coordinated_behavior`,
  `repeated_failures`, `anomalous_queries`, `pattern_deviation` }.
  `severity` ∈ { `low`, `medium`, `high`, `critical` }.
- `SAEAlert` structure is **identical to Brain message structure** — same fields, same
  signature scheme. The Conductor (M6) processes SAE alerts and Brain messages through the
  same intake (M6-L5).
- `status() -> { active, traders_monitored, alerts_pending, model_freshness }`.

## 6. Dependencies & stubs
- M5 Traders — tool call source; *stub:* canned tool call log.
- M6 Conductor — alert consumer; *stub:* print alerts.
- F2 SAE monitor (organism-level) — architectural pattern; no runtime dependency.

## 7. Invariants / laws
- **L1 (C5):** the SAE watches **traders, never the Conductor** — the Conductor is the
  stomach's judgment; the SAE monitors the machinery. Echoes F2-L1 (watch the machinery, never
  the homunculus).
- **L2 (C5):** **every tool call is logged** — no trader action escapes monitoring. This is
  enforced architecturally (tool call interception), not by policy.
- **L3 (C4):** **detection only, no enforcement** — the SAE reports to the Conductor; it never
  blocks, pauses, or modifies trader actions itself. Echoes F2-L2 (no closed elimination loop).
- **L4 (C4):** **alert format = Brain message format** — structurally identical, same signatures.
  This is not coincidental; it ensures the Conductor can be supervised by the Brain using the
  same protocol if the organism ever needs to override stomach autonomy.
- **L5 (C3):** the SAE model is **trained on normal trader behavior** — anomalies are deviations
  from the learned normal, not violations of predefined rules (those are the law script's job
  in M1).

## 8. Build steps
1. Implement tool-call interception in the trader harness (M5).
2. Define the action embedding scheme (how tool calls are vectorized).
3. Train the SAE on normal trader behavior (bootstrapped from simulated trading).
4. Implement anomaly scoring and alert threshold.
5. Wire alerts to Conductor (M6) in Brain-compatible message format.

## 9. Tests
Interception: every tool call produces a log entry. Anomaly: known-suspicious patterns (e.g.
100x normal frequency) trigger alert. Normal: baseline behavior does not trigger alert.
No enforcement: SAE cannot pause or block a trader (only Conductor can). Alert format: SAE
alert parses as valid Brain message. Conductor-blind: no Conductor action appears in SAE logs.

## 10. Open items
- SAE architecture (how many features? reconstruction vs. classification?).
- Training data bootstrapping (simulated trading or historical data?).
- Alert threshold tuning (too sensitive = alert fatigue; too lax = missed anomalies).
- Whether M7 should also monitor Marketplace execution outcomes (fills, slippage) in addition
  to tool calls.
- Relationship to F2: shared model? shared training pipeline? or fully independent?
