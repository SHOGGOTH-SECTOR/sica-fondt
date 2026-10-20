:- [engine].
run :-
  honesty_step(0.5,2.0,1.0,0.2,H), H > 0.5,
  required_slash_probability(2.0,5.0,10.0,P), abs(P-0.3) < 0.000001,
  markov_step([1.0,0.0],[[0.9,0.1],[0.2,0.8]],N), N=[A,B], abs(A-0.9)<0.000001, abs(B-0.1)<0.000001,
  consensus_liveness(0.5,0.67,L), L < 1.0,
  writeln('CONSENSUS TESTS PASSED').
:- local initialization(run).
