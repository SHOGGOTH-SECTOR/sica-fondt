# M3e — Tokenomics & macro-state sims

## 1. Component
Macro-level token economy simulation: models **token supply dynamics, monetary policy (halvings,
burns, inflation), lending protocol dynamics, DeFi systemic risk, and stock-flow balances** using
stochastic differential equations (SDEs), state-space models, kinked interest rate curves, and
inter-protocol credit exposure networks. Pops here are **aggregate behavioral cohorts**
(miners/validators, holders, speculators, protocol treasuries, borrowers/lenders) whose collective
behavior drives token-level dynamics across **six concurrent time horizons** at tick-advanced, 90:1 (1s wall = 90s sim).

Grounded in Vienna complex-systems token modeling [7], ResearchGate engineering token economy
frameworks [6], Aave/Compound kinked interest rate models (industry standard), and DeXposure
inter-protocol credit propagation (Matzakos et al. 2025).

## 2. Status / certainty
IMPLEMENTED · M3e V1 · Fortran 2018. `core/src/economy/sims/tokenomics/`
implements conserved aggregate token state, Euler–Maruyama stochastic evolution, scalar Kalman
state estimation, discrete halving and burn policy flows, kinked lending curves, iterative
liquidation cascades, directional DeXposure propagation, VAR impulse responses, exact constrained
quadratic yield allocation, and all ten bounded prediction types. `tokenomics_query.f90` reads
normalized M2 `on_chain_event` history, rejects stock-flow violations, calibrates the aggregate
state natively, scores walk-forward innovation accuracy, and returns a bounded result to the Tcl
runner; `runner.tcl` publishes that result into M3 as `tokenomics_macro`. Strict gfortran CI
verifies the numerical kernel and the M2→Fortran→Hub boundary. Foundations C4/C5; implementation
C3; live-token parameterization remains data-driven.

## 3. Language & location
**Fortran 2018** (gfortran) · `src/economy/sims/tokenomics/`. Build: **fpm**. Dependencies:
**OpenBLAS** (LAPACK/BLAS via native Fortran interfaces). Hand-rolled: Box-Muller RNG, SDE
solvers, JSON I/O against fixed schemas. SDE solvers (Euler-Maruyama, Milstein), state-space
estimation, and VAR impulse responses are dense matrix-heavy loops where Fortran's array
intrinsics and zero-overhead numerics dominate; same language as M3d avoids a toolchain split
across the heaviest numerical sims.

## 4. Does / does-not
- **Does:** simulate token state dynamics via the SDE framework:
  $dX_t = f(X_t, u(X_t, t), t)dt + \sigma(X_t, t)dW_t$ where $X_t$ is the system state vector,
  $u$ is the behavioral policy function, deterministic drift captures programmatic parameters
  (halvings, burns), and Brownian motion $\sigma dW_t$ captures stochastic behavioral shocks;
  model stock-flow balances (circulating supply, staked, locked, burned); simulate monetary
  policy impacts (halving events, fee burns, treasury emissions); model **lending protocol
  dynamics** via kinked interest rate curves:
  $R = R_0 + R_{\text{slope1}} \times U$ if $U \leq U_{\text{opt}}$,
  $R = R_0 + R_{\text{slope1}} \times U_{\text{opt}} + R_{\text{slope2}} \times
  (U - U_{\text{opt}})$ if $U > U_{\text{opt}}$ where $U = \text{Borrowed}/(\text{Supplied} +
  \text{Borrowed})$, $U_{\text{opt}} \approx 0.8$ — cascade liquidations when
  $\text{collateral} \times \text{LTV} < \text{borrowed}$; model **DeFi systemic risk** via
  DeXposure inter-protocol credit propagation:
  $E_{ij}(t) = \sum_{\text{tokens}} [\text{TVL}_j(\text{token}) \times
  \text{ownership}_i(\text{token})]$ with VAR impulse responses for shock contagion across
  protocols sharing collateral; model **composable yield optimization**:
  $\max \sum_i w_i(t) \cdot \text{APY}_i(t) - \lambda \sum_i w_i(t)^2 \sigma_i^2(t)$
  subject to $\sum_i w_i = 1$ — dynamic rebalancing across lending, LP, and staking strategies;
  produce bounded predictions on token supply, protocol health, yield, and systemic risk.
- **Does-not:** model individual transactions (M3c/M3d); model social sentiment (M3b);
  model consensus mechanics (M3f); execute yield strategies (Traders/Marketplace do).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** SDE confidence bands, utilization rate ranges, contagion impact intervals.
- **Time-horizon mapping** (all run concurrently, tick-advanced, 90:1 (1s wall = 90s sim)):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Hourly | Lending rates, utilization, liquidation risk | Every block |
  | Daily | Yield optimization, protocol TVL flows | Hourly roll |
  | Weekly | SDE supply trajectory, stock-flow balances | Daily roll |
  | Monthly | DeXposure credit contagion, systemic risk | Weekly roll |
  | Annual | Halving/burn policy impacts, inflation trajectory | Monthly roll |
  | 5-year | Token supply long-run equilibrium, protocol lifecycle | Quarterly roll |
- Examples:
  `{ value: 2.1, lower_bound: 1.4, upper_bound: 3.2, confidence: 9.00,
  time_horizon: "90d", sim_type: "tokenomics_macro" }` — annualized inflation rate (%).
  `{ value: 0.67, lower_bound: 0.58, upper_bound: 0.74, confidence: 8.50,
  time_horizon: "30d", sim_type: "tokenomics_macro" }` — staking ratio.
  `{ value: 0.83, lower_bound: 0.78, upper_bound: 0.91, confidence: 8.80,
  time_horizon: "1h", sim_type: "tokenomics_macro" }` — Aave ETH utilization rate.
  `{ value: 0.12, lower_bound: 0.04, upper_bound: 0.25, confidence: 7.20,
  time_horizon: "7d", sim_type: "tokenomics_macro" }` — systemic contagion risk index.
- **Prediction types:** `supply_trajectory`, `inflation_rate`, `staking_ratio`,
  `velocity_estimate`, `halving_impact`, `treasury_runway`, `utilization_rate`,
  `liquidation_cascade_risk`, `systemic_contagion_index`, `optimal_yield_allocation`.
- Calibration: ingests `on_chain_event` (supply metrics, staking data, lending protocol state,
  TVL) from M2.

## 6. Dependencies & runtime boundary
- M2 Data Feeds — normalized `on_chain_event` supplies aggregate stock/flow state, lending
  balances, treasury state, policy parameters, directional exposure summary, and candidate
  yield APY/volatility observations.
- Native query runtime — `tokenomics_query.f90` consumes the complete ticker history and
  applies Kalman updates before prediction. Stock-flow conservation is checked for every row.
- M3 Sims hub — every M3e result is published in the common bounded schema as
  `tokenomics_macro`; Traders read it only through Marketplace.
- M3e has no wallet, signer, strategy-execution, transaction, or live-chain broadcast surface.

## 7. Invariants / laws
- **L1 (C5):** the SDE framework is the **canonical representation** — all token dynamics are
  expressed as drift + diffusion. Deterministic policy (halvings, burns) lives in the drift $f$;
  behavioral uncertainty lives in the diffusion $\sigma dW_t$.
- **L2 (C5):** **stock-flow conservation** — tokens are never created or destroyed outside the
  protocol's defined mechanisms. circulating + staked + locked + burned = total ever minted.
- **L3 (C5):** lending rate curves are **kinked at $U_{\text{opt}}$** — the steep slope above
  optimal utilization is a design invariant of Aave/Compound, not a parameter to smooth.
- **L4 (C4):** macro sims operate on **aggregate cohorts, not individuals** — the state vector
  $X_t$ tracks population-level quantities (total staked, total circulating), not per-wallet.
- **L5 (C4):** DeXposure contagion is **directional** — protocol A's exposure to protocol B
  is not symmetric. The exposure matrix $E_{ij}$ is not assumed symmetric.

## 8. Build steps
1. Implement Euler-Maruyama SDE solver for a simple token model (supply + staking).
2. Define the state vector $X_t$ and drift/diffusion functions for a reference token.
3. Add stock-flow accounting (verify conservation).
4. Implement kinked lending rate model (Aave-style) with liquidation cascade simulation.
5. Implement DeXposure credit propagation network with VAR impulse responses.
6. Implement composable yield optimizer (risk-adjusted return maximization).
7. Wire M2 on-chain data → state estimation / calibration.
8. Add monetary policy events (halving, burn) as drift discontinuities.

## 9. Tests
SDE: sample paths have correct mean (matches drift) and variance (matches diffusion). Stock-flow:
conservation holds across all time steps. Halving: supply growth rate drops at halving event.
Lending: rate curve exhibits kink at $U_{\text{opt}}$; liquidation cascades triggered when
collateral ratio breached. DeXposure: shock to protocol A propagates to protocol B through shared
collateral; isolated protocols unaffected. Yield: optimizer rebalances toward highest risk-adjusted
APY. Calibration: state estimate converges to observed data. Bounds: SDE confidence bands cover
realized paths on backtest. Speed: sim tick-advances at 90:1.

## 10. V1 decisions and future extensions
- **Token universe:** V1 is token-agnostic. M2 chooses the ticker and supplies its policy/state
  observations; M3e does not hardcode ETH, BTC, or any chain.
- **State vector:** V1 calibrates total minted, circulating, staked, locked, burned, supplied,
  borrowed, collateral, treasury, and velocity, with latest policy/network/yield parameters.
  Additional token-specific state can extend the observation schema later.
- **Behavioral policy:** V1 represents aggregate behavior through observed state drift/diffusion,
  staking/locking flows, utilization, treasury burn, yield candidates and exposure pressure.
  Cohort-specific structural policy functions are a future fidelity layer.
- **Multi-token interaction:** V1 operates one ticker per query. Correlated multi-token
  diffusions are a future cross-asset extension rather than a V1 dependency.
- **DeXposure granularity:** V1 accepts a directional aggregate exposure factor at the query
  boundary while the native engine retains full directional matrix and VAR kernels. Explicit
  protocol-graph ingestion can extend M2 without changing the M3 contract.
- **Lending curves:** the canonical kinked curve is V1. Morpho-style adaptive curves and other
  protocol-specific IRMs are optional later models.
