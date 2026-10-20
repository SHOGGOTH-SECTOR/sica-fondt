# M3 simulator family

Seven native simulator engines live here behind the Tcl M3 hub.

| ID | Engine | Native language | Implemented kernel |
|---|---|---|---|
| M3a | statistical | R | V1 complete: GBM/Merton/Heston, CF option calibration, GARCH, HMM/Viterbi, fitted rough vol, DCC+t-copula, Bayesian+ARIMA, VaR/ES, empirical scoring, 7 typed predictions, price+DEX-pool calibration |
| M3b | sociological | ECLiPSe Prolog | replicator dynamics, Hegselmann-Krause, complex contagion, pump/dump phase |
| M3c | AMM/liquidity | Solidity + Foundry | V1 complete: x*y=k, IL/slippage, concentrated positions, LP/JIT strategies, backrun/sandwich pops, two-pool routing, 5 bounded predictions, price+pool calibration |
| M3d | MEV/adversarial | Fortran 2018 | all-pay PGA, block knapsack, cross-chain path comparison, sandwich score |
| M3e | tokenomics/macro | Fortran 2018 | Euler-Maruyama, stock-flow conservation, kinked lending, directional contagion, yield weights |
| M3f | consensus/staking | ECLiPSe Prolog | honesty replicator, validator Markov transitions, incentive threshold, liveness |
| M3g | microstructure | Fortran 2018 | depth/slippage, spread, Almgren-Chriss schedule, arb decay, impact fit |

`registry.tcl` is the canonical engine inventory. `scheduler.tcl` is the live six-horizon wall→sim clock. It starts at 90 simulated seconds per wall second for tick/hourly and accelerates the longer horizons according to the M3 spec.

Run all locally available native tests:

```sh
tclsh core/src/economy/sims/run_tests.tcl
```

Pass `--strict` when the environment is expected to contain every external runtime.

The Fortran engines are verified with `gfortran -std=f2018 -Wall -Wextra -Werror -pedantic`. M3a has a dedicated GitHub Actions R job that runs both the native statistical suite and the `M2 price_tick → R → M3 hub` Tcl integration suite. R is installed by the repo SessionStart hook in remote sessions. ECLiPSe and Foundry remain separately hosted toolchains, matching the existing M3 design. M3c has a dedicated Foundry workflow that runs the native Solidity suite and a Tcl boundary test against a stateless query contract on an ephemeral local Anvil instance; ECLiPSe native test files remain checked in next to their engines.

This directory contains simulators only. Nothing here broadcasts transactions or bypasses M1 Marketplace, M4 wallet brakes, or D1.
