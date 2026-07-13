# M3 — Sims hub (market prediction simulations)

## 1. Component
The economy organ's prediction engine: **always-running simulations** ("Sims") populated by
autonomous simulation agents ("Pops") that model market dynamics across multiple mathematical
domains and time scales. Sims are **queryable at any time** by Traders (M5) — they produce
**predictions with explicit upper and lower bounds** on every output value. This is the hub spec;
individual sim types have dedicated sub-specs (M3a–M3g).

The academic foundations span AMM mechanism design [1,2], MEV game theory [3,4,5], macro
tokenomics via SDEs [6,7], and evolutionary consensus games [8–11].

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C3; implementation C1. Mathematical foundations C4 (literature
established); specific model parameters C1.

## 3. Language & location
TBD · `src/economy/sims/`. Numerical computing (Julia, Python/NumPy, Octave, or Rust) for the
simulation cores. A query facade accessible to Traders. Each sim type (M3a–M3g) may use a
different runtime suited to its math.

## 4. Does / does-not
- **Does:** tick-advance continuously at **≥ 360:1** (1 wall-second = 1 sim-hour minimum)
  across **six concurrent time horizons** — tick/hourly, daily, weekly, monthly, annual, and
  5-year forecast windows; every tick advances every sim; maintain populations of Pops whose
  behaviors emerge from the sim's mathematical model; ingest live data from Data Feeds (M2)
  for calibration; respond to Trader queries with bounded predictions; produce outputs with
  **explicit upper/lower bounds** on every prediction value.
  | Horizon | Window | At 360:1 floor (1s wall = 1h sim) |
  |---------|--------|-----------------------------------|
  | Tick–hourly | Next 1–60 min | Covered in <1s wall time |
  | Daily | Next 24h | Covered in 24s wall time |
  | Weekly | Next 7d | Covered in ~168s wall time |
  | Monthly | Next 30d | Covered in ~720s wall time |
  | Annual | Next 365d | Covered in ~2.4h wall time |
  | 5-year | Next 1825d | Covered in ~12h wall time |
- **Does-not:** trade (Traders/Marketplace do); make decisions for traders (it informs, they
  decide); enforce laws (Marketplace does); supervise behavior (Conductor/SAE do); skip ticks;
  run slower than 360:1.

## 5. Interface contract
- `query(sim_type: SimType, query: PredictionQuery) -> BoundedPrediction`.
  `SimType` ∈ { `statistical`, `sociological`, `amm_liquidity`, `mev_adversarial`,
  `tokenomics_macro`, `consensus_staking`, `market_microstructure` } (M3a–M3g).
- `BoundedPrediction { value, lower_bound, upper_bound, confidence, time_horizon, sim_type, timestamp }`.
  Every output is bounded — no point estimates without uncertainty ranges.
  Example: `{ value: 7.2, lower_bound: 5.8, upper_bound: 8.9, confidence: 0.73,
  time_horizon: "4h", sim_type: "amm_liquidity" }`.
- `status(sim_type?) -> { running, pop_count, last_calibration, data_freshness }` — health check.
- `calibrate(sim_type, feed_data: [NormalizedDatum])` — Data Feeds (M2) pushes live data for
  model recalibration.

## 6. Dependencies & stubs
- M2 Data Feeds — calibration data source; *stub:* canned market data.
- M5 Traders — query consumers; *stub:* canned queries.
- M3a–M3g sub-specs — individual sim implementations; *stub:* each returns fixed predictions.

## 7. Invariants / laws
- **L1 (C5):** sims are **always running** — they are not invoked on demand. Traders query
  current state; they don't trigger computation.
- **L2 (C5):** every prediction output includes **explicit upper and lower bounds** — no
  unbounded point estimates. Uncertainty is a first-class value, not an afterthought.
- **L3 (C5):** all sims are **tick-advanced and continuous** — they advance every tick, never
  skip. The slowest system runs at **360:1** — 1 wall-clock second = 1 simulated hour. Sims
  may run faster but never slower.
- **L4 (C4):** sims are **read-only from traders' perspective** — a query never mutates sim
  state. Calibration happens only from Data Feeds (M2).
- **L5 (C4):** each sim type is **independent** — failure in one sim does not cascade to others.
  Degraded sims report their status; traders handle missing predictions.
- **L6 (C3):** Pops are **simulation constructs, not AI actors** — they follow mathematical
  rules within the sim. Traders (M5) are the AI actors.

## 8. Build steps
1. Define `BoundedPrediction` shape and query protocol.
2. Build the sim runner (lifecycle management for always-on sims).
3. Wire M2 Data Feeds → calibration pipeline.
4. Implement sub-specs M3a–M3g as they land.
5. Wire trader query interface.

## 9. Tests
Always-on: sim running after init without external trigger. Bounded output: every prediction has
lower ≤ value ≤ upper. Query: trader receives prediction without mutating sim. Independence:
one sim's failure doesn't affect others. Calibration: new data updates model state.

## 10. Open items
- Pop lifecycle (birth/death/mutation within sims, or fixed populations?).
- Cross-sim aggregation (do traders query individual sims, or is there a meta-prediction layer?).
- Calibration frequency per sim type.
- Computational budget per sim (how much CPU/GPU each can consume).
