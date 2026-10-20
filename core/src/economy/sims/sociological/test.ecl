:- [engine].

approx(A, B, Eps) :- Diff is abs(A-B), Diff =< Eps.

must(Name, Goal) :-
    ( call(Goal) ->
        true
    ;
        printf(error, "FAILED: %w%n", [Name]),
        fail
    ).

prediction_types([
    sentiment_index,
    herd_threshold,
    strategy_distribution,
    cascade_probability,
    coordination_stability,
    opinion_cluster_count,
    pump_dump_phase,
    mfg_equilibrium_stability,
    narrative_regime
]).

check_prediction_types([], _, _).
check_prediction_types([Type|Types], State, Horizon) :-
    sociological_prediction(Type,State,Horizon,V,L,U,_),
    number(V), number(L), number(U),
    L =< V, V =< U,
    check_prediction_types(Types,State,Horizon).

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


    must(adaptive_hk_tightens_under_uncertainty,
        (adaptive_confidence_bound(0.35,0.20,0.10,Loose),
         adaptive_confidence_bound(0.35,0.90,0.50,Tight),
         Tight < Loose,
         Tight > 0.01)),

    must(opinion_cluster_count_detects_groups,
        (opinion_cluster_count([0.10,0.12,0.50,0.52,0.90],0.08,Clusters),
         Clusters =:= 3)),

    must(all_m3b_prediction_types_bounded,
        (State=state(
            0.70,
            0.20,
            0.08,
            0.60,
            0.65,
            [0.40,0.20,0.15,0.15,0.10],
            [0.70,0.15,0.15],
            0.80,
            [0.10,0.12,0.50,0.52,0.90]
         ),
         prediction_types(Types),
         check_prediction_types(Types,State,weekly))),

    must(categorical_predictions_keep_labels,
        (State2=state(
            0.85,0.15,0.10,0.50,0.75,
            [0.45,0.15,0.10,0.10,0.20],
            [0.70,0.10,0.20],
            0.75,
            [0.70,0.72,0.75,0.80]
         ),
         sociological_prediction(pump_dump_phase,State2,daily,PV,PL,PU,PLabel),
         PL =< PV, PV =< PU,
         PLabel = promotion,
         sociological_prediction(narrative_regime,State2,monthly,NV,NL,NU,NLabel),
         NL =< NV, NV =< NU,
         NLabel = bullish)),


    must(multi_horizon_uncertainty_widens,
        (HState=state(
            0.40,0.15,0.03,0.45,0.50,
            [0.45,0.20,0.15,0.15,0.05],
            [0.80,0.10,0.10],
            0.85,
            [0.35,0.40,0.45,0.50]
         ),
         sociological_prediction(sentiment_index,HState,hourly,HV,HL,HU,_),
         sociological_prediction(sentiment_index,HState,five_year,FV,FL,FU,_),
         approx(HV,FV,1.0e-9),
         HWidth is HU-HL,
         FWidth is FU-FL,
         FWidth > HWidth)),

    writeln("SOCIOLOGICAL TESTS PASSED").
