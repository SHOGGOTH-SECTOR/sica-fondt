# M3d — MEV & adversarial extraction sims

## 1. Component
Maximal Extractable Value simulation: models **transaction ordering as an optimization problem**,
**Priority Gas Auctions (PGA) as all-pay auctions**, and **block building as a multidimensional
knapsack problem**. Pops here are **searcher bots, block builders, and validators** competing for
extractable value. Grounded in ACM MEV game theory [3] and knapsack auction literature [4,5].

## 2. Status / certainty
DESIGN-FIRST · ABSENT. PGA-as-all-pay-auction model C4 (ACM [3]); knapsack formulation C4
(Cornell [4,5]); simulation parameterization C1.

## 3. Language & location
TBD · `src/economy/sims/mev/`. Needs combinatorial optimization (for knapsack) and continuous-time
auction modeling. Python (PuLP/OR-Tools for optimization), Rust, or Julia.

## 4. Does / does-not
- **Does:** simulate Priority Gas Auctions where multiple searcher bots compete for the same
  arbitrage opportunity $V$ by bidding gas fees $g$ in a continuous-time all-pay auction; model
  block building as a multidimensional knapsack problem (scarce block space, heterogeneous
  transaction values/sizes); simulate endogenous selection cutoffs under paid-priority ordering;
  predict MEV exposure for proposed trades; produce bounded predictions on extraction risk and
  optimal gas strategies.
- **Does-not:** extract MEV itself (this is a simulator, not a searcher); model AMM mechanics
  (M3c handles pool math); model social dynamics (M3b).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** extraction probability ranges and gas cost intervals.
  Example: `{ value: 0.23, lower_bound: 0.11, upper_bound: 0.38, confidence: 0.80,
  time_horizon: "next_block", sim_type: "mev_adversarial" }` — probability this trade gets
  sandwiched.
  Example: `{ value: 14.7, lower_bound: 8.2, upper_bound: 22.5, confidence: 0.75,
  time_horizon: "next_block", sim_type: "mev_adversarial" }` — optimal gas bid (gwei) for
  a given opportunity.
- **Prediction types:** `sandwich_probability`, `frontrun_risk`, `optimal_gas_bid`,
  `block_inclusion_probability`, `mev_exposure`.
- Calibration: ingests `on_chain_event` (mempool-like data) and `price_tick` from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — on-chain events and gas data; *stub:* canned mempool snapshots.
- M3 Sims hub — lifecycle management; *stub:* manual init.
- M3c AMM sims — pool state for arbitrage opportunity detection; *stub:* fixed pool state.

## 7. Invariants / laws
- **L1 (C4):** PGA is modeled as an **all-pay auction** — all bidders pay their gas whether they
  win or not. The sim must capture this cost structure (not winner-pays-only).
- **L2 (C4):** block building is a **knapsack problem, not a queue** — builders optimize for
  total extracted value subject to gas limit constraints, not first-come-first-served.
- **L3 (C3):** MEV exposure predictions are **pre-trade** — traders query this sim *before*
  submitting to the Marketplace to understand their extraction risk.

## 8. Build steps
1. Implement the PGA all-pay auction model (N searchers, opportunity value V, gas bids).
2. Implement the block-building knapsack solver.
3. Add sandwich/frontrun detection heuristics.
4. Wire M2 on-chain data → calibration of searcher population and gas dynamics.
5. Wire pre-trade query interface for Traders.

## 9. Tests
All-pay: losing bidders still pay gas cost. Knapsack: builder selects optimal transaction set
under gas limit. Sandwich: known sandwich-vulnerable trade flagged; non-vulnerable trade clear.
Bounds: all outputs bounded. Pre-trade: query does not submit any transaction.

## 10. Open items
- Mempool data access (public mempool? private order flow?).
- Which MEV types to model initially (sandwich, backrun, liquidation, JIT?).
- Multi-block MEV (cross-block extraction strategies).
- Integration with M3c (arbitrage opportunities arise from AMM pool state).
