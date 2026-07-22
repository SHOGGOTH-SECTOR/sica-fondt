# M3b — Sociological & population dynamics sims

## 1. Component
Sociological simulation: **evolutionary game theory, bounded rationality, opinion dynamics,
complex contagion, adaptive learning populations, and Mean-Field Game equilibria** among market
participants. Pops here are **behavioral archetypes** — retail herd followers, contrarian whales,
MEV searchers, passive LPs, pump-and-dump manipulators — whose strategies evolve under selection
pressure across **six concurrent time horizons**. Grounded in evolutionary consensus game models
[8,9], Hegselmann-Krause opinion dynamics (2002), complex contagion theory (Centola & Macy 2007),
MFG theory (Lasry & Lions 2007), and crypto manipulation ABMs.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Evolutionary game theory C4 (Cornell [8]). Hegselmann-Krause bounded
confidence C5 (established 2002). Complex contagion C4 (Centola & Macy 2007; crypto applications
C3). Bandit-replicator hybrid C3 (emerging). Mean-Field Games C4 (Lasry & Lions 2007; tensor-train
solvers C3). Crypto pump-and-dump ABM C3 (3-agent protocol validated on historical data).
Pop behavioral models C1.

## 3. Language & location
**ECLiPSe Prolog 7.2** · `src/economy/sims/sociological/`. Libraries: **ic** (interval
constraints — bounds propagation for BoundedPrediction ranges), **eplex** (LP/MIP via COIN-OR
CLP/CBC — Nash equilibrium computation). Game-theoretic equilibria, replicator dynamics, and
strategy evolution are naturally expressed as logical relations over population states; Nash
equilibrium search is constraint satisfaction. Needs efficient population iteration, strategy
mutation, PDE solvers for MFG (HJB + Fokker-Planck), and bandit algorithms (UCB/Thompson).

## 4. Does / does-not
- **Does:** simulate populations of behavioral archetypes competing in a market; apply
  **replicator dynamics** $dx_i/dt = x_i(\pi_i(x) - \bar{\pi}(x))$ to strategy distributions;
  model **opinion clustering** via Hegselmann-Krause bounded confidence:
  $x_i(t+1) = x_i(t) + \mu(x_j(t) - x_i(t))$ for $|x_i - x_j| \leq d$ — agents only update
  toward neighbors within confidence bound $d$, creating natural clustering and trend-reversal
  thresholds; model **complex contagion** with heterogeneous thresholds: adoption probability
  $P_i = f(n_i / k_i)$ where multiple exposures amplify adoption non-linearly (captures meme-coin
  rallies and narrative-driven pumps); implement **bandit-replicator hybrid** where pops use
  UCB or Thompson Sampling to estimate strategy payoffs:
  $x_i'(t) = x_i(t)[\lambda_i(t) - \bar{\lambda}(t)]$ with $\lambda_i = \text{UCB}(\theta_i)$
  — bridges replicator dynamics with multi-armed bandit learning; solve **Mean-Field Game
  equilibria** via coupled HJB + Fokker-Planck PDEs for large-population limits:
  $-\partial_t u + H(x, \nabla u) = F(x, m)$ (HJB, individual optimization),
  $\partial_t m - \nabla \cdot (m \nabla_p H) = 0$ (Fokker-Planck, population density) — Newton
  iteration with tensor-train decomposition reduces $O(N^d)$ to $O(dNr^2)$ for high-dimensional
  state spaces; simulate **crypto pump-and-dump protocol** with 3 pop types: Normal traders,
  Market Analysts (MA, information-advantaged), Market Players (MP, manipulators) in a 4-phase
  cycle (accumulation → promotion → distribution → collapse); model sentiment cascades
  (fear/greed contagion across pop clusters); model bounded rationality (pops satisfice, not
  optimize — heuristics, not perfect strategies); produce bounded predictions across all six
  time horizons.
- **Does-not:** model protocol mechanics (M3c–M3f); compute statistical forecasts (M3a);
  represent real individuals (pops are archetypes, not profiles).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** population-fraction ranges, sentiment scales, MFG equilibrium stability.
- **Time-horizon mapping** (all run concurrently):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Hourly | Hegselmann-Krause opinion clusters, bandit-replicator | Every data tick |
  | Daily | Complex contagion cascades, pump-and-dump phase detection | Hourly roll |
  | Weekly | Replicator dynamics strategy evolution, MFG equilibrium | Daily roll |
  | Monthly | Population archetype composition, narrative regime shifts | Weekly roll |
  | Annual | Long-run evolutionary stable strategies (ESS) | Monthly roll |
  | 5-year | MFG stationary equilibria, structural population shifts | Quarterly roll |
- Examples:
  `{ value: 7.3, lower_bound: 5.0, upper_bound: 9.1, confidence: 6.80,
  time_horizon: "12h", sim_type: "sociological" }` — herd-panic index (0–10).
  `{ value: 0.42, lower_bound: 0.31, upper_bound: 0.55, confidence: 7.20,
  time_horizon: "1w", sim_type: "sociological" }` — fraction of pops in "contrarian" strategy.
  `{ value: "promotion", lower_bound: null, upper_bound: null, confidence: 6.10,
  time_horizon: "current", sim_type: "sociological" }` — pump-and-dump phase detection.
  `{ value: 0.78, lower_bound: 0.65, upper_bound: 0.88, confidence: 7.00,
  time_horizon: "30d", sim_type: "sociological" }` — MFG equilibrium stability index.
  Models span multiple horizons — e.g. replicator dynamics runs hourly through annual; MFG
  produces weekly equilibria and 5-year stationary states. The table shows primary assignments.
- **Prediction types:** `sentiment_index`, `herd_threshold`, `strategy_distribution`,
  `cascade_probability`, `coordination_stability`, `opinion_cluster_count`,
  `pump_dump_phase`, `mfg_equilibrium_stability`, `narrative_regime`.
- Calibration: ingests `rss_news` (sentiment signal) and `price_tick` (realized behavior) from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — sentiment and price data for calibration; *stub:* canned sentiment series.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C5):** pops are **archetypal individuals, not literal living persons** — no attempt to model or track real
  market participants. The sim models emergent behavior from abstracted populations.
- **L2 (C5):** strategies **evolve** — the population distribution shifts over time via
  replicator dynamics. No fixed strategy ratios.
- **L3 (C4):** rationality is ***NOT*** the **default** — pops satisfice with heuristics, not
  optimize with perfect information. Rational-agent models are an **abnormal** case, not the baseline.
- **L4 (C4):** **complex contagion requires multiple exposures** — adoption is non-linear in
  neighbor count, not simple diffusion. Single-exposure models undercount threshold effects.
- **L5 (C4):** the MFG limit is **valid only for large populations** — below ~100 pops, use
  discrete replicator dynamics; above, the continuum HJB+FP approximation applies.
- **L6 (C3):** pump-and-dump detection is **phase-based** — the 4-phase cycle (accumulate →
  promote → distribute → collapse) has distinct statistical signatures in volume and price.

## 8. Build steps
0. Get ECLiPSe tool chain installed and operational.
1. Define pop archetypes and their various strategies.
2. Implement replicator dynamics (strategy evolution over generations).
3. Implement Hegselmann-Krause bounded confidence opinion model.
4. Implement complex contagion with heterogeneous thresholds.
5. Implement bandit-replicator hybrid (UCB payoff estimation + replicator selection).
6. Implement MFG solver (HJB + Fokker-Planck with Newton iteration).
7. Implement pump-and-dump 3-type ABM (Normal, MA, MP) with 4-phase protocol.
8. Wire M2 news/price data → calibration of pop parameters.
9. Implement multi-horizon `BoundedPrediction` outputs.

## 9. Tests
Evolution: dominant strategy shifts when payoff landscape changes. Cascade: sentiment shock
propagates through pop network above threshold, not below. Bounded confidence: opinion clusters
form at predicted cluster count for given $d$. Complex contagion: multiple-exposure requirement
produces slower but more robust adoption than simple contagion. Bandit: explore-exploit tradeoff
produces adapting populations. MFG: equilibrium converges for large N; matches discrete sim for
small N. Pump-dump: 4-phase cycle detected on synthetic manipulation data. Bounds: all outputs
include upper/lower.

## 10. Open items
- Pop archetype catalog (which behavioral types? how many?).
- Network topology for sentiment contagion (small-world? scale-free?).
- Calibration from real market data — how to infer pop distribution from observable price action. >>>We actually use blogs, reddit, and social networks to infer pops<<<
- MFG tensor-train rank $r$ (>>>accuracy<<< vs. compute tradeoff).
- Hegselmann-Krause confidence bound $d$ — fixed or >>>adaptive<<<?
- Cross-sim interaction: do sociological predictions feed into M3c (AMM) or M3d (MEV)? [conditional on prediction accuracy over time]
