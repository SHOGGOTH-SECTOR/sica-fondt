# M3e — tokenomics & macro-state simulator

M3e V1 is the Fortran-native macro simulator behind the stomach's `tokenomics_macro` prediction type.

Implemented kernels include conserved token stock/flow state, Euler–Maruyama SDE evolution, scalar Kalman state estimation, discrete halving and burn policy, kinked lending rates, iterative liquidation cascades, directional exposure propagation, VAR impulse response, exact constrained quadratic yield allocation, and liquidation shortfall.

The live boundary is:

`M2 on_chain_event → TokenomicsRunner (Tcl) → tokenomics_query.f90 → SimsHub → Marketplace`

Each query consumes the complete normalized history for one ticker. The native executable rejects stock-flow violations, calibrates aggregate state through sequential Kalman updates, derives confidence/correctness/certainty from evidence quality and walk-forward innovation error, computes the requested bounded prediction, and returns it to Tcl for hub publication.

The ten public prediction types are `supply_trajectory`, `inflation_rate`, `staking_ratio`, `velocity_estimate`, `halving_impact`, `treasury_runway`, `utilization_rate`, `liquidation_cascade_risk`, `systemic_contagion_index`, and `optimal_yield_allocation`.

The `optimal_yield_allocation` scalar is the largest portfolio weight; the full three-weight allocation is retained as prediction metadata. All hub-facing outputs remain numeric and bounded.

M3e models aggregate token/protocol state only. It does not hold keys, sign messages, submit swaps, rebalance capital, or broadcast transactions.

Verification is performed by dedicated CI with strict Fortran flags:

```sh
gfortran -std=f2018 -Wall -Wextra -Werror -pedantic
```

The job compiles the native kernel tests and query executable, requires `TOKENOMICS TESTS PASSED`, and enforces `4 passed / 0 failed` at the M2→M3e→Hub boundary.
