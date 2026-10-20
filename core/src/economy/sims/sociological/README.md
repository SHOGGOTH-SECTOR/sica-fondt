# M3b — sociological simulator

M3b V1 is the ECLiPSe-Prolog population simulator behind the stomach's `sociological` prediction type.

V1 contains five abstract archetypes: retail herd, contrarian whale, MEV searcher, passive LP, and manipulator. It implements replicator dynamics, UCB bandit-replicator adaptation, adaptive Hegselmann–Krause bounded confidence, heterogeneous complex contagion, a one-dimensional HJB/Fokker–Planck mean-field equilibrium with damped Newton iteration, bounded-rationality pump/dump dynamics, opinion clustering, and nine public prediction types.

The live boundary is:

`M2 rss_news + price_tick → SociologicalRunner (Tcl) → ECLiPSe → SimsHub → Marketplace`

Population state persists per ticker. Each query advances that state through ECLiPSe's native bandit-replicator relation before the requested prediction is evaluated. MFG stability is also computed by ECLiPSe, not reimplemented in Tcl.

`correctness` is empirical: confidence/engagement-weighted social direction is compared walk-forward against the next realized price move. It is therefore usable as evidence for later cross-sim gating rather than as a source-count heuristic.

The nine prediction types are `sentiment_index`, `herd_threshold`, `strategy_distribution`, `cascade_probability`, `coordination_stability`, `opinion_cluster_count`, `pump_dump_phase`, `mfg_equilibrium_stability`, and `narrative_regime`.

No pop represents a literal person. M3b has no trading, signing, broadcasting, or transaction surface.

Verification:

```sh
eclipse -b core/src/economy/sims/sociological/test.ecl -e run_tests
tclsh core/src/economy/sims/sociological/integration.test
```

Dedicated CI enforces the native ECLiPSe suite and `6 passed / 0 failed` at the M2→M3b→Hub boundary.
