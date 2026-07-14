# M3g — Market microstructure sims

## 1. Component
Market microstructure simulation: models **order flow, liquidity depth, slippage, spread dynamics,
optimal execution, and cross-exchange arbitrage** at the fastest time scales. Pops here are
**market makers, takers, and arbitrageurs** interacting across multiple venues. Includes the
**Almgren-Chriss optimal execution framework** for minimizing market impact of large orders.
Operates at the highest temporal resolution — where M3a provides statistical forecasts and M3c
models pool mechanics, M3g models the *plumbing* of how orders actually execute, across **six
concurrent time horizons** at tick-advanced, 90:1 (1s wall = 90s sim).

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Order-book microstructure theory C4 (established). Almgren-Chriss
optimal execution C5 (industry standard since 2001; crypto adaptations validated 2023–2024,
Kurz CMC thesis). DEX-specific microstructure C2 (emerging). Implementation C1.

## 3. Language & location
TBD · `src/economy/sims/microstructure/`. Needs high-frequency data handling, event-driven
simulation, and Riccati equation solvers for optimal execution trajectories. C++, Fortran,
or Julia.

## 4. Does / does-not
- **Does:** simulate order flow across venues (DEXs and CEXs); model bid-ask spread dynamics as a
  function of inventory risk and adverse selection; simulate slippage curves for various order
  sizes; solve **Almgren-Chriss optimal execution**:
  $\min \int_0^T [\lambda \cdot x(t) \cdot \dot{x}(t) + \eta \cdot \dot{x}(t)^2] \, dt$
  where $\lambda$ = permanent impact, $\eta$ = temporary impact, $x(t)$ = remaining order —
  splits large orders across time to minimize market impact + timing risk; impact parameters
  $\lambda, \eta$ re-estimated from order-flow streams every 10–30s; execution trajectory solved
  via Riccati equations in <100ms; model cross-exchange arbitrage opportunities and their decay;
  operate at **tick-level resolution** (sub-second to minute); produce bounded predictions on
  execution quality, optimal routing, and liquidity conditions.
- **Does-not:** model protocol consensus (M3f); model macro token supply (M3e); model social
  behavior (M3b); execute trades (Marketplace does).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** execution cost ranges, liquidity intervals, optimal trajectory envelopes.
- **Time-horizon mapping** (all run concurrently, tick-advanced, 90:1 (1s wall = 90s sim)):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Tick–hourly | Almgren-Chriss execution, slippage, spread, arb decay | Every tick |
  | Daily | Liquidity regime, venue depth profiles | Hourly roll |
  | Weekly | Cross-venue flow patterns, impact parameter drift | Daily roll |
  | Monthly | Structural liquidity shifts, venue market share | Weekly roll |
  | Annual | Microstructure regime (DEX vs CEX share evolution) | Monthly roll |
  | 5-year | Venue topology evolution, structural impact trends | Quarterly roll |
- Examples:
  `{ value: 0.0034, lower_bound: 0.0018, upper_bound: 0.0052, confidence: 8.50,
  time_horizon: "next_trade", sim_type: "market_microstructure" }` — slippage (%) for 10 ETH.
  `{ value: 12400, lower_bound: 8200, upper_bound: 18600, confidence: 7.80,
  time_horizon: "1h", sim_type: "market_microstructure" }` — depth (USD) within 50bps.
  `{ value: [0.3, 0.3, 0.2, 0.1, 0.1], lower_bound: null, upper_bound: null, confidence: 8.00,
  time_horizon: "30min", sim_type: "market_microstructure" }` — Almgren-Chriss optimal execution
  schedule (fraction per 6-min bucket for 100 ETH sell).
- **Prediction types:** `slippage_estimate`, `spread_forecast`, `depth_profile`,
  `cross_venue_arb`, `optimal_execution_schedule`, `optimal_execution_route`,
  `liquidity_score`, `impact_estimate`.
- Calibration: ingests `price_tick`, `dex_pool_state`, and `execution_fill` from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — tick data and pool state; *stub:* canned order book snapshots.
- M3a Statistical — volatility estimates for Almgren-Chriss timing risk; *stub:* fixed vol.
- M3c AMM sims — pool mechanics for DEX venues; *stub:* fixed pool state.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C5):** microstructure operates at the **highest temporal resolution** — predictions are
  valid for seconds to hours, not days. Stale microstructure data is worse than no data.
- **L2 (C5):** slippage is a **function of order size and current depth** — not a fixed
  percentage. The sim must model the non-linear relationship.
- **L3 (C5):** Almgren-Chriss impact parameters $\lambda, \eta$ are **estimated from live data**,
  never hardcoded — crypto impact dynamics differ by asset, venue, and time-of-day.
- **L4 (C4):** cross-venue arbitrage opportunities **decay** — the sim models the time-to-close
  of an arb opportunity, not just its existence.
- **L5 (C4):** optimal execution trajectories are **re-solved on every significant state change**
  (vol spike, depth drop, regime transition) — a stale trajectory is worse than naive execution.

## 8. Build steps
1. Implement a simplified order-book simulator (limit orders, market orders, cancels).
2. Add spread dynamics (inventory-based market maker model).
3. Add slippage curves (order size → execution cost).
4. Implement Almgren-Chriss optimal execution (Riccati solver, impact estimation).
5. Add cross-venue arb detection and decay modeling.
6. Wire M2 tick data → calibration of impact parameters.
7. Wire M3a vol estimates → Almgren-Chriss timing risk component.

## 9. Tests
Slippage: larger orders produce greater slippage. Spread: spread widens under adverse selection.
Almgren-Chriss: optimal trajectory minimizes total cost vs. naive execution on backtest; impact
parameters update when market conditions change. Arb decay: detected arb opportunity closes over
time. Depth: depth profile matches order book state. Bounds: all outputs bounded. Resolution:
predictions update at tick frequency. Speed: sim tick-advances at 90:1.

## 10. Open items
- CEX order book data access (API limitations, costs).
- DEX-specific microstructure (AMM pools don't have order books — translate pool state to
  equivalent depth/spread).
- Latency modeling (how fast can our traders actually reach an arb?).
- Almgren-Chriss extensions for crypto (volume-dependent variant? discrete block propagation?).
- Which venues to model initially.
