:- [engine].

approx(A, B, Eps) :- Diff is abs(A-B), Diff =< Eps.

must(Name, Goal) :-
    ( call(Goal) ->
        true
    ;
        printf(error, "FAILED: %w%n", [Name]),
        fail
    ).

run_tests :-
    must(replicator_normalizes,
        (replicator_step([0.5,0.5],[1.0,2.0],0.2,N),
         N=[A,B], Sum is A+B, approx(Sum,1.0,1.0e-9), B > 0.5)),

    must(hk_clusters_local_neighbors,
        (hk_step([0.0,0.1,0.9,1.0],0.2,1.0,H),
         H=[H1,H2,H3,H4],
         approx(H1,0.05,1.0e-9),
         approx(H2,0.05,1.0e-9),
         approx(H3,0.95,1.0e-9),
         approx(H4,0.95,1.0e-9))),

    must(complex_contagion_needs_threshold,
        (complex_contagion([1,3],[4,4],[0.5,0.5],Ad),
         Ad=[0,1])),

    must(complex_contagion_requires_multiple_exposures,
        (complex_contagion([1,2,3],[1,2,4],[0.1,0.5,0.75],Multi),
         Multi=[0,1,1])),

    must(pump_phase_promotion,
        pump_phase(0.10,2.5,0.8,promotion)),

    must(archetype_catalog_v1,
        archetype_catalog([
            retail_herd,
            contrarian_whale,
            mev_searcher,
            passive_lp,
            manipulator
        ])),

    must(ucb_rewards_exploration,
        (ucb_score(0.2,10,100,0.7,S1),
         ucb_score(0.8,10,100,0.7,S2),
         S2 > S1)),

    must(bandit_replicator_adapts,
        (bandit_replicator_step(
            [0.5,0.5],
            [2.0,9.0],
            [10,10],
            20,
            0.6,
            0.25,
            Next,
            Scores
         ),
         Next=[N1,N2],
         Scores=[U1,U2],
         U2 > U1,
         N2 > N1,
         SumN is N1+N2,
         approx(SumN,1.0,1.0e-9))),


    must(mfg_population_guard,
        (not(mfg_valid_population(99)),
         mfg_valid_population(100),
         mfg_valid_population(1000))),

    must(mfg_equilibrium_normalized_and_stable,
        (mfg_equilibrium(
            250,
            [0.10,0.20,0.40,0.20,0.10],
            0.12,
            0.08,
            0.35,
            80,
            Density,
            Value,
            Stability,
            Residual
         ),
         Density=[D1,D2,D3,D4,D5],
         SumD is D1+D2+D3+D4+D5,
         approx(SumD,1.0,1.0e-6),
         D1 >= 0.0, D2 >= 0.0, D3 >= 0.0, D4 >= 0.0, D5 >= 0.0,
         length(Value,5),
         Stability >= 0.0, Stability =< 1.0,
         Residual >= 0.0, Residual < 0.25)),


    must(pump_abm_promotion_selects_manipulators,
        (pump_abm_step(
            [0.80,0.10,0.10],
            0.10,3.0,0.85,0.25,
            Promotion,promotion
         ),
         Promotion=[_,_,PromoMP],
         PromoMP > 0.10)),

    must(pump_abm_collapse_selects_against_manipulators,
        (pump_abm_step(
            [0.70,0.15,0.15],
            -0.12,3.2,0.20,0.25,
            Collapse,collapse
         ),
         Collapse=[_,_,CollapseMP],
         CollapseMP < 0.15)),

    writeln("SOCIOLOGICAL TESTS PASSED").
