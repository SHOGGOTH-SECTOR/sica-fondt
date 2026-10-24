# M3c — AMM & liquidity pool sims

## 1. Component
Automated Market Maker simulation: models **constant-product invariant mechanics, impermanent
loss, and the non-cooperative game between liquidity providers and arbitrageurs**. Pops here are
**LP positions and arbitrage bots** operating on the $x \cdot y = k$ curve. Grounded in the DEX/AMM
literature [1,2].

## 1A. Measurement contract
This Sim inherits the M3 common epistemic contract. Its scope is **impermanent loss, pool return, liquidity range, slippage, and LP withdrawal economics**.
- Every prediction must identify `target`, `prediction_type`, `horizon`, relevant
  `conditioning`, and `regime` before its `correctness` score is meaningful.
- `confidence` describes evidential/model support; `certainty` describes stability under
  perturbation/model uncertainty; `correctness` is empirical accuracy after realization. These
  are not synonyms.
- Correctness is compared longitudinally only within compatible scopes. It is not a universal
  leaderboard against other M3 domains.
- Every prediction family must eventually link to a realization and accumulate
  regime-conditioned calibration loss. Repeated bias or repeated out-of-bound realizations feed
  M0 durable economic memory.
- This Sim does not need to agree with another Sim. Cross-domain interpretation belongs to M5/M6.

## 2. Status / certainty
IMPLEMENTED · M3c V1 · Solidity/Foundry. `core/src/economy/sims/amm/src/AMMSim.sol`
implements fee-adjusted constant-product swaps, exact fixed-point impermanent loss, nonlinear
slippage, IL-derived withdrawal thresholds, active LP rebalance, just-in-time liquidity economics,
deterministic backrun and sandwich populations, concentrated-liquidity position/range accounting,
two-pool optimal split routing, and all five bounded M3c prediction types. `AMMQuery.sol` is a
read-only EVM ABI bridge; `runner.tcl` calibrates from M2 `price_tick` + `dex_pool_state`,
evaluates the Solidity engine via `eth_call`, and publishes the result into the M3 hub for
Marketplace consumption. Dedicated Foundry CI verifies both native math and the M2→M3c→Hub
boundary on an ephemeral local Anvil instance. Mathematical foundations C5; implementation C3;
live-market parameterization remains data-dependent.

## 3. Language & location
**Solidity** + **Foundry** (forge, anvil) · `core/src/economy/sims/amm/`. Foundry is hosted
separately from the session container — not a session-start install. M3c's output enters the
system through Hub like every other sim, same `BoundedPrediction` schema, same M2 path.
On-chain-equivalent fixed-point arithmetic reproduces the exact invariant calculations DEXs
execute, eliminating precision-mismatch bugs between sim and production contracts.

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
  Example: `{ value: -0.034, lower_bound: -0.058, upper_bound: -0.012, confidence: 9.00,
  time_horizon: "7d", sim_type: "amm_liquidity" }` — projected impermanent loss for ETH/USDC pool.
  Example: `{ value: 0.082, lower_bound: 0.041, upper_bound: 0.127, confidence: 8.50,
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

## 6. Dependencies & runtime boundary
- M2 Data Feeds — normalized `dex_pool_state` supplies reserves, fee tier, volume, TVL and
  representative trade size; `price_tick` supplies external price, realized movement and
  volatility calibration.
- M3 Sims hub — every M3c result is converted to the common bounded-prediction schema and
  published as `amm_liquidity`; Traders read it through Marketplace.
- Foundry — hosted separately by design. CI uses a fresh local Anvil chain and deploys only the
  stateless/read-only `AMMQuery` bridge. M3c has no live-chain signer, broadcaster, approval,
  transfer, or swap-execution surface.

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

## 10. V1 decisions and future extensions
- **Concentrated liquidity:** V1 implements the canonical liquidity-to-token amount equations,
  one-sided out-of-range positions, and volatility/horizon-derived optimal ranges. Full
  Uniswap-v3-style initialized-tick crossing and fee-growth accounting are a future fidelity
  extension, not required by the V1 prediction contract.
- **Multi-pool routing:** V1 implements deterministic optimal exact-input splitting across two
  pools by marginal-output equalization. N-way routing is a future scaling extension.
- **Pool universe:** the engine is chain- and pair-agnostic. M2 chooses the concrete pools;
  the simulator does not hardcode ETH/USDC, stablecoins, or any particular chain.
- **Execution boundary:** arbitrage and sandwich functions are simulation constructs only.
  No native M3c API can submit a real swap.
