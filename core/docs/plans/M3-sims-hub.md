# M3 — Sims hub (market prediction simulations)

## 1. Component
The economy organ's prediction engine: **always-running simulations** ("Sims") populated by
autonomous simulation agents ("Pops") that model market dynamics across multiple mathematical
domains and time scales. Sims produce raw simulation data; the hub transforms it into
**predictions with explicit upper and lower bounds** and publishes them continuously to the
Marketplace via M2 Data Feeds. Traders query predictions from the Marketplace (M1), not from the
hub directly. This is the hub spec; individual sim types have dedicated sub-specs (M3a–M3g).

The academic foundations span AMM mechanism design [1,2], MEV game theory [3,4,5], macro
tokenomics via SDEs [6,7], and evolutionary consensus games [8–11].

## 1A. Operational doctrine
- **Purpose:** Sims are complementary mathematical senses over different scopes of the same
  environment. They are not contestants trying to become one canonical market oracle.
- **No forced reconciliation:** apparent disagreement is first treated as a question of scope,
  horizon, conditioning, or resolution. Traders interpret local implications; M6 interprets
  portfolio/system implications. M3 itself does not vote, average, or choose a winner.
- **Scoped correctness:** `correctness` means empirical accuracy with respect to a Sim's declared
  target, horizon, conditioning assumptions, and regime. Scores from different Sim types are not
  directly comparable unless their scopes are explicitly aligned.
- **Calibration metric:** every prediction family should accumulate longitudinal calibration loss
  against realization and declared uncertainty, conditioned on regime:
  `L(prediction, realization, declared_uncertainty | scope, regime)`.
- **Memory:** repeated calibration failures, regime-specific strengths, and persistent bias become
  durable economic memory. A single miss is evidence; repetition changes trust.
- **Completion criterion:** a native Sim is runtime-complete only when calibration input,
  native execution, bounded publication, realization capture, longitudinal scoring, degraded-state
  handling, and replayable tests all exist. Source presence alone is never completion.

## 2. Status / certainty
MIXED · EXECUTABLE HUB + FOUR V1 RUNTIME BRIDGES + THREE NATIVE KERNELS.
`core/src/economy/sims/` contains all seven native engine trees, a seven-engine registry, the
bounded-prediction hub, and a live Tcl event-loop clock for all six horizons. M3a, M3b, M3c,
and M3e are wired end-to-end from normalized M2 history through their native runtimes into the
M3 hub and Marketplace. M3d, M3f, and M3g are tested native kernels but do not yet have equivalent
Tcl process/query bridges. The scheduler currently advances horizon clocks; it does **not** spawn
all seven engines or republish every prediction automatically. Role C3; hub/runtime implementation
C3; live-market parameterization remains data-dependent.

## 3. Language & location
**Tcl 8.6** · `core/src/economy/sims/`. The hub is syntax-agnostic, but V1 does not force one
wire protocol on every native engine. Current bridges are deliberately native:
- **M3a / R:** Tcl invokes the R engine and publishes typed bounded results.
- **M3b / ECLiPSe Prolog:** Tcl submits native ECLiPSe goals and parses bounded results.
- **M3c / Solidity:** Tcl uses a read-only ABI against an ephemeral/local EVM query contract in CI.
- **M3e / Fortran:** Tcl writes normalized numeric history to `tokenomics_query` over stdin and
  parses its single bounded result line.
- **M3d / Fortran, M3f / ECLiPSe, M3g / Fortran:** native kernels exist; runtime bridges remain open.

## 4. Does / does-not
- **Implemented now:** maintain the canonical seven-engine registry; run the six-horizon wall→sim
  clock at 90:1 or faster; validate every published prediction against the common bounded schema;
  retain the latest prediction per sim type; expose those predictions to Traders only through
  Marketplace; calibrate and query M3a/M3b/M3c/M3e from M2 histories using native runtimes.
- **Target runtime behavior:** continuously refresh native simulations on their own cadences and
  publish fresh bounded predictions without a Trader query triggering computation. The horizon
  clock needed for that loop exists, but the automatic per-engine dispatch/refresh loop is not yet
  implemented.
- **Does-not:** trade; make Trader decisions; enforce Marketplace law; supervise Trader behavior;
  bypass M1, M4, M6, M7, or D1; treat registered source presence as proof that a native engine is
  runtime-wired.

  | Horizon | Window | Clock ratio |
  |---------|--------|-------------|
  | Tick–hourly | Next 1–60 min | 90:1 |
  | Daily | Next 24h | 2,160:1 |
  | Weekly | Next 7d | 15,120:1 |
  | Monthly | Next 30d | 64,800:1 |
  | Annual | Next 365d | ~788,000:1 |
  | 5-year | Next 1825d | ~3,942,000:1 |

## 5. Interface contract
- `publish(sim_type, BoundedPrediction)` validates and stores the latest bounded result for one
  of `statistical`, `sociological`, `amm_liquidity`, `mev_adversarial`,
  `tokenomics_macro`, `consensus_staking`, or `market_microstructure`.
- Current V1 minimum:
  `BoundedPrediction { value, lower_bound, upper_bound, confidence, correctness, certainty,
  time_horizon, sim_type, timestamp, token_ticker, recent_shift, ...metadata }`.
  Every numeric result obeys `lower_bound ≤ value ≤ upper_bound`; quality metrics are in
  `[0,10]`.
- **Required next schema revision for meaningful correctness:**
  `PredictionScope { target, prediction_type, horizon, conditioning, regime, calibration_window }`
  travels with every result. A `correctness` value without that scope metadata is insufficient
  for durable cross-time comparison.
- Native engines may preserve extra metadata such as M3b population state, M3c range/routing
  detail, or M3e yield-allocation weights.
- `Marketplace.predictions(trader_id, sim_type)` is the Trader-facing read path. Traders never
  receive the raw hub object or native runtime handle.
- Current calibrated facade methods on `::stomach::Economy`:
  `statistical_from_feed_type`, `sociological_from_feed`, `amm_from_feed`, and
  `tokenomics_from_feed`.
- Registry presence and horizon-clock state are operational metadata; neither implies automatic
  native execution.

## 6. Dependencies & runtime state
- **M2 Data Feeds:** implemented in-memory normalized history + explicit backpressure. External
  WebSocket/RSS/on-chain adapters remain open.
- **M1 Marketplace:** implemented prediction-consumer facade; holds no native sim handles.
- **M3a:** V1 native R bridge wired and CI-verified.
- **M3b:** V1 native ECLiPSe bridge wired and CI-verified.
- **M3c:** V1 native Solidity/read-only EVM bridge wired and CI-verified.
- **M3d:** strict-Fortran kernel/tests present; Tcl query bridge open.
- **M3e:** V1 native Fortran query bridge wired and CI-verified.
- **M3f:** ECLiPSe kernel/tests present; Tcl query bridge open.
- **M3g:** strict-Fortran kernel/tests present; Tcl query bridge open.

## 7. Invariants / laws
- **L1 (C5):** sims are **always running** — they are not invoked on demand. Traders query
  current state; they don't trigger computation.
- **L2 (C5):** every prediction output includes **explicit upper and lower bounds** — no
  unbounded point estimates. Uncertainty is a first-class value, not an afterthought.
- **L3 (C5):** all sims are **tick-advanced and continuous** — fine-grained ticks (RTS-style).
  Base speed **90:1** (1s wall = 90s sim). Longer horizons run at higher velocity with coarser
  steps and update less frequently. Each horizon completes its forecast window in **~40s wall
  time**. Each horizon runs **in parallel** — they are concurrent, not sequential. No horizon
  runs slower than 90:1.
- **L4 (C4):** sims are **read-only from traders' perspective** — traders consume predictions
  from the Marketplace; they cannot mutate sim state. Calibration happens only from Data Feeds
  (M2).
- **L5 (C4):** each sim type is **independent** — failure in one sim does not cascade to others.
  Degraded sims report their status; traders handle missing predictions.
- **L6 (C3):** Pops are **simulation constructs, not AI actors** — they follow mathematical
  rules within the sim. Traders (M5) are the AI actors.

## 8. Build status
1. **Done:** common `BoundedPrediction` validation and latest-result storage.
2. **Done:** seven-engine registry and six-horizon live scheduler.
3. **Done for M3a/M3b/M3c/M3e:** M2 history → native calibration/query → M3 publish.
4. **Kernel done, bridge open for M3d/M3f/M3g:** add the same process/query boundary.
5. **Next:** add common `PredictionScope` metadata and realization linkage so correctness is
   explicitly target/horizon/regime scoped.
6. **Next:** persist per-Sim longitudinal calibration-loss summaries into M0 economic memory.
7. **Open:** scheduler-driven automatic refresh/publish loop independent of Trader queries.
8. **Open:** persistent calibration/history storage beyond the in-session M2 buffers.

## 9. Tests
- `tclsh core/src/economy/sims/tests/hub_runtime.test` verifies the registry and six-horizon clock.
- `tclsh core/src/economy/tests/stomach.test` verifies bounded publication and Marketplace reads
  inside the M0 facade.
- Dedicated CI verifies the native + M2→native→Hub boundaries for M3a, M3b, M3c, and M3e.
- M3d and M3g compile/test under strict Fortran flags; M3f has native ECLiPSe tests.
- A future automatic-refresh test must prove predictions update without a Trader-triggered query;
  that claim is intentionally not made by the current suite.

## 10. Open items
- Native runtime/query bridges for M3d, M3f, and M3g.
- Common `PredictionScope` + realization-reference schema.
- Regime-conditioned longitudinal calibration-loss persistence.
- Scheduler-driven automatic engine refresh and bounded republishing.
- Per-Sim calibration cadence and failure/degraded-state policy.
- No default cross-Sim voting/averaging layer; any future synthesis must preserve source scopes
  and remain a Trader/M6 interpretation aid rather than declaring a winner.
- Persistent history/calibration state beyond the in-session M2 buffer.
- Explicit CPU/GPU budgets and admission/backpressure for expensive native queries.
