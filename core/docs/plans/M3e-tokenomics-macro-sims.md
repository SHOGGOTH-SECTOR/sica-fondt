# M3e — Tokenomics & macro-state sims

## 1. Component
Macro-level token economy simulation: models **token supply dynamics, monetary policy (halvings,
burns, inflation), and systemic stock-flow balances** using stochastic differential equations
(SDEs) and state-space models. Pops here are **aggregate behavioral cohorts** (miners/validators,
holders, speculators, protocol treasuries) whose collective behavior drives token-level dynamics.
Grounded in the Vienna University complex-systems token modeling [7] and ResearchGate engineering
token economy frameworks [6].

## 2. Status / certainty
DESIGN-FIRST · ABSENT. SDE state-space framework C4 (Vienna [7]); stock-flow modeling C4
(ResearchGate [6]); specific token model parameters C1.

## 3. Language & location
TBD · `src/economy/sims/tokenomics/`. Needs SDE solvers (Euler-Maruyama, Milstein) and
state-space estimation. Julia (DifferentialEquations.jl), Python (scipy), or Octave.

## 4. Does / does-not
- **Does:** simulate token state dynamics via the SDE framework:
  $dX_t = f(X_t, u(X_t, t), t)dt + \sigma(X_t, t)dW_t$ where $X_t$ is the system state vector,
  $u$ is the behavioral policy function, deterministic drift captures programmatic parameters
  (halvings, burns), and Brownian motion $\sigma dW_t$ captures stochastic behavioral shocks;
  model stock-flow balances (circulating supply, staked, locked, burned); simulate monetary
  policy impacts (halving events, fee burns, treasury emissions); produce bounded predictions
  on token supply trajectories, inflation rates, and velocity.
- **Does-not:** model individual transactions (M3c/M3d); model social sentiment (M3b);
  model consensus mechanics (M3f).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** SDE confidence bands (derived from the stochastic component $\sigma dW_t$).
  Example: `{ value: 2.1, lower_bound: 1.4, upper_bound: 3.2, confidence: 0.90,
  time_horizon: "90d", sim_type: "tokenomics_macro" }` — annualized inflation rate (%).
  Example: `{ value: 0.67, lower_bound: 0.58, upper_bound: 0.74, confidence: 0.85,
  time_horizon: "30d", sim_type: "tokenomics_macro" }` — staking ratio (fraction of supply).
- **Prediction types:** `supply_trajectory`, `inflation_rate`, `staking_ratio`,
  `velocity_estimate`, `halving_impact`, `treasury_runway`.
- Calibration: ingests `on_chain_event` (supply metrics, staking data) from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — on-chain supply/staking data; *stub:* canned supply snapshots.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C4):** the SDE framework is the **canonical representation** — all token dynamics are
  expressed as drift + diffusion. Deterministic policy (halvings, burns) lives in the drift $f$;
  behavioral uncertainty lives in the diffusion $\sigma dW_t$.
- **L2 (C4):** **stock-flow conservation** — tokens are never created or destroyed outside the
  protocol's defined mechanisms. The sim must balance: circulating + staked + locked + burned =
  total ever minted.
- **L3 (C3):** macro sims operate on **aggregate cohorts, not individuals** — the state vector
  $X_t$ tracks population-level quantities (total staked, total circulating), not per-wallet.

## 8. Build steps
1. Implement Euler-Maruyama SDE solver for a simple token model (supply + staking).
2. Define the state vector $X_t$ and drift/diffusion functions for a reference token.
3. Add stock-flow accounting (verify conservation).
4. Wire M2 on-chain data → state estimation / calibration.
5. Add monetary policy events (halving, burn) as drift discontinuities.

## 9. Tests
SDE: sample paths have correct mean (matches drift) and variance (matches diffusion). Stock-flow:
conservation holds across all time steps. Halving: supply growth rate drops at halving event.
Calibration: state estimate converges to observed data. Bounds: SDE confidence bands correctly
cover realized paths on backtest.

## 10. Open items
- Which tokens to model initially (ETH? BTC? a specific alt?).
- State vector dimensionality (how many state variables per token model?).
- Behavioral policy function $u(X_t, t)$ — how to parameterize aggregate cohort behavior.
- Multi-token interactions (correlated diffusions across tokens?).
