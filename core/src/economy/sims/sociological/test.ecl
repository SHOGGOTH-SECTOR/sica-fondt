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
         N=[A,B], approx(A+B,1.0,1.0e-9), B > 0.5)),

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
         approx(N1+N2,1.0,1.0e-9))),

    writeln("SOCIOLOGICAL TESTS PASSED").
