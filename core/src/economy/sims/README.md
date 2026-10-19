# M3 simulator family

Seven native simulator engines live here behind the Tcl M3 hub.

| ID | Engine | Native language | Implemented kernel |
|---|---|---|---|
| M3a | statistical | R | GBM, Merton jump diffusion, Heston, GARCH(1,1), Hurst estimate, regime state, bounded MC forecast |
| M3b | sociological | ECLiPSe Prolog | replicator dynamics, Hegselmann-Krause, complex contagion, pump/dump phase |
| M3c | AMM/liquidity | Solidity + Foundry | fee-adjusted x*y=k, impermanent loss, slippage, IL-derived withdrawal |
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

The Fortran engines are verified with `gfortran -std=f2018 -Wall -Wextra -Werror -pedantic`. R is installed by the repo SessionStart hook in remote sessions. ECLiPSe and Foundry remain separately hosted toolchains, matching the existing M3 design; their native test files are checked in next to their engines.

This directory contains simulators only. Nothing here broadcasts transactions or bypasses M1 Marketplace, M4 wallet brakes, or D1.
