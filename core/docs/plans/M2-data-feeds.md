# M2 — Data feeds (market data pipeline)

## 1. Component
The economy organ's sensory nervous system: **live RSS feeds, price streams, and on-chain data**
flowing into both the Marketplace (M1) and the Sims (M3). Sits between them — the Marketplace
produces execution data (fills, positions, P&L) that feeds back into Sims, and Sims produce
predictions that inform Traders operating through the Marketplace. Data Feeds is the bridge.

## 1A. Operational doctrine
- **Purpose:** M2 preserves observations; it does not adjudicate reality.
- **Epistemic rule:** provenance, source, timestamp, confidence, and contradiction are first-class.
  Conflicting observations coexist intact. M2 must not collapse them into a synthetic consensus
  datum unless an explicitly named downstream process requests and records that transformation.
- **Normalization rule:** normalize representation, units, and schema - never silently normalize
  away disagreement, source identity, uncertainty, or missingness.
- **Derived belief separation:** source reliability, regime-conditioned trust, and repeated
  source failure may become durable economic memory, but those assessments are derived records
  linked back to immutable observations; they do not rewrite M2 history.
- **Completion criterion:** a source adapter is complete only when it preserves provenance,
  exposes loss/backpressure behavior explicitly, survives reconnect/replay without duplication,
  and can reproduce the normalized history consumed by downstream Sims.

## 2. Status / certainty
SCAFFOLD · EXECUTABLE. `core/src/economy/feeds.tcl` implements normalized in-session history
and explicit backpressure without silent drop. External stream adapters remain open. Role C3;
scaffold C2.

## 3. Language & location
**Tcl 8.6 core buffer** · `core/src/economy/feeds.tcl`. V1 provides normalized in-session
history and explicit capacity backpressure. External WebSocket/SSE/RSS/RPC adapters, subscriptions,
and persistent storage remain separate ingress work.

## 4. Does / does-not
- **Does now:** accept already-normalized `NormalizedDatum` records; validate confidence;
  retain ordered per-feed in-session history up to a configured capacity; return explicit
  `backpressure` instead of silently evicting or dropping data; expose history to native M3
  bridges. Current calibrated consumers use `price_tick`, `rss_news`, `dex_pool_state`, and
  `on_chain_event`.
- **Does not now:** open external streams, poll APIs, persist history, maintain subscriptions,
  transform heterogeneous provider payloads, or synthesize execution fills.
- **Does not conceptually:** predict or trade; interpretation belongs to consumers.

## 5. Interface contract
- Implemented: `publish(feed_type, source, timestamp, payload, confidence)`.
- Implemented: `history(feed_type) -> [NormalizedDatum]`.
- Planned, not implemented: source adapters, subscriptions, time-range queries, persistence, and
  provider-specific normalization.
- `FeedType` remains open-ended; the economy currently exercises `price_tick`, `rss_news`,
  `on_chain_event`, and `dex_pool_state`, with `execution_fill` / `portfolio_state`
  reserved for later execution feedback.
- `NormalizedDatum { feed_type, source, timestamp, payload, confidence }` — current common shape.
  `confidence` is source-supplied/ingress reliability metadata, not M2's declaration of truth.
- Target provenance revision:
  `Observation { observation_id, feed_type, source_id, observed_at, received_at, payload,
  source_confidence, provenance, supersedes? }`.
  Contradictory observations get different IDs and remain simultaneously addressable.
- Target derived assessment:
  `SourceAssessment { source_id, regime, metric, value, recurrence, observation_refs,
  evaluated_at }`. Assessments live in economic memory and may influence consumers, but never
  mutate or replace the underlying `Observation`.

## 6. Dependencies & runtime state
- External data adapters — open; callers/tests currently provide normalized data directly.
- M1 Marketplace execution feedback — open; live fills/portfolio state do not exist yet.
- M3a/M3b/M3c/M3e — active history consumers through their Tcl runners.
- M3d/M3f/M3g — native kernels exist; no feed-query bridge yet.
- M5 Traders — no direct feed-reader facade is currently exposed.

## 7. Invariants / laws
- **L1 (C4):** data feeds are **raw and unnormalized in meaning** — the pipeline normalizes
  *format* (schema, timestamps, units) but never interprets, filters, or editorialize content.
- **L2 (C4 target):** **bidirectional flow** — external observations and internal execution
  feedback use the same normalized datum shape. **Current implementation:** normalized ingress
  to history is live; execution-fill/portfolio feedback is reserved because execution is
  simulation-only and no feedback adapter exists yet.
- **L3 (C3):** **backpressure, not drop** — if a consumer is slow, buffer up to a cap, then
  apply backpressure to the source. Never silently drop data points.
- **L4 (C3):** every datum carries a **source and timestamp** — consumers can always trace
  where data came from and when.

## 8. Build status
1. **Done:** normalized datum storage shape.
2. **Done:** per-feed ordered in-session history.
3. **Done:** explicit capacity backpressure with no silent eviction.
4. **Done:** M3a/M3b/M3c/M3e calibrated history consumers.
5. **Next:** assign stable observation IDs and explicit provenance fields.
6. **Next:** define contradiction/replay semantics: duplicates collapse by identity; conflicting
   observations coexist.
7. **Next:** persist regime-conditioned `SourceAssessment` records separately from observations.
8. **Open:** external source adapters and provider normalization.
9. **Open:** subscriptions/fan-out, time-range queries, persistence, and execution feedback.

## 9. Tests
The M0 suite verifies accepted publishes, capacity backpressure, preserved buffered history, and
source/timestamp/confidence retention. Dedicated M3 integration suites prove real consumers for
`price_tick`, `rss_news`, `dex_pool_state`, and `on_chain_event`. Subscription, provider
normalization, persistence, and execution-feedback tests do not exist because those surfaces are
not implemented.

## 10. Open items
- External source/adaptor set and credentials/rate-limit handling.
- Per-feed capacity and persistence policy beyond the current configured in-session cap.
- Subscription/fan-out semantics if push delivery is added.
- Freshness/latency contracts per consumer.
- Execution-fill / portfolio-state feedback once a real execution layer exists.
