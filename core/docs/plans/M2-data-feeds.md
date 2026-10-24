# M2 — Data feeds (market data pipeline)

## 1. Component
The economy organ's sensory nervous system: **live RSS feeds, price streams, and on-chain data**
flowing into both the Marketplace (M1) and the Sims (M3). Sits between them — the Marketplace
produces execution data (fills, positions, P&L) that feeds back into Sims, and Sims produce
predictions that inform Traders operating through the Marketplace. Data Feeds is the bridge.

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
