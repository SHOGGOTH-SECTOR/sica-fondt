% test_etr.m — invariants-first RED tests for the ETR scaffold (Octave script).
% Deliberately uses NO local functions (Octave's script-local-function visibility
% is fragile); results are built as data and looped. RED here is CORRECT: the laws
% exist before the constants are fitted. Run via run_etr_tests.sh (handles the cd).

source('etr.m');

% --- pre-compute the stateful checks ---
% L2 band convergence: from a below-band start, zero AI-drift should settle into band.
s = etr_init([5 5 5]);
for k = 1:200, s = etr_step(s, [0 0 0], 0); endfor
conv_inband = all(abs(s.coord) >= ETR_BAND_LO() & abs(s.coord) <= ETR_BAND_HI());

% L4: a step with no drift argument must ERROR (ETR never invents motion).
drift_required = false;
try
  etr_step(etr_init());
catch
  drift_required = true;
end_try_catch

% --- {section, name, condition} ---
tests = {
  'L1 wrap',      '+50 wraps to -50',                  abs(etr_axis_wrap(50)  - (-50)) < 1e-9;
  'L1 wrap',      '60 wraps to -40',                   abs(etr_axis_wrap(60)  - (-40)) < 1e-9;
  'L1 wrap',      '-60 wraps to +40',                  abs(etr_axis_wrap(-60) -  (40)) < 1e-9;
  'L1 wrap',      'in-range value unchanged',          abs(etr_axis_wrap(25)  -   25)  < 1e-9;
  'L1 wrap',      'edge continuity 49.9 vs -50.1',     abs(etr_axis_wrap(49.9) - etr_axis_wrap(-50.1)) < 1e-9;
  'L3 direction', '|v|<17 outward (+ for +v)',         etr_axis_restoring_dir(10)  > 0;
  'L3 direction', '|v|<17 outward (- for -v)',         etr_axis_restoring_dir(-10) < 0;
  'L3 direction', '|v|>35 inward  (- for +v)',         etr_axis_restoring_dir(40)  < 0;
  'L3 direction', '|v|>35 inward  (+ for -v)',         etr_axis_restoring_dir(-40) > 0;
  'L3 direction', 'in-band is slack (0)',              etr_axis_restoring_dir(25) == 0;
  'L3 magnitude', 'out-of-band force nonzero [RED]',   etr_axis_restoring(10) != 0;
  'L2 converge',  'zero-drift settles into band [RED]', conv_inband;
  'L4 drift',     'step refuses to invent drift',      drift_required;
  'L5 couple',    'coupling off (stress=0) identity',  isequal(etr_coupling([25 25 25], 0), [25 25 25]);
};

pend = {
  'L5 couple',    'coupling active (stress>0) alters coord',       'stress->axis mapping undefined (C1)';
  'L7 no-zero-x', 'pole-flip only over the wrap, never through 0', 'mechanism unconfirmed (C2)';
};

printf('ETR invariants — red tests (laws exist before constants are fitted)\n\n');
np = 0; nf = 0;
for i = 1:rows(tests)
  if logical(tests{i, 3})
    printf('  PASS  [%s] %s\n', tests{i, 1}, tests{i, 2}); np++;
  else
    printf('  FAIL  [%s] %s\n', tests{i, 1}, tests{i, 2}); nf++;
  endif
endfor
for i = 1:rows(pend)
  printf('  PEND  [%s] %s  (%s)\n', pend{i, 1}, pend{i, 2}, pend{i, 3});
endfor

printf('\n----\nPASS=%d  FAIL=%d  PEND=%d\n', np, nf, rows(pend));
if nf > 0
  printf('RED (expected at scaffold stage): %d law(s) await implementation/fitting.\n', nf);
  exit(1);
else
  printf('GREEN.\n');
  exit(0);
endif
