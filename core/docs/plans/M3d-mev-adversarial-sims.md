# M3d — MEV & adversarial extraction sims

## 1. Component
Maximal Extractable Value and adversarial simulation: models **transaction ordering as an
optimization problem**, **Priority Gas Auctions (PGA) as all-pay auctions**, **block building as a
multidimensional knapsack problem**, **cross-chain adversarial arbitrage**, and **Dynamic
Stackelberg Mean-Field Games (DSMFG) for protocol-level adversarial policy**. Pops here are
**searcher bots, block builders, validators, cross-chain arbitrageurs, and adversarial
manipulators** competing for extractable value across **six concurrent time horizons**.

Grounded in ACM MEV game theory [3], knapsack auction literature [4,5], Kolokoltsov adversarial
dynamics (non-linear Fokker-Planck with WENO shock capturing), and DSMFG bilevel optimization
(leader policy + follower MFG equilibrium).

## 2. Status / certainty
DESIGN-FIRST · ABSENT. PGA-as-all-pay-auction C4 (ACM [3]); knapsack formulation C4 (Cornell
[4,5]); cross-chain arbitrage C4 (ACM SIGMETRICS 2025, 5.5x growth since Dencun); DSMFG bilevel
optimization C3 (emerging — SMFRL solvers); Kolokoltsov adversarial C3 (non-linear Fokker-Planck;
WENO discretization established but crypto application novel). Parameterization C1.

## 3. Language & location
FORTRAN [WHICH IMPLEMENTATIOBS?] · `src/economy/sims/mev/`. **Fortran** — dense numerical loops for PDE solvers (WENO
shock-capturing), knapsack combinatorics, and continuous-time auction modeling at the throughput
MEV extraction demands; no GC pauses during hot-path simulation.

## 4. Does / does-not
- **Does:** simulate Priority Gas Auctions where multiple searcher bots compete for the same
  arbitrage opportunity $V$ by bidding gas fees $g$ in a continuous-time all-pay auction; model
  block building as a multidimensional knapsack problem (scarce block space, heterogeneous
  transaction values/sizes); simulate endogenous selection cutoffs under paid-priority ordering;
  model **cross-chain adversarial arbitrage** with inventory vs. bridge execution trade-off:
  $\pi_{\text{inv}} = (P_{\text{src}} - P_{\text{dst}} - \text{slippage} - \text{gas}) \times q$
  vs. $\pi_{\text{bridge}} = (P_{\text{src}} - P_{\text{dst}} - \text{fee} -
  \text{depreciation}(\Delta t)) \times q$ where bridge latency $\Delta t \approx 242$s vs.
  inventory $\Delta t \approx 9$s; solve **Dynamic Stackelberg MFG** for adversarial policy
  design — bilevel optimization where a leader (protocol/regulator) sets policy and followers
  (searchers) respond as an MFG equilibrium: the leader solves
  $\min_\alpha J_L(\alpha, m^*(\alpha))$ subject to $m^*(\alpha)$ being the MFG Nash equilibrium
  of followers under policy $\alpha$; model **Kolokoltsov adversarial dynamics** via non-linear
  Fokker-Planck: $\partial_t m + \nabla \cdot (b(x,m)m) = \frac{1}{2}\nabla^2(\sigma^2 m)$
  with WENO shock-capturing for discontinuous adversarial strategies; predict MEV exposure for
  proposed trades; produce bounded predictions on extraction risk across all six time horizons.
- **Does-not:** extract MEV itself (simulator, not a searcher); model AMM pool math (M3c);
  model social dynamics (M3b); execute cross-chain bridges (Marketplace does).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** extraction probability ranges, gas cost intervals, cross-chain profit
  bounds, DSMFG equilibrium stability ranges.
- **Time-horizon mapping** (all run concurrently, tick-advanced, 90:1 (1s wall = 90s sim)):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Tick–hourly | PGA auctions, sandwich detection, cross-chain arb | Every block |
  | Daily | Knapsack builder strategies, MEV landscape | Hourly roll |
  | Weekly | Searcher population dynamics, cross-chain flow patterns | Daily roll |
  | Monthly | DSMFG policy equilibria, adversarial strategy evolution | Weekly roll |
  | Annual | Kolokoltsov adversarial long-run dynamics | Monthly roll |
  | 5-year | Structural MEV regime shifts, protocol-level policy effects | Quarterly roll |
- Examples:
  `{ value: 0.23 / 15.00 , lower_bound: 0.11 / 15.00 , upper_bound: 0.38 / 15.00 , confidence: 8.00 / 10.00,
  time_horizon: "block", sim_type: "mev_adversarial" }`
- **Prediction types:** `sandwich_probability`, `frontrun_risk`, `optimal_gas_bid`,
  `block_inclusion_probability`, `mev_exposure`, `cross_chain_arb_profit`,
  `adversarial_policy_stability`, `searcher_population_shift`.
- Calibration: ingests `on_chain_event` (mempool-like data), `price_tick`, and cross-chain
  bridge state from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — on-chain events, gas data, cross-chain state; *stub:* canned snapshots.
- M3 Sims hub — lifecycle management; *stub:* manual init.
- M3c AMM sims — pool state for arbitrage opportunity detection; *stub:* fixed pool state.

## 7. Invariants / laws
- **L1 (C5):** PGA is modeled as an **all-pay auction** — all bidders pay their gas whether they
  win or not. The sim must capture this cost structure (not winner-pays-only).
- **L2 (C5):** block building is a **knapsack problem, not a queue** — builders optimize for
  total extracted value subject to gas limit constraints, not first-come-first-served.
- **L3 (C4):** MEV exposure predictions are **pre-trade** — traders query this sim *before*
  submitting to the Marketplace to understand their extraction risk.
- **L4 (C4):** cross-chain arb models **both execution paths** — inventory (fast, capital-
  intensive) and bridge (slow, capital-light) — never assumes one dominates.
- **L5 (C3):** DSMFG solutions are **bilevel** — the leader's optimal policy depends on the
  followers' MFG equilibrium, which itself depends on the leader's policy. Fixed-point iteration
  or SMFRL solvers required.

## 8. Build steps
1. Implement the PGA all-pay auction model (N searchers, opportunity value V, gas bids).
2. Implement the block-building knapsack solver.
3. Add sandwich/frontrun detection heuristics.
4. Implement cross-chain arb model (inventory vs. bridge, latency, MEV exposure).
5. Implement Kolokoltsov non-linear Fokker-Planck with WENO discretization.
6. Implement DSMFG bilevel solver (leader policy + follower MFG equilibrium).
7. Wire M2 on-chain + cross-chain data → calibration.
8. Wire pre-trade query interface for Traders.

## 9. Tests
All-pay: losing bidders still pay gas cost. Knapsack: builder selects optimal transaction set
under gas limit. Sandwich: known sandwich-vulnerable trade flagged; non-vulnerable trade clear.
Cross-chain: inventory path preferred when latency advantage exceeds capital cost. DSMFG: leader
policy converges to fixed point with follower equilibrium. Kolokoltsov: WENO captures shock
discontinuities in adversarial strategy distribution. Bounds: all outputs bounded. Pre-trade:
query does not submit any transaction. Speed: sim tick-advances at 90:1.

## 10. Open items
- Mempool data access (public mempool? private order flow?).
- Which MEV types to model initially (sandwich, backrun, liquidation, JIT?).
- Multi-block MEV (cross-block extraction strategies).
- DSMFG solver choice (SMFRL? fictitious play? direct bilevel optimization?).
- WENO order for Kolokoltsov (3rd? 5th? tradeoff with compute budget).
- Which L2s/bridges to model for cross-chain (Arbitrum? Optimism? Base?).
