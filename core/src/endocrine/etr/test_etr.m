% test_etr.m — invariants tests for the ETR five-zone bistable axis (Octave script).
% Deliberately uses NO local functions (Octave's script-local-function visibility
% is fragile); results are built as data and looped. Run via run_etr_tests.sh.

source('etr.m');

% --- stateful checks ---------------------------------------------------

% L2 convergence (same pole): a SOFT-zone start, zero drift, settles into the
% band WITHOUT flipping sign.
s = etr_init([10 10 10]);
for k = 1:200, s = etr_step(s, [0 0 0], 0); endfor
conv_soft   = all(abs(s.coord) >= ETR_BAND_LO() & abs(s.coord) <= ETR_BAND_HI());
soft_noflip = all(s.coord > 0);

% Inner snap: a SNAP_IN start (|v|<7) flips across 0 to the opposite pole, landing
% in the opposite SOFT zone, then settles into the opposite band.
s = etr_init([5 5 5]);
s1 = etr_step(s, [0 0 0], 0);                      % one step = the snap itself
inner_lands_soft = all(s1.coord < 0) && ...
                   all(abs(s1.coord) > ETR_SNAP_INNER() & abs(s1.coord) < ETR_BAND_LO());
for k = 1:200, s = etr_step(s, [0 0 0], 0); endfor
inner_flip_band = all(s.coord < 0) && ...
                  all(abs(s.coord) >= ETR_BAND_LO() & abs(s.coord) <= ETR_BAND_HI());

% Outer snap: a SNAP_OUT start (|v|>45) flips over the wrap, landing in the
% opposite INCOH zone, then settles into the opposite band.
s = etr_init([47 47 47]);
s1 = etr_step(s, [0 0 0], 0);
outer_lands_incoh = all(s1.coord < 0) && ...
                    all(abs(s1.coord) > ETR_BAND_HI() & abs(s1.coord) <= ETR_SNAP_OUTER());
for k = 1:200, s = etr_step(s, [0 0 0], 0); endfor
outer_flip_band = all(s.coord < 0) && ...
                  all(abs(s.coord) >= ETR_BAND_LO() & abs(s.coord) <= ETR_BAND_HI());

% L4: a step with no drift argument must ERROR (ETR never invents motion).
drift_required = false;
try
  etr_step(etr_init());
catch
  drift_required = true;
end_try_catch

% --- {section, name, condition} ---------------------------------------
tests = {
  'L1 wrap',      '+50 wraps to -50',                   abs(etr_axis_wrap(50)  - (-50)) < 1e-9;
  'L1 wrap',      '60 wraps to -40',                    abs(etr_axis_wrap(60)  - (-40)) < 1e-9;
  'L1 wrap',      '-60 wraps to +40',                   abs(etr_axis_wrap(-60) -  (40)) < 1e-9;
  'L1 wrap',      'in-range value unchanged',           abs(etr_axis_wrap(25)  -   25)  < 1e-9;
  'L1 wrap',      'edge continuity 49.9 vs -50.1',      abs(etr_axis_wrap(49.9) - etr_axis_wrap(-50.1)) < 1e-9;

  'zones',        'SNAP_IN below 7',                    strcmp(etr_axis_zone(5),  'SNAP_IN');
  'zones',        'SOFT 7..17',                         strcmp(etr_axis_zone(10), 'SOFT');
  'zones',        'IN_BAND 17..35',                     strcmp(etr_axis_zone(25), 'IN_BAND');
  'zones',        'INCOH 35..45',                       strcmp(etr_axis_zone(40), 'INCOH');
  'zones',        'SNAP_OUT above 45',                  strcmp(etr_axis_zone(47), 'SNAP_OUT');

  'L3 direction', 'SOFT outward (+ for +v)',            etr_axis_restoring_dir(10)  > 0;
  'L3 direction', 'SOFT outward (- for -v)',            etr_axis_restoring_dir(-10) < 0;
  'L3 direction', 'INCOH inward (- for +v)',            etr_axis_restoring_dir(40)  < 0;
  'L3 direction', 'INCOH inward (+ for -v)',            etr_axis_restoring_dir(-40) > 0;
  'L3 direction', 'in-band is slack (0)',               etr_axis_restoring_dir(25) == 0;

  'L3 magnitude', 'SOFT force nonzero',                 etr_axis_restoring(10) != 0;
  'L3 magnitude', 'INCOH force nonzero',                etr_axis_restoring(40) != 0;
  'L3 magnitude', 'snap zone has no restoring force',   etr_axis_restoring(5) == 0;
  'L3 weighting', 'soft-pull weaker than incoherency',  abs(etr_axis_restoring(8)) < abs(etr_axis_restoring(44));

  'L2 converge',  'SOFT start settles in band (no flip)', conv_soft && soft_noflip;

  'L3 snap-in',   'inner snap lands in opposite SOFT',  inner_lands_soft;
  'L7 flip',      'inner snap flips pole -> opp. band',  inner_flip_band;
  'L3 snap-out',  'outer snap lands in opposite INCOH', outer_lands_incoh;
  'L7 flip',      'outer snap flips pole -> opp. band',  outer_flip_band;

  'L4 drift',     'step refuses to invent drift',       drift_required;
  'L5 couple',    'coupling off (stress=0) identity',   isequal(etr_coupling([25 25 25], 0), [25 25 25]);
};

pend = {
  'L5 couple',    'coupling active (stress>0) alters coord', 'stress->axis mapping undefined (C1)';
};

printf('ETR invariants — five-zone bistable axis\n\n');
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
  printf('RED: %d law(s) await implementation/fitting.\n', nf);
  exit(1);
else
  printf('GREEN.\n');
  exit(0);
endif
