# M3c — AMM & liquidity simulator

M3c V1 is the Solidity-native AMM simulator behind the stomach's `amm_liquidity` prediction type.

Implemented mechanics: fee-adjusted constant-product swaps; exact fixed-point impermanent loss; nonlinear slippage; IL-derived withdrawal thresholds; active LP rebalance; just-in-time liquidity fee economics; deterministic backrun and sandwich simulation; concentrated-liquidity position amounts and volatility/horizon range forecasts; deterministic exact-input splitting across two pools.

The five public prediction types are `impermanent_loss`, `pool_return`, `optimal_range`, `slippage_estimate`, and `lp_withdrawal_threshold`. Every publication remains a numeric `BoundedPrediction` with explicit lower/value/upper bounds.

Calibration consumes normalized M2 `dex_pool_state` and `price_tick` histories. Source confidence sets the uncertainty width; recent literal pool-state history supplies a retrospective correctness score.

The live simulation boundary is:

`M2 → AMMRunner (Tcl) → AMMQuery (read-only eth_call) → AMMSim → SimsHub → Marketplace`

`AMMQuery.sol` is stateless and exposes only pure query methods. It has no transfer, approval, swap, signer, broadcaster, or privileged function. CI deploys it only to a fresh ephemeral local Anvil instance.

V1 concentrated liquidity covers position/range accounting, not full initialized-tick traversal. V1 multi-pool routing optimizes across two pools; N-way routing is a scaling extension.

Verification:

```sh
cd core/src/economy/sims/amm
forge test -vv
tclsh integration.test
```

The dedicated M3c workflow enforces both the native Foundry suite and the Tcl M2→M3c→Hub summary.
