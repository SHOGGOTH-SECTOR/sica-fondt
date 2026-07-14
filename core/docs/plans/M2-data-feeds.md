# M2 — Data feeds (market data pipeline)

## 1. Component
The economy organ's sensory nervous system: **live RSS feeds, price streams, and on-chain data**
flowing into both the Marketplace (M1) and the Sims (M3). Sits between them — the Marketplace
produces execution data (fills, positions, P&L) that feeds back into Sims, and Sims produce
predictions that inform Traders operating through the Marketplace. Data Feeds is the bridge.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C3; implementation C1.

## 3. Language & location
TBD · `src/economy/feeds/`. Needs async I/O for streaming data (WebSockets, SSE, RSS polling).
Pony actors are a natural fit (async, backpressure-aware).

## 4. Does / does-not
- **Does:** ingest live market data from external sources (RSS, price APIs, DEX subgraphs,
  on-chain event logs); normalize heterogeneous data into a common internal format; distribute
  to Sims (M3) for prediction and to Traders (M5) for decision-making; ingest Marketplace (M1)
  execution data (fills, portfolio state) and feed it back into Sims for calibration; maintain
  time-series history within session (ring buffer).
- **Does-not:** predict (Sims do); trade (Marketplace does); filter or editorialize data — it
  delivers raw, normalized feeds. Interpretation is the consumer's job.

## 5. Interface contract
- `subscribe(feed_type: FeedType, consumer_id) -> subscription_handle`.
  `FeedType` ∈ { `price_tick`, `rss_news`, `on_chain_event`, `dex_pool_state`, `execution_fill`,
  `portfolio_state` }.
- `publish(feed_type, data_point: NormalizedDatum)` — internal; sources push into the pipeline.
- `query_history(feed_type, time_range) -> [NormalizedDatum]` — sims and traders can pull
  historical data within the session window.
- `NormalizedDatum { feed_type, source, timestamp, payload, confidence }` — common shape.
  `confidence` ∈ [0.0, 10.0] — data source reliability per position produced (exchange-reported
  price = high; RSS sentiment = lower). Sims produce even finer-grained confidence.

## 6. Dependencies & stubs
- External data sources (price APIs, RSS, RPC nodes) — *stub:* canned market data replay.
- M1 Marketplace — execution data source (fills, positions); *stub:* canned fills.
- M3 Sims — primary consumer; *stub:* print data points.
- M5 Traders — secondary consumer; *stub:* print data points.

## 7. Invariants / laws
- **L1 (C4):** data feeds are **raw and unnormalized in meaning** — the pipeline normalizes
  *format* (schema, timestamps, units) but never interprets, filters, or editorialize content.
- **L2 (C4):** **bidirectional flow** — external data flows in (market → sims/traders), and
  internal execution data flows back (marketplace → sims). Both directions use the same
  `NormalizedDatum` shape.
- **L3 (C3):** **backpressure, not drop** — if a consumer is slow, buffer up to a cap, then
  apply backpressure to the source. Never silently drop data points.
- **L4 (C3):** every datum carries a **source and timestamp** — consumers can always trace
  where data came from and when.

## 8. Build steps
1. Define `NormalizedDatum` and `FeedType` shapes.
2. Implement the pub/sub pipeline (subscribe, publish, distribute).
3. Wire external source adapters (start with one price API + one RSS feed).
4. Wire M1 execution data feedback loop.
5. Implement session-scoped time-series history (ring buffer).

## 9. Tests
Normalization: heterogeneous inputs produce uniform `NormalizedDatum` output. Pub/sub: subscriber
receives published data. History: query returns correct time range. Backpressure: slow consumer
does not cause data loss. Bidirectional: marketplace fills reach sims via the feed.

## 10. Open items
- Which price APIs / RSS sources to support initially (CoinGecko? DeFiLlama? specific DEX
  subgraphs?).
- History buffer size / eviction policy.
- Whether feeds need authentication / rate limiting management.
- Latency requirements (how fresh must data be for each consumer type?).
