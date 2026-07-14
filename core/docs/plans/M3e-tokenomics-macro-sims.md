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
DESIGN-FIRST · ABSENT. SDE state-space framework C4 (Vienna [7]); stock-flow modeling C4
(ResearchGate [6]); kinked interest rate model C5 (Aave/Compound production standard);
DeXposure inter-protocol credit propagation C3 (emerging, 2025 — high DeFi specificity);
composable yield optimization C4 (Yearn v3, Beefy, production-validated). Specific parameters C1.

## 3. Language & location
TBD · `src/economy/sims/tokenomics/`. Needs SDE solvers (Euler-Maruyama, Milstein),
state-space estimation, and VAR (vector autoregression) for credit exposure impulse responses.
Julia (DifferentialEquations.jl) or Octave.

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

## 6. Dependencies & stubs
- M2 Data Feeds — on-chain supply/staking/lending data; *stub:* canned supply snapshots.
- M3 Sims hub — lifecycle management; *stub:* manual init.

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

## 10. Open items
- Which tokens to model initially (ETH? BTC? a specific alt?).
- State vector dimensionality (how many state variables per token model?).
- Behavioral policy function $u(X_t, t)$ — how to parameterize aggregate cohort behavior.
- Multi-token interactions (correlated diffusions across tokens?).
- DeXposure graph granularity (how many protocols? top-10 by TVL?).
- Lending model extensions (Morpho AdaptiveCurveIRM? variable kink parameters?).
