# M3b — Sociological & population dynamics sims

## 1. Component
Sociological simulation: **evolutionary game theory, bounded rationality, sentiment cascades, and
population dynamics** among market participants. Pops here are **behavioral archetypes** — retail
herd followers, contrarian whales, MEV searchers, passive LPs — whose strategies evolve under
selection pressure. Grounded in evolutionary consensus game models [8,9] and bounded-rationality
coordination frameworks.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Evolutionary game-theory foundations C4 (Cornell blockchain cooperation
literature [8]); pop behavioral models C1.

## 3. Language & location
TBD · `src/economy/sims/sociological/`. Agent-based modeling frameworks (Mesa/Python, NetLogo,
or custom). Needs efficient population iteration and strategy mutation.

## 4. Does / does-not
- **Does:** simulate populations of behavioral archetypes competing in a market; apply
  evolutionary dynamics (replicator equation, mutation, selection) to strategy distributions;
  model sentiment cascades (fear/greed contagion across pop clusters); model bounded rationality
  (pops satisfice, not optimize — they follow heuristics, not perfect strategies); produce
  bounded predictions on market sentiment, herd behavior thresholds, and coordination breakdowns.
- **Does-not:** model protocol mechanics (M3c–M3f); compute statistical forecasts (M3a);
  represent real individuals (pops are archetypes, not profiles).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** population-fraction ranges and sentiment scales.
  Example: `{ value: 7.3, lower_bound: 5.0, upper_bound: 9.1, confidence: 0.68,
  time_horizon: "12h", sim_type: "sociological" }` — herd-panic index on a 0–10 scale.
  Example: `{ value: 0.42, lower_bound: 0.31, upper_bound: 0.55, confidence: 0.72,
  time_horizon: "1w", sim_type: "sociological" }` — fraction of pops in "contrarian" strategy.
- **Prediction types:** `sentiment_index`, `herd_threshold`, `strategy_distribution`,
  `cascade_probability`, `coordination_stability`.
- Calibration: ingests `rss_news` (sentiment signal) and `price_tick` (realized behavior) from M2.

## 6. Dependencies & stubs
- M2 Data Feeds — sentiment and price data for calibration; *stub:* canned sentiment series.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C4):** pops are **archetypes, not individuals** — no attempt to model or track real
  market participants. The sim models emergent behavior from strategy populations.
- **L2 (C4):** strategies **evolve** — the population distribution shifts over time via
  replicator dynamics. No fixed strategy ratios.
- **L3 (C3):** bounded rationality is the **default** — pops satisfice with heuristics, not
  optimize with perfect information. Rational-agent models are a special case, not the baseline.

## 8. Build steps
1. Define pop archetypes and their heuristic strategies.
2. Implement replicator dynamics (strategy evolution over generations).
3. Implement sentiment contagion model (network-based cascade).
4. Wire M2 news/price data → calibration of pop parameters.
5. Implement `BoundedPrediction` output with population-fraction CIs.

## 9. Tests
Evolution: dominant strategy shifts when payoff landscape changes. Cascade: sentiment shock
propagates through pop network above threshold, not below. Bounded rationality: satisficing pop
underperforms optimizer in simple games but outperforms in noisy environments. Bounds: all
outputs include upper/lower.

## 10. Open items
- Pop archetype catalog (which behavioral types? how many?).
- Network topology for sentiment contagion (small-world? scale-free?).
- Calibration from real market data — how to infer pop distribution from observable price action.
- Cross-sim interaction: do sociological predictions feed into M3c (AMM) or M3d (MEV)?
