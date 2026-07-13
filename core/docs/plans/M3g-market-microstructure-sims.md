# M3g — Market microstructure sims

## 1. Component
Market microstructure simulation: models **order flow, liquidity depth, slippage, spread dynamics,
and cross-exchange arbitrage** at the fastest time scales (tick-level to hourly). Pops here are
**market makers, takers, and arbitrageurs** interacting across multiple venues. The sim that
operates at the highest temporal resolution — where M3a provides statistical forecasts and M3c
models pool mechanics, M3g models the *plumbing* of how orders actually execute.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Order-book microstructure theory C4 (established academic field);
DEX-specific microstructure C2 (emerging). Implementation C1.

## 3. Language & location
TBD · `src/economy/sims/microstructure/`. Needs high-frequency data handling and event-driven
simulation. Rust, C++, or Python with optimized event loop.

## 4. Does / does-not
- **Does:** simulate order flow across venues (DEXs and CEXs); model bid-ask spread dynamics as a
  function of inventory risk and adverse selection; simulate slippage curves for various order
  sizes; model cross-exchange arbitrage opportunities and their decay; operate at **tick-level
  resolution** (sub-second to minute); produce bounded predictions on execution quality, optimal
  routing, and liquidity conditions.
- **Does-not:** model protocol consensus (M3f); model macro token supply (M3e); model social
  behavior (M3b); execute trades (Marketplace does).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** execution cost ranges and liquidity intervals.
  Example: `{ value: 0.0034, lower_bound: 0.0018, upper_bound: 0.0052, confidence: 0.85,
  time_horizon: "next_trade", sim_type: "market_microstructure" }` — expected slippage (%) for a
  10 ETH market sell.
  Example: `{ value: 12400, lower_bound: 8200, upper_bound: 18600, confidence: 0.78,
  time_horizon: "1h", sim_type: "market_microstructure" }` — available depth (USD) within 50bps
  of mid.
- **Prediction types:** `slippage_estimate`, `spread_forecast`, `depth_profile`,
  `cross_venue_arb`, `optimal_execution_route`, `liquidity_score`.
- Calibration: ingests `price_tick`, `dex_pool_state`, and `execution_fill` from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — tick data and pool state; *stub:* canned order book snapshots.
- M3c AMM sims — pool mechanics for DEX venues; *stub:* fixed pool state.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C4):** microstructure operates at the **highest temporal resolution** — predictions are
  valid for seconds to hours, not days. Stale microstructure data is worse than no data.
- **L2 (C4):** slippage is a **function of order size and current depth** — not a fixed
  percentage. The sim must model the non-linear relationship.
- **L3 (C3):** cross-venue arbitrage opportunities **decay** — the sim models the time-to-close
  of an arb opportunity, not just its existence.

## 8. Build steps
1. Implement a simplified order-book simulator (limit orders, market orders, cancels).
2. Add spread dynamics (inventory-based market maker model).
3. Add slippage curves (order size → execution cost).
4. Add cross-venue arb detection and decay modeling.
5. Wire M2 tick data → calibration.

## 9. Tests
Slippage: larger orders produce greater slippage. Spread: spread widens under adverse selection.
Arb decay: detected arb opportunity closes over time. Depth: depth profile matches order book
state. Bounds: all outputs bounded. Resolution: predictions update at tick frequency.

## 10. Open items
- CEX order book data access (API limitations, costs).
- DEX-specific microstructure (AMM pools don't have order books — translate pool state to
  equivalent depth/spread).
- Latency modeling (how fast can our traders actually reach an arb?).
- Which venues to model initially.
