# M3 simulator family

Seven native simulator engines live here behind the Tcl M3 hub. **Native source presence is not
the same thing as runtime integration.** The current state is:

| ID | Engine | Native language | Native implementation | Tcl/M3 runtime bridge |
|---|---|---|---|---|
| M3a | statistical | R | V1 complete: GBM/Merton/Heston, CF calibration, GARCH, HMM/Viterbi, rough vol, DCC+t-copula, Bayesian+ARIMA, VaR/ES, 7 predictions | **wired + CI verified** |
| M3b | sociological | ECLiPSe Prolog | V1 complete: 5 archetypes, UCB/replicator, adaptive HK, contagion, HJB/FP MFG, pump/dump, 9 predictions | **wired + CI verified** |
| M3c | AMM/liquidity | Solidity + Foundry | V1 complete: x*y=k, concentrated positions, LP/JIT, backrun/sandwich, 2-pool routing, 5 predictions | **wired + CI verified** |
| M3d | MEV/adversarial | Fortran 2018 | PGA, block knapsack, cross-chain paths, sandwich scoring | **open** |
| M3e | tokenomics/macro | Fortran 2018 | V1 complete: conserved state, SDE, Kalman, policy, lending/cascade, VAR contagion, exact yield optimizer, 10 predictions | **wired + CI verified** |
| M3f | consensus/staking | ECLiPSe Prolog | honesty replicator, validator Markov transitions, incentive threshold, liveness | **open** |
| M3g | microstructure | Fortran 2018 | depth/slippage, spread, Almgren-Chriss schedule, arb decay, impact fit | **open** |

`registry.tcl` is the canonical engine inventory. `scheduler.tcl` is the live six-horizon
wall→sim clock. It starts at 90 simulated seconds per wall second for tick/hourly and accelerates
longer horizons according to the M3 spec. The clock does **not yet dispatch every native engine**:
M3a/M3b/M3c/M3e execute when their calibrated facade query is called; scheduler-driven automatic
refresh is still an M3 hub task.

Run all locally available native tests:

```sh
tclsh core/src/economy/sims/run_tests.tcl
```

Pass `--strict` when the environment is expected to contain every external runtime.

The Fortran engines are verified with `gfortran -std=f2018 -Wall -Wextra -Werror -pedantic`. M3a has a dedicated GitHub Actions R job that runs both the native statistical suite and the `M2 price_tick → R → M3 hub` Tcl integration suite. R is installed by the repo SessionStart hook in remote sessions. ECLiPSe and Foundry remain separately hosted toolchains, matching the existing M3 design. M3c has a dedicated Foundry workflow that runs the native Solidity suite and a Tcl boundary test against a stateless query contract on an ephemeral local Anvil instance; M3b has a dedicated ECLiPSe workflow covering the native sociological suite plus persistent M2→M3b→Hub population evolution and walk-forward correctness. M3e has a dedicated strict-Fortran workflow that compiles both the numerical test binary and native query executable, then verifies the M2 on-chain-event → Fortran → M3 hub boundary.

This directory contains simulators only. Nothing here broadcasts transactions or bypasses M1 Marketplace, M4 wallet brakes, or D1.
