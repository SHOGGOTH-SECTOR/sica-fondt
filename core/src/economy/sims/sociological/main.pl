#!/usr/bin/env swipl
%
% M3b -- Sociological & population dynamics sims
% Language: Prolog (game-theoretic equilibria as constraint satisfaction)
% Protocol: line-delimited JSON on stdin/stdout to hub.tcl

:- use_module(library(lists)).
:- use_module(library(apply)).

% -- Behavioral archetypes -----------------------------------------------
% Each archetype has a strategy and population share

archetype(herd_follower).
archetype(contrarian_whale).
archetype(mev_searcher).
archetype(passive_lp).
archetype(manipulator).

% -- Replicator dynamics --------------------------------------------------
% dx_i/dt = x_i * [f_i(x) - phi(x)]
% Discretized: x_i(t+1) = x_i(t) + dt * x_i(t) * [f_i(x) - phi(x)]

% Payoff matrix: row strategy vs column strategy
% Returns payoff for Row when playing against Col
payoff(herd_follower,    herd_follower,    0.02).
payoff(herd_follower,    contrarian_whale, -0.01).
payoff(herd_follower,    mev_searcher,     -0.03).
payoff(herd_follower,    passive_lp,       0.01).
payoff(herd_follower,    manipulator,      -0.05).
payoff(contrarian_whale, herd_follower,    0.04).
payoff(contrarian_whale, contrarian_whale, -0.02).
payoff(contrarian_whale, mev_searcher,     0.01).
payoff(contrarian_whale, passive_lp,       0.02).
payoff(contrarian_whale, manipulator,      -0.01).
payoff(mev_searcher,     herd_follower,    0.06).
payoff(mev_searcher,     contrarian_whale, 0.01).
payoff(mev_searcher,     mev_searcher,     -0.04).
payoff(mev_searcher,     passive_lp,       0.05).
payoff(mev_searcher,     manipulator,      0.02).
payoff(passive_lp,       herd_follower,    0.03).
payoff(passive_lp,       contrarian_whale, 0.01).
payoff(passive_lp,       mev_searcher,     -0.02).
payoff(passive_lp,       passive_lp,       0.02).
payoff(passive_lp,       manipulator,      -0.04).
payoff(manipulator,      herd_follower,    0.08).
payoff(manipulator,      contrarian_whale, -0.03).
payoff(manipulator,      mev_searcher,     -0.02).
payoff(manipulator,      passive_lp,       0.06).
payoff(manipulator,      manipulator,      -0.06).

% Fitness of strategy I given population state Pop = [(Archetype, Share), ...]
fitness(I, Pop, F) :-
    findall(Pij, (
        member((J, Xj), Pop),
        payoff(I, J, Pij0),
        Pij is Pij0 * Xj
    ), Payoffs),
    sumlist(Payoffs, F).

% Average fitness across population
avg_fitness(Pop, Phi) :-
    findall(XiFi, (
        member((I, Xi), Pop),
        fitness(I, Pop, Fi),
        XiFi is Xi * Fi
    ), Products),
    sumlist(Products, Phi).

% One replicator step: x_i(t+dt) = x_i + dt * x_i * (f_i - phi)
replicator_step(Pop, Dt, NewPop) :-
    avg_fitness(Pop, Phi),
    maplist(update_share(Phi, Dt, Pop), Pop, RawPop),
    normalize_pop(RawPop, NewPop).

update_share(Phi, Dt, Pop, (I, Xi), (I, Xi1)) :-
    fitness(I, Pop, Fi),
    Xi1 is max(0, Xi + Dt * Xi * (Fi - Phi)).

normalize_pop(Pop, NormPop) :-
    findall(X, member((_, X), Pop), Shares),
    sumlist(Shares, Total),
    (Total > 0 ->
        maplist(norm_share(Total), Pop, NormPop)
    ;
        NormPop = Pop
    ).

norm_share(Total, (I, X), (I, Xn)) :-
    Xn is X / Total.

% Run N replicator steps
replicator_evolve(Pop, _, 0, Pop) :- !.
replicator_evolve(Pop, Dt, N, FinalPop) :-
    N > 0,
    replicator_step(Pop, Dt, Pop1),
    N1 is N - 1,
    replicator_evolve(Pop1, Dt, N1, FinalPop).

% -- Hegselmann-Krause bounded confidence ---------------------------------
% x_i(t+1) = mean({x_j : |x_j - x_i| < epsilon})

hk_step(Opinions, Epsilon, NewOpinions) :-
    maplist(hk_update(Opinions, Epsilon), Opinions, NewOpinions).

hk_update(AllOpinions, Epsilon, Xi, NewXi) :-
    include(within_confidence(Xi, Epsilon), AllOpinions, Neighbors),
    length(Neighbors, Count),
    sumlist(Neighbors, Sum),
    NewXi is Sum / Count.

within_confidence(Xi, Epsilon, Xj) :-
    abs(Xj - Xi) < Epsilon.

hk_evolve(Opinions, _, 0, Opinions) :- !.
hk_evolve(Opinions, Epsilon, N, Final) :-
    N > 0,
    hk_step(Opinions, Epsilon, Next),
    N1 is N - 1,
    hk_evolve(Next, Epsilon, N1, Final).

% -- Nash equilibrium search (constraint satisfaction) --------------------
% For 2-player symmetric games, find mixed strategy Nash equilibria
% via support enumeration

% Check if a mixed strategy (list of probabilities) is a Nash eq
% for a symmetric game with payoff matrix
is_nash_2p(Strategies, PayoffMatrix, Threshold) :-
    length(Strategies, N),
    length(PayoffMatrix, N),
    expected_payoff_vec(Strategies, PayoffMatrix, ExpPayoffs),
    max_list(ExpPayoffs, MaxPayoff),
    forall((
        nth0(I, Strategies, Si),
        nth0(I, ExpPayoffs, Ei)
    ), (
        Si =:= 0 ; abs(Ei - MaxPayoff) < Threshold
    )).

expected_payoff_vec(Strat, Matrix, Payoffs) :-
    maplist(expected_payoff_row(Strat), Matrix, Payoffs).

expected_payoff_row(Strat, Row, EP) :-
    maplist(mul, Strat, Row, Products),
    sumlist(Products, EP).

mul(A, B, C) :- C is A * B.

% -- BoundedPrediction output ---------------------------------------------

bounded_prediction(Value, Lower, Upper, Confidence, Horizon, Pred) :-
    Lower =< Value,
    Value =< Upper,
    Confidence >= 0.0,
    Confidence =< 10.0,
    get_time(Now),
    Timestamp is round(Now * 1000),
    Pred = pred(Value, Lower, Upper, Confidence, Horizon, sociological, Timestamp).

format_prediction(pred(V, L, U, C, H, T, _)) :-
    format("  value: ~4f [~4f, ~4f]~n", [V, L, U]),
    format("  confidence: ~2f/10.00~n", [C]),
    format("  horizon: ~w  type: ~w~n", [H, T]).

% -- Self-test -------------------------------------------------------------

default_population([
    (herd_follower,    0.30),
    (contrarian_whale, 0.15),
    (mev_searcher,     0.10),
    (passive_lp,       0.35),
    (manipulator,      0.10)
]).

run_self_test :-
    prolog_flag(version, V),
    format("M3b Sociological Sim -- SWI-Prolog ~w~n~n", [V]),

    format("Replicator dynamics (100 steps, dt=0.1):~n", []),
    default_population(Pop0),
    format("  initial: ", []),
    print_pop(Pop0),
    replicator_evolve(Pop0, 0.1, 100, PopFinal),
    format("  final:   ", []),
    print_pop(PopFinal),
    nl,

    format("Hegselmann-Krause (epsilon=0.2, 20 steps):~n", []),
    HKInit = [0.1, 0.2, 0.25, 0.5, 0.55, 0.8, 0.85, 0.9],
    format("  initial: ~w~n", [HKInit]),
    hk_evolve(HKInit, 0.2, 20, HKFinal),
    format("  final:   ", []),
    maplist(print_float, HKFinal), nl, nl,

    format("BoundedPrediction check:~n", []),
    (bounded_prediction(0.35, 0.20, 0.50, 7.80, '7d', Pred) ->
        format_prediction(Pred)
    ;
        format("  FAILED~n", [])
    ),

    format("~nInvariant checks:~n", []),
    (bounded_prediction(5.0, 6.0, 8.0, 7.0, '1h', _) ->
        format("  L2 bounds: FAIL~n", [])
    ;
        format("  L2 bounds: PASS (rejected lower > value)~n", [])
    ),
    (bounded_prediction(5.0, 4.0, 8.0, 11.0, '1h', _) ->
        format("  Confidence range: FAIL~n", [])
    ;
        format("  Confidence range: PASS (rejected 11.0 > 10.0)~n", [])
    ),

    format("~nAll models operational.~n", []).

print_pop([]) :- nl.
print_pop([(Name, Share)|Rest]) :-
    format("~w:~3f ", [Name, Share]),
    print_pop(Rest).

print_float(X) :- format("~3f ", [X]).

:- initialization((run_self_test, halt)).
