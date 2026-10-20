% M3b sociological simulator kernels for ECLiPSe Prolog 7.2.

sum_list([], 0.0).
sum_list([X|Xs], S) :- sum_list(Xs, T), S is X + T.

normalize([], []).
normalize(Xs, Ys) :- sum_list(Xs, S), S > 0, normalize_(Xs, S, Ys).
normalize_([], _, []).
normalize_([X|Xs], S, [Y|Ys]) :- Y is X/S, normalize_(Xs,S,Ys).

weighted_mean([], [], 0.0).
weighted_mean([X|Xs],[P|Ps], M) :- weighted_mean(Xs,Ps,T), M is T + X*P.

replicator_step(Shares, Payoffs, Dt, Next) :-
    weighted_mean(Payoffs, Shares, Avg),
    replicator_raw(Shares,Payoffs,Avg,Dt,Raw), normalize(Raw,Next).
replicator_raw([],[],_,_,[]).
replicator_raw([X|Xs],[P|Ps],Avg,Dt,[Y|Ys]) :-
    Y0 is X + Dt*X*(P-Avg), (Y0 < 0 -> Y = 0 ; Y = Y0),
    replicator_raw(Xs,Ps,Avg,Dt,Ys).

hk_step(Opinions, Bound, Mu, Next) :- hk_all(Opinions,Opinions,Bound,Mu,Next).
hk_all([],_,_,_,[]).
hk_all([X|Xs],All,D,Mu,[Y|Ys]) :- neighbor_mean(All,X,D,M), Y is X + Mu*(M-X), hk_all(Xs,All,D,Mu,Ys).
neighbor_mean(All,X,D,M) :- collect_neighbors(All,X,D,Ns), sum_list(Ns,S), length(Ns,N), N > 0, M is S/N.
collect_neighbors([],_,_,[]).
collect_neighbors([Y|Ys],X,D,[Y|Ns]) :- abs(Y-X) =< D, !, collect_neighbors(Ys,X,D,Ns).
collect_neighbors([_|Ys],X,D,Ns) :- collect_neighbors(Ys,X,D,Ns).

complex_contagion(Exposures, Degrees, Thresholds, Adoption) :- contagion_(Exposures,Degrees,Thresholds,Adoption).
contagion_([],[],[],[]).
contagion_([E|Es],[D|Ds],[T|Ts],[A|As]) :-
    (D =< 0 -> Frac=0 ; Frac is E/D),
    (E >= 2, Frac >= T -> A=1 ; A=0),
    contagion_(Es,Ds,Ts,As).

pump_phase(PriceDelta, VolumeRatio, Sentiment, Phase) :-
    (VolumeRatio > 2.0, Sentiment > 0.6, PriceDelta > 0.05 -> Phase=promotion ;
     VolumeRatio > 2.0, PriceDelta < -0.05 -> Phase=collapse ;
     VolumeRatio > 1.5, PriceDelta >= 0 -> Phase=distribution ;
     Phase=accumulation).


% V1 behavioral archetypes. These are abstract population roles, never literal
% identities or profiles of real market participants.
archetype_catalog([
    retail_herd,
    contrarian_whale,
    mev_searcher,
    passive_lp,
    manipulator
]).

ucb_score(_, Count, _, _, 1.0e9) :-
    Count =< 0, !.
ucb_score(Mean, Count, Total, Explore, Score) :-
    Count > 0,
    ( Total =< 1 ->
        Bonus = 0.0
    ;
        Bonus is Explore * sqrt(ln(Total) / Count)
    ),
    Score is Mean + Bonus.

ucb_scores([], [], _, _, []).
ucb_scores([Reward|Rewards], [Count|Counts], Total, Explore, [Score|Scores]) :-
    ( Count =< 0 ->
        Mean = 0.0
    ;
        Mean is Reward / Count
    ),
    ucb_score(Mean, Count, Total, Explore, Score),
    ucb_scores(Rewards, Counts, Total, Explore, Scores).

bandit_replicator_step(
    Shares,
    RewardSums,
    Counts,
    Total,
    Explore,
    Dt,
    Next,
    Scores
) :-
    ucb_scores(RewardSums, Counts, Total, Explore, Scores),
    replicator_step(Shares, Scores, Dt, Next).


% --- Large-population mean-field game --------------------------------------

mfg_valid_population(N) :- integer(N), N >= 100.

zeros_like([], []).
zeros_like([_|Xs], [0.0|Zs]) :- zeros_like(Xs, Zs).

nth0_value([X|_], 0, X) :- !.
nth0_value([_|Xs], I, X) :-
    I > 0,
    I1 is I - 1,
    nth0_value(Xs, I1, X).

reflected_neighbor(List, I, N, X) :-
    ( I < 0 ->
        nth0_value(List, 0, X)
    ; I >= N ->
        Last is N - 1,
        nth0_value(List, Last, X)
    ;
        nth0_value(List, I, X)
    ).

hjb_residual_at(M, U, I, N, Diffusion, Coupling, Residual) :-
    nth0_value(U, I, Ui),
    nth0_value(M, I, Mi),
    IL is I - 1,
    IR is I + 1,
    reflected_neighbor(U, IL, N, UL),
    reflected_neighbor(U, IR, N, UR),
    Grad is (UR - UL) / 2.0,
    Lap is UL - 2.0*Ui + UR,
    Residual is Ui + 0.5*Grad*Grad - Coupling*Mi - Diffusion*Lap.

hjb_residuals(M, U, Diffusion, Coupling, Residuals) :-
    length(U, N),
    hjb_residuals_(0, N, M, U, Diffusion, Coupling, Residuals).
hjb_residuals_(I, N, _, _, _, _, []) :- I >= N, !.
hjb_residuals_(I, N, M, U, Diffusion, Coupling, [R|Rs]) :-
    hjb_residual_at(M, U, I, N, Diffusion, Coupling, R),
    I1 is I + 1,
    hjb_residuals_(I1, N, M, U, Diffusion, Coupling, Rs).

newton_value_update([], [], _, _, []).
newton_value_update([U|Us], [R|Rs], Diffusion, Damping, [V|Vs]) :-
    Denom is 1.0 + 2.0*Diffusion,
    V is U - Damping*R/Denom,
    newton_value_update(Us, Rs, Diffusion, Damping, Vs).

hjb_newton_step(M, U, Diffusion, Coupling, Damping, Next, Residuals) :-
    hjb_residuals(M, U, Diffusion, Coupling, Residuals),
    newton_value_update(U, Residuals, Diffusion, Damping, Next).

boltzmann_weights([], _, []).
boltzmann_weights([U|Us], Temperature, [W|Ws]) :-
    W is exp(-U / Temperature),
    boltzmann_weights(Us, Temperature, Ws).

fp_stationary_density(U, Diffusion, Density) :-
    ( Diffusion < 1.0e-6 -> Temp = 1.0e-6 ; Temp = Diffusion ),
    boltzmann_weights(U, Temp, Raw),
    normalize(Raw, Density).

blend_density([], [], _, []).
blend_density([M|Ms], [T|Ts], Damping, [N|Ns]) :-
    N0 is (1.0-Damping)*M + Damping*T,
    ( N0 < 0.0 -> N = 0.0 ; N = N0 ),
    blend_density(Ms, Ts, Damping, Ns).

density_relax(M, Target, Damping, Next) :-
    blend_density(M, Target, Damping, Raw),
    normalize(Raw, Next).

abs_list([], []).
abs_list([X|Xs], [A|As]) :- A is abs(X), abs_list(Xs, As).

max_list([X|Xs], Max) :- max_list_(Xs, X, Max).
max_list_([], Max, Max).
max_list_([X|Xs], Acc, Max) :-
    ( X > Acc -> Acc1 = X ; Acc1 = Acc ),
    max_list_(Xs, Acc1, Max).

list_l1([], [], 0.0).
list_l1([A|As], [B|Bs], D) :-
    list_l1(As, Bs, Tail),
    D is abs(A-B) + Tail.

mfg_residual(M, U, Diffusion, Coupling, Residual) :-
    hjb_residuals(M, U, Diffusion, Coupling, H),
    abs_list(H, AbsH),
    max_list(AbsH, HMax),
    fp_stationary_density(U, Diffusion, Target),
    list_l1(M, Target, FpResidual),
    Residual is max(HMax, FpResidual).

mfg_iter(0, M, U, Diffusion, Coupling, _, M, U, Residual) :- !,
    mfg_residual(M, U, Diffusion, Coupling, Residual).
mfg_iter(K, M, U, Diffusion, Coupling, Damping, Density, Value, Residual) :-
    K > 0,
    hjb_newton_step(M, U, Diffusion, Coupling, Damping, U1, _),
    fp_stationary_density(U1, Diffusion, Target),
    density_relax(M, Target, Damping, M1),
    K1 is K - 1,
    mfg_iter(K1, M1, U1, Diffusion, Coupling, Damping,
             Density, Value, Residual).

mfg_equilibrium(
    Population,
    InitialDensity,
    Diffusion,
    Coupling,
    Damping,
    Iterations,
    Density,
    Value,
    Stability,
    Residual
) :-
    mfg_valid_population(Population),
    Diffusion > 0.0,
    Coupling >= 0.0,
    Damping > 0.0,
    Damping =< 1.0,
    integer(Iterations),
    Iterations > 0,
    normalize(InitialDensity, M0),
    zeros_like(M0, U0),
    mfg_iter(Iterations, M0, U0, Diffusion, Coupling, Damping,
             Density, Value, Residual),
    Stability is 1.0 / (1.0 + 10.0*Residual).


% --- Pump/dump three-population ABM ----------------------------------------

pump_phase_payoffs(accumulation, [1.00,1.10,1.30]).
pump_phase_payoffs(promotion,    [1.15,1.35,2.00]).
pump_phase_payoffs(distribution, [0.85,1.20,1.45]).
pump_phase_payoffs(collapse,     [0.70,1.40,0.20]).

satisficing_payoff(Payoff, Aspiration, Limit, Effective) :-
    Gap is Payoff - Aspiration,
    ( Gap > Limit ->
        Bounded = Limit
    ; Gap < -Limit ->
        Bounded is -Limit
    ;
        Bounded = Gap
    ),
    Effective is Aspiration + Bounded.

satisficing_payoffs([], _, _, []).
satisficing_payoffs([P|Ps], Aspiration, Limit, [E|Es]) :-
    satisficing_payoff(P, Aspiration, Limit, E),
    satisficing_payoffs(Ps, Aspiration, Limit, Es).

pump_abm_step(
    Shares,
    PriceDelta,
    VolumeRatio,
    Sentiment,
    Dt,
    Next,
    Phase
) :-
    Shares = [_,_,_],
    pump_phase(PriceDelta, VolumeRatio, Sentiment, Phase),
    pump_phase_payoffs(Phase, RawPayoffs),
    satisficing_payoffs(RawPayoffs, 1.0, 0.75, Payoffs),
    replicator_step(Shares, Payoffs, Dt, Next).


% --- Adaptive confidence, clusters, and bounded prediction contract --------

clamp_value(X, Lo, Hi, Y) :-
    ( X < Lo -> Y = Lo
    ; X > Hi -> Y = Hi
    ; Y = X
    ).

adaptive_confidence_bound(Base, Volatility, Dispersion, Bound) :-
    Base > 0.0,
    Penalty is 0.35*Volatility + 0.45*Dispersion,
    Raw is Base * (1.0 - Penalty),
    clamp_value(Raw, 0.01, Base, Bound).

opinion_cluster_count([], _, 0) :- !.
opinion_cluster_count(Opinions, Bound, Count) :-
    Bound >= 0.0,
    sort(Opinions, Sorted),
    Sorted = [First|Rest],
    cluster_count_sorted(Rest, First, Bound, 1, Count).

cluster_count_sorted([], _, _, Count, Count).
cluster_count_sorted([X|Xs], Previous, Bound, Acc, Count) :-
    Gap is X - Previous,
    ( Gap > Bound -> Acc1 is Acc + 1 ; Acc1 = Acc ),
    cluster_count_sorted(Xs, X, Bound, Acc1, Count).

sentiment_label(Sentiment, bullish) :- Sentiment > 0.25, !.
sentiment_label(Sentiment, bearish) :- Sentiment < -0.25, !.
sentiment_label(_, neutral).

narrative_label(Sentiment, PriceShift, bearish) :-
    (Sentiment < -0.25 ; PriceShift < -0.05), !.
narrative_label(Sentiment, PriceShift, bullish) :-
    Sentiment > 0.25, PriceShift >= 0.0, !.
narrative_label(_, _, neutral).

dominant_strategy(Shares, Label, Share) :-
    archetype_catalog(Labels),
    Shares = [S|Ss],
    Labels = [L|Ls],
    dominant_strategy_(Ss, Ls, L, S, Label, Share).

dominant_strategy_([], [], Label, Share, Label, Share).
dominant_strategy_([S|Ss], [L|Ls], BestL, BestS, Label, Share) :-
    ( S > BestS ->
        NextL = L, NextS = S
    ;
        NextL = BestL, NextS = BestS
    ),
    dominant_strategy_(Ss, Ls, NextL, NextS, Label, Share).

bounded_unit(Value0, Width0, Value, Lower, Upper) :-
    clamp_value(Value0, 0.0, 1.0, Value),
    (Width0 < 0.0 -> Width = 0.0 ; Width = Width0),
    L0 is Value - Width,
    U0 is Value + Width,
    clamp_value(L0, 0.0, 1.0, Lower),
    clamp_value(U0, 0.0, 1.0, Upper).

bounded_ten(Value0, Width0, Value, Lower, Upper) :-
    clamp_value(Value0, 0.0, 10.0, Value),
    (Width0 < 0.0 -> Width = 0.0 ; Width = Width0),
    L0 is Value - Width,
    U0 is Value + Width,
    clamp_value(L0, 0.0, 10.0, Lower),
    clamp_value(U0, 0.0, 10.0, Upper).

horizon_scale(current, 0.50).
horizon_scale(hourly, 0.65).
horizon_scale(tick_hourly, 0.65).
horizon_scale(daily, 0.80).
horizon_scale(weekly, 1.00).
horizon_scale(monthly, 1.20).
horizon_scale(annual, 1.50).
horizon_scale(five_year, 1.80).

horizon_width(Horizon, BaseWidth, Width) :-
    horizon_scale(Horizon, Scale),
    Width is BaseWidth * Scale.

phase_code(accumulation, 0.25).
phase_code(promotion, 0.50).
phase_code(distribution, 0.75).
phase_code(collapse, 1.00).

regime_code(bearish, 0.0).
regime_code(neutral, 0.5).
regime_code(bullish, 1.0).

sociological_prediction(
    sentiment_index,
    state(Sentiment,Dispersion,_,_,_,_,_,_,_),
    Horizon,
    Value,Lower,Upper,Label
) :- !,
    Raw is (Sentiment + 1.0) * 5.0,
    BaseWidth is 0.5 + 4.0*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_ten(Raw, Width, Value, Lower, Upper),
    sentiment_label(Sentiment, Label).

sociological_prediction(
    herd_threshold,
    state(_,Dispersion,_,Volatility,_,_,_,_,_),
    Horizon,
    Value,Lower,Upper,herd_activation
) :- !,
    adaptive_confidence_bound(0.35, Volatility, Dispersion, Value),
    BaseWidth is 0.10 + 0.20*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Value, Width, Value, Lower, Upper).

sociological_prediction(
    strategy_distribution,
    state(_,Dispersion,_,_,_,Shares,_,_,_),
    Horizon,
    Value,Lower,Upper,Label
) :- !,
    dominant_strategy(Shares, Label, Dominant),
    BaseWidth is 0.05 + 0.20*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Dominant, Width, Value, Lower, Upper).

sociological_prediction(
    cascade_probability,
    state(_,Dispersion,_,Volatility,ExposureRate,_,_,_,_),
    Horizon,
    Value,Lower,Upper,complex_contagion
) :- !,
    adaptive_confidence_bound(0.35, Volatility, Dispersion, Threshold),
    E2 is ExposureRate*ExposureRate,
    T2 is Threshold*Threshold,
    ( E2 + T2 =< 0.0 -> Raw = 0.0 ; Raw is E2/(E2+T2) ),
    BaseWidth is 0.05 + 0.25*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Raw, Width, Value, Lower, Upper).

sociological_prediction(
    coordination_stability,
    state(_,Dispersion,_,Volatility,_,_,_,MfgStability,_),
    Horizon,
    Value,Lower,Upper,coordination
) :- !,
    Raw is MfgStability * (1.0-Dispersion) * (1.0-0.25*Volatility),
    BaseWidth is 0.05 + 0.20*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Raw, Width, Value, Lower, Upper).

sociological_prediction(
    opinion_cluster_count,
    state(_,Dispersion,_,Volatility,_,_,_,_,Opinions),
    Horizon,
    Value,Lower,Upper,clusters
) :- !,
    adaptive_confidence_bound(0.35, Volatility, Dispersion, Bound),
    opinion_cluster_count(Opinions, Bound, Count),
    length(Opinions, N),
    Value is float(Count),
    horizon_scale(Horizon, Scale),
    L0 is max(1.0, Value-Scale),
    U0 is min(float(N), Value+Scale),
    Lower = L0,
    Upper = U0.

sociological_prediction(
    pump_dump_phase,
    state(Sentiment,Dispersion,PriceShift,_,ExposureRate,_,_,_,_),
    Horizon,
    Value,Lower,Upper,Phase
) :- !,
    VolumeRatio is 1.0 + 2.0*ExposureRate,
    pump_phase(PriceShift, VolumeRatio, Sentiment, Phase),
    phase_code(Phase, Raw),
    BaseWidth is 0.05 + 0.15*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Raw, Width, Value, Lower, Upper).

sociological_prediction(
    mfg_equilibrium_stability,
    state(_,Dispersion,_,_,_,_,_,MfgStability,_),
    Horizon,
    Value,Lower,Upper,mfg
) :- !,
    BaseWidth is 0.05 + 0.20*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(MfgStability, Width, Value, Lower, Upper).

sociological_prediction(
    narrative_regime,
    state(Sentiment,Dispersion,PriceShift,_,_,_,_,_,_),
    Horizon,
    Value,Lower,Upper,Label
) :- !,
    narrative_label(Sentiment, PriceShift, Label),
    regime_code(Label, Raw),
    BaseWidth is 0.05 + 0.20*Dispersion,
    horizon_width(Horizon, BaseWidth, Width),
    bounded_unit(Raw, Width, Value, Lower, Upper).
