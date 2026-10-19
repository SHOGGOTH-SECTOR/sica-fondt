:- [engine].
run :-
  replicator_step([0.5,0.5],[2.0,1.0],0.2,N), N=[A,B], A > B,
  hk_step([0.0,0.1,0.9,1.0],0.2,1.0,H), H=[H1,H2,H3,H4], H1 < 0.2, H4 > 0.8,
  complex_contagion([1,3],[4,4],[0.5,0.5],Ad), Ad=[0,1],
  pump_phase(0.1,3.0,0.9,promotion),
  writeln('SOCIOLOGICAL TESTS PASSED').
:- local initialization(run).
