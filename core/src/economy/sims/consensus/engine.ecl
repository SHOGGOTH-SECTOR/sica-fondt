% M3f consensus/staking simulator kernels for ECLiPSe Prolog 7.2.

honesty_step(Honest, HonestPayoff, AttackPayoff, Dt, Next) :-
  Avg is Honest*HonestPayoff + (1-Honest)*AttackPayoff,
  N0 is Honest + Dt*Honest*(HonestPayoff-Avg),
  (N0 < 0 -> Next=0 ; N0 > 1 -> Next=1 ; Next=N0).

required_slash_probability(HonestReward, AttackGain, SlashPenalty, P) :-
  SlashPenalty > 0,
  P0 is (AttackGain-HonestReward)/SlashPenalty,
  (P0 < 0 -> P=0 ; P0 > 1 -> P=1 ; P=P0).

markov_step(Dist, Matrix, Next) :- transpose(Matrix, T), dot_rows(T,Dist,Next).
dot_rows([],_,[]).
dot_rows([R|Rs],D,[X|Xs]) :- dot(R,D,X), dot_rows(Rs,D,Xs).
dot([],[],0.0).
dot([A|As],[B|Bs],X) :- dot(As,Bs,T), X is T+A*B.
transpose([],[]).
transpose([[]|_],[]) :- !.
transpose(M,[R|Rs]) :- heads_tails(M,R,T), transpose(T,Rs).
heads_tails([],[],[]).
heads_tails([[H|T]|Rows],[H|Hs],[T|Ts]) :- heads_tails(Rows,Hs,Ts).

consensus_liveness(HonestFraction, Threshold, Liveness) :-
  (HonestFraction >= Threshold -> Liveness=1.0 ; HonestFraction =< 0 -> Liveness=0.0 ; Liveness is HonestFraction/Threshold).
