# M3c — AMM & liquidity pool sims

## 1. Component
Automated Market Maker simulation: models **constant-product invariant mechanics, impermanent
loss, and the non-cooperative game between liquidity providers and arbitrageurs**. Pops here are
**LP positions and arbitrage bots** operating on the $x \cdot y = k$ curve. Grounded in the DEX/AMM
literature [1,2].

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Mathematical foundations C5 (constant product invariant is proven);
impermanent loss formula C5 (closed-form: $\text{IL}(r) = \frac{2\sqrt{r}}{1+r} - 1$);
simulation parameterization C1.

## 3. Language & location
TBD · `src/economy/sims/amm/`. Needs precise fixed-point or arbitrary-precision arithmetic for
invariant calculations (Solidity-equivalent precision). Python, Rust, or Julia.

## 4. Does / does-not
- **Does:** simulate constant-product pools with fee parameter $\gamma$:
  $(x + \gamma \Delta x)(y - \Delta y) = k$; model impermanent loss as a function of price ratio
  shift $r$; simulate LP strategies (provide, withdraw, rebalance) against arbitrageur behavior;
  model non-linear price slippage from the curve geometry; produce bounded predictions on pool
  profitability, IL risk, and optimal LP ranges.
- **Does-not:** model consensus mechanics (M3f); model social behavior (M3b); execute real swaps
  (Marketplace does).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** IL ranges and pool return intervals.
  Example: `{ value: -0.034, lower_bound: -0.058, upper_bound: -0.012, confidence: 0.90,
  time_horizon: "7d", sim_type: "amm_liquidity" }` — projected impermanent loss for ETH/USDC pool.
  Example: `{ value: 0.082, lower_bound: 0.041, upper_bound: 0.127, confidence: 0.85,
  time_horizon: "30d", sim_type: "amm_liquidity" }` — net LP return (fees − IL).
- **Time-horizon mapping** (all run concurrently, tick-advanced, 90:1 (1s wall = 90s sim)):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Tick–hourly | Slippage curves, invariant state, JIT liquidity | Every swap event |
  | Daily | IL accumulation, fee income, LP profitability | Hourly roll |
  | Weekly | Optimal LP range recalculation, pool composition | Daily roll |
  | Monthly | LP strategy evolution (passive vs. active rebalance) | Weekly roll |
  | Annual | Pool lifecycle, fee tier competitiveness | Monthly roll |
  | 5-year | AMM design evolution, concentrated liquidity adoption | Quarterly roll |
- **Prediction types:** `impermanent_loss`, `pool_return`, `optimal_range`, `slippage_estimate`,
  `lp_withdrawal_threshold`.
- Calibration: ingests `dex_pool_state` and `price_tick` from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — pool state and price data; *stub:* canned pool snapshots.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C5):** the **constant product invariant** $x \cdot y = k$ (adjusted for fees $\gamma$)
  is the ground truth — all pool state transitions must satisfy the invariant or the sim is wrong.
- **L2 (C5):** **impermanent loss** follows the proven formula
  $\text{IL}(r) = \frac{2\sqrt{r}}{1+r} - 1$ — the sim must reproduce this exactly for the
  base case (no fees, no concentrated liquidity).
- **L3 (C4):** LP withdrawal thresholds are **derived from IL, not hardcoded** — the sim
  calculates at what price ratio a rational LP withdraws, based on the IL formula and fee income.

## 8. Build steps
1. Implement the constant-product pool simulator with fee parameter.
2. Verify IL formula reproduction against known inputs.
3. Add LP pop strategies (passive hold, active rebalance, just-in-time liquidity).
4. Add arbitrageur pops (sandwich, backrun).
5. Wire M2 pool state data → calibration.

## 9. Tests
Invariant: every swap satisfies $(x + \gamma \Delta x)(y - \Delta y) = k$. IL formula: matches
closed-form for known price ratios. Slippage: large swaps produce greater slippage than small.
LP threshold: LP withdraws when IL exceeds fee income. Bounds: all outputs bounded.

## 10. Open items
- Concentrated liquidity (Uniswap v3 style) — extends the base model significantly.
- Multi-pool routing (split swaps across pools).
- Which specific pools to simulate (ETH/USDC? stablecoin pairs?).
