1;  % script-file marker: makes every function below visible when this file is sourced.
% =====================================================================
% ETR — Existential Temporality Relief  ·  Drive-Box Driver 4  ·  SCAFFOLD
% =====================================================================
% Model: a SINGLE POINT on three INDEPENDENT toroidal axes (x, y, z) —
% not vectors, not a field. See etr_invariants.md for the laws + tags.
%
%   L1 wrap   : each axis toroidal, wraps at +/-50 (period 100)          [C5]
%   L2 bands  : stable when 17 <= |v| <= 35  (v in [-35,-17] U [17,35])  [C5]
%   L3 oppose : |v|<17 push OUTWARD (off 0); |v|>35 push INWARD (off edge)[C5]
%   L4 drift  : per-step motion is AI-originated, fed by the caller      [C4]
%   L5 couple : axes couple via a stress metric — MAPPING UNDEFINED      [C1]
%
% SCAFFOLD discipline: wrap + restoring DIRECTION are implemented (they
% are law, no fitting). The restoring MAGNITUDE (RESTORE_GAIN) and the
% cross-axis COUPLING are deliberately UNIMPLEMENTED stubs so their tests
% stay RED until fitted. No disowned number is carried forward.
% =====================================================================

% ---- law constants (these ARE the law, not fitted) ----
function v = ETR_BAND_LO();  v = 17; endfunction
function v = ETR_BAND_HI();  v = 35; endfunction
function v = ETR_WRAP();     v = 50; endfunction

% ---- state: one point, three scalars ----
function s = etr_init(coord)
  if nargin < 1, coord = [25 25 25]; endif   % default: a valid in-band point
  s = struct('coord', coord(:)');
endfunction

% ---- L1: per-axis toroidal wrap (CONFIRMED, implemented) ----
% Maps any real onto the half-open torus [-50, 50); +50 is identified with -50.
function w = etr_axis_wrap(v)
  P = 2 * ETR_WRAP();                          % period = 100
  w = mod(v + ETR_WRAP(), P) - ETR_WRAP();     % -> [-50, 50)
endfunction

% ---- L3: per-axis restoring DIRECTION (CONFIRMED law, implemented) ----
%   |v| < LO -> +sign(v) (outward, off 0)
%   |v| > HI -> -sign(v) (inward, off the edge)
%   in band  ->  0 (slack)
function d = etr_axis_restoring_dir(v)
  a = abs(v);
  if a < ETR_BAND_LO()
    d = sign(v);
  elseif a > ETR_BAND_HI()
    d = -sign(v);
  else
    d = 0;
  endif
endfunction

% ---- L3: per-axis restoring FORCE (STUB: magnitude UNFITTED -> RED) ----
% Direction above is law; the magnitude/curve (RESTORE_GAIN) is C1 TBD.
% Returns 0 for now so the magnitude + convergence tests stay red.
function r = etr_axis_restoring(v)
  r = 0;  % STUB — TODO: RESTORE_GAIN * shape(v) along etr_axis_restoring_dir(v)
endfunction

% ---- L5: cross-axis coupling (OPEN SEAM) ----
% The three axes couple via a stress metric (hypothesis: PS+/Eth-Int load).
% Mapping UNDEFINED [C1] -> identity while stress-coupling is undefined.
function c = etr_coupling(coord, stress)
  c = coord;  % STUB — TODO: define the stress-mediated cross-axis mapping
endfunction

% ---- one ETR step: AI drift -> coupling -> per-axis restoring -> wrap ----
% drift  : 1x3, caller-supplied AI-originated motion (L4 — NOT generated here)
% stress : scalar coupling mediator (0 = off)
function s = etr_step(s, drift, stress)
  if nargin < 2
    error('etr_step: AI-originated drift must be supplied (L4 — ETR does not invent motion)');
  endif
  if nargin < 3, stress = 0; endif
  c = etr_coupling(s.coord, stress);
  for i = 1:3
    c(i) = c(i) + drift(i) + etr_axis_restoring(c(i));
    c(i) = etr_axis_wrap(c(i));
  endfor
  s.coord = c;
endfunction

% ---- per-axis band classification (derived from confirmed bands) ----
% 'BELOW' (|v|<17) | 'IN_BAND' (17..35) | 'ABOVE' (|v|>35).
% The old magnitude->flavor naming (DREAD/BLUR/...) is DISOWNED [C1].
function st = etr_status(s)
  st = cell(1, 3);
  for i = 1:3
    a = abs(s.coord(i));
    if a < ETR_BAND_LO()
      st{i} = 'BELOW';
    elseif a > ETR_BAND_HI()
      st{i} = 'ABOVE';
    else
      st{i} = 'IN_BAND';
    endif
  endfor
endfunction
