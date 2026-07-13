# M3f — Consensus & staking game sims

## 1. Component
Consensus-layer simulation: models **Proof-of-Stake validation dynamics, staking pool game theory,
and Byzantine fault tolerance** using evolutionary games and Markov chains. Pops here are
**validators and staking pool operators** whose honesty is a dynamic, evolving strategy under
financial incentives. Grounded in Cornell evolutionary consensus [8,9], ACM staking pool risk
theorems [10], and Monash dynamic PBFT modeling [11].

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Evolutionary PoS game theory C4 (Cornell [8]); staking pool Nash
equilibrium proofs C4 (ACM [10]); Markov chain throughput models C4 (Monash [11]); MFG for
validator populations C4 (Lasry & Lions 2007; validator-specific application C3);
simulation parameterization C1.

## 3. Language & location
TBD · `src/economy/sims/consensus/`. Needs Markov chain solvers and game-theoretic equilibrium
computation. Python, Julia, or R.

## 4. Does / does-not
- **Does:** simulate validator populations where honesty evolves via **evolutionary game theory**
  under bounded rationality [8]; model staking pool delegation as a game with proven reward-
  parameter thresholds enforcing subgame-perfect Nash equilibria favoring honest validation over
  malicious slashing [10]; simulate **throughput stability under shifting validator states** via
  Markov chains [11]; solve **Mean-Field Game equilibria for large validator populations** —
  coupled HJB (individual validator optimization) + Fokker-Planck (population density):
  $-\partial_t u + H(x, \nabla u) = F(x, m)$, $\partial_t m - \nabla \cdot (m \nabla_p H) = 0$
  — captures emergent staking coordination without enumerating every validator; predict slashing
  risk, validator set stability, and staking yield across **six concurrent time horizons** at
  tick-advanced, ≥ 360:1 (1s wall = 1h sim); produce bounded predictions on consensus health and staking returns.
- **Does-not:** validate blocks (this is a simulator); model AMM pools (M3c); model token supply
  (M3e — but consumes staking ratio from M3e as input).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** equilibrium stability ranges and yield intervals.
  Example: `{ value: 0.89, lower_bound: 0.82, upper_bound: 0.94, confidence: 0.88,
  time_horizon: "7d", sim_type: "consensus_staking" }` — fraction of validators honest in
  equilibrium.
  Example: `{ value: 4.2, lower_bound: 3.6, upper_bound: 5.1, confidence: 0.82,
  time_horizon: "30d", sim_type: "consensus_staking" }` — annualized staking yield (%).
- **Time-horizon mapping** (all run concurrently, tick-advanced, ≥ 360:1 (1s wall = 1h sim)):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Hourly | Markov chain validator state transitions | Every epoch |
  | Daily | Replicator dynamics strategy shifts, slashing events | Hourly roll |
  | Weekly | Staking pool Nash equilibrium recalculation | Daily roll |
  | Monthly | MFG equilibrium for validator population | Weekly roll |
  | Annual | Evolutionary stable strategies, yield trajectory | Monthly roll |
  | 5-year | Consensus mechanism structural evolution | Quarterly roll |
- **Prediction types:** `validator_honesty_fraction`, `slashing_probability`, `staking_yield`,
  `pool_delegation_equilibrium`, `throughput_stability`, `consensus_liveness`,
  `mfg_validator_equilibrium`.
- Calibration: ingests `on_chain_event` (validator set changes, slashing events) from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — validator/staking on-chain data; *stub:* canned validator snapshots.
- M3e Tokenomics — staking ratio as macro input; *stub:* fixed ratio.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C4):** validator honesty is a **dynamic equilibrium, not a fixed parameter** — it evolves
  via replicator dynamics as payoffs change. The sim must not assume fixed honesty rates.
- **L2 (C4):** the staking pool reward threshold is **mathematically derived** — the sim must
  reproduce the subgame-perfect Nash equilibrium from the ACM proofs [10], not use ad-hoc
  thresholds.
- **L3 (C4):** throughput is modeled as a **Markov chain** over validator states (active, pending,
  slashed, exited) — transitions are stochastic with rates calibrated from on-chain data [11].

## 8. Build steps
1. Implement the evolutionary honesty game (replicator dynamics, bounded rationality).
2. Implement the Markov chain validator-state model.
3. Reproduce the staking pool Nash equilibrium reward threshold from [10].
4. Implement MFG solver (HJB + Fokker-Planck) for large validator populations.
5. Wire M2 validator data → calibration of transition rates.
6. Wire M3e staking ratio input.

## 9. Tests
Equilibrium: honesty fraction converges to Nash equilibrium under stable payoffs. Markov:
stationary distribution matches expected validator state proportions. Threshold: pool delegation
equilibrium matches the ACM proof for test parameters. Bounds: all outputs bounded. Liveness:
throughput degrades when honest fraction drops below threshold.

## 10. Open items
- Which PoS protocol to model initially (Ethereum? a specific L2?).
- Bounded rationality implementation (noisy best-response? epsilon-greedy? logit?).
- Slashing severity parameterization.
- Cross-sim: does consensus instability feed into M3b sociological panic signals?
