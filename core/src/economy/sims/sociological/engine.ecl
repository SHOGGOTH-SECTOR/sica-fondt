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
    (Frac >= T -> A=1 ; A=0), contagion_(Es,Ds,Ts,As).

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
        Bonus is Explore * sqrt(log(Total) / Count)
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
