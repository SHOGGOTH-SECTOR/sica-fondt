1;  % script-file marker: makes every function below visible when this file is sourced.
% =====================================================================
% ETR — Existential Temporality Relief  ·  Drive-Box Driver 4
% =====================================================================
% Model: a SINGLE POINT on three INDEPENDENT toroidal axes (x, y, z) —
% not vectors, not a field. See etr_invariants.md for the laws + tags.
%
% Each axis is a BISTABLE torus with two stable bands ([+17,+35], [-35,-17])
% and FIVE zones per pass (Anja's radial map), with unstable watersheds at
% |v| = 7 (inner) and |v| = 45 (outer):
%
%   |v| < 7    SNAP_IN  : too uncommitted -> snaps ACROSS 0 to the opposite pole
%   7 .. 17    SOFT     : weak restoring pull up into the band
%   17 .. 35   IN_BAND  : stable (slack)
%   35 .. 45   INCOH    : (incoherency) firmer restoring pull down into the band
%   |v| > 45   SNAP_OUT : too saturated -> snaps ACROSS the wrap to the opposite pole
%
% A snap lands JUST PAST the opposite watershed (Anja): an inner snap into the
% opposite SOFT zone (weak pull), an outer snap into the opposite INCOH zone.
% Pole-flips therefore happen ONLY through the two snap zones (L7) — through 0
% (inner) or over the +/-50 wrap (outer); the basin (7..45) never flips.
% =====================================================================

% ---- law constants (these ARE the law, not fitted) ----
function v = ETR_BAND_LO();    v = 17; endfunction
function v = ETR_BAND_HI();    v = 35; endfunction
function v = ETR_WRAP();       v = 50; endfunction
function v = ETR_SNAP_INNER(); v = 7;  endfunction   % inner watershed (Anja)
function v = ETR_SNAP_OUTER(); v = 45; endfunction   % outer watershed (Anja)

% ---- fitted constants (NOT law) ----
% Soft-pull is deliberately WEAKER than the incoherency pull (Anja): recovery
% from the under-committed side — and from a snap landing — is gentle.
function v = ETR_GAIN_SOFT();   v = 0.25; endfunction  % weak  (SOFT,  7..17)
function v = ETR_GAIN_INCOH();  v = 0.5;  endfunction  % firmer (INCOH, 35..45)
% How far PAST the opposite watershed a snap deposits the point.
function v = ETR_SNAP_MARGIN(); v = 2; endfunction

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

% ---- zone classification (the five-zone radial map) ----
function z = etr_axis_zone(v)
  a = abs(v);
  if     a < ETR_SNAP_INNER(),  z = 'SNAP_IN';
  elseif a < ETR_BAND_LO(),     z = 'SOFT';
  elseif a <= ETR_BAND_HI(),    z = 'IN_BAND';
  elseif a <= ETR_SNAP_OUTER(), z = 'INCOH';
  else                          z = 'SNAP_OUT';
  endif
endfunction

% ---- L3: per-axis restoring DIRECTION (basin only; CONFIRMED law) ----
% Within the basin (7..45) the restoring points toward the band:
%   SOFT  (7..17)  -> +sign(v) (up into band)
%   INCOH (35..45) -> -sign(v) (down into band)
%   IN_BAND        ->  0 (slack)
% Snap zones (|v|<7, |v|>45) are NOT restored locally — they are resolved by a
% flip across (etr_axis_snap), so this direction law is defined for the basin.
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

% ---- L3: per-axis restoring FORCE (FITTED, zone-dependent) ----
% A spring toward the band CENTRE (26), with a WEAK gain in SOFT and a firmer
% gain in INCOH. Zero in band (slack) and zero in the snap zones (those flip,
% they don't restore). A centre target makes the step cross INTO [17,35] and
% stop there (an edge target would asymptote onto 17 and fail L2 convergence).
function r = etr_axis_restoring(v)
  a = abs(v);
  centre = (ETR_BAND_LO() + ETR_BAND_HI()) / 2;     % 26
  if a < ETR_SNAP_INNER() || a > ETR_SNAP_OUTER()
    r = 0;                                          % snap zone: no local restoring
  elseif a >= ETR_BAND_LO() && a <= ETR_BAND_HI()
    r = 0;                                          % in band: slack (L3)
  elseif a < ETR_BAND_LO()
    r = ETR_GAIN_SOFT()  * (centre * sign(v) - v);  % SOFT  — weak pull
  else
    r = ETR_GAIN_INCOH() * (centre * sign(v) - v);  % INCOH — firmer pull
  endif
endfunction

% ---- snap resolution: a flip ACROSS to the opposite pole (Anja) ----
% Precondition: v is in a snap zone (|v|<7 or |v|>45). The point lands JUST PAST
% the opposite watershed, sign flipped: an inner snap -> opposite SOFT
% (|.| = 7 + margin); an outer snap -> opposite INCOH (|.| = 45 - margin). This
% is the ONLY way a pole-flip happens (L7); the landing zone then recovers it.
function v = etr_axis_snap(v)
  s = sign(v); if s == 0, s = 1; endif            % 0 has no pole; pick one
  if abs(v) < ETR_SNAP_INNER()
    v = -s * (ETR_SNAP_INNER() + ETR_SNAP_MARGIN());   % inner -> opposite SOFT  (e.g. -/+9)
  else
    v = -s * (ETR_SNAP_OUTER() - ETR_SNAP_MARGIN());   % outer -> opposite INCOH (e.g. -/+43)
  endif
endfunction

% ---- L5: cross-axis coupling (OPEN SEAM) ----
% The three axes couple via a stress metric (hypothesis: PS+/Eth-Int load).
% Mapping UNDEFINED [C1] -> identity while stress-coupling is undefined.
function c = etr_coupling(coord, stress)
  c = coord;  % STUB — TODO: define the stress-mediated cross-axis mapping
endfunction

% ---- one ETR step: AI drift -> coupling -> (snap | restoring) -> wrap ----
% drift  : 1x3, caller-supplied AI-originated motion (L4 — NOT generated here)
% stress : scalar coupling mediator (0 = off)
function s = etr_step(s, drift, stress)
  if nargin < 2
    error('etr_step: AI-originated drift must be supplied (L4 — ETR does not invent motion)');
  endif
  if nargin < 3, stress = 0; endif
  c = etr_coupling(s.coord, stress);
  for i = 1:3
    v = etr_axis_wrap(c(i) + drift(i));         % apply AI drift, wrap onto torus
    a = abs(v);
    if a < ETR_SNAP_INNER() || a > ETR_SNAP_OUTER()
      v = etr_axis_snap(v);                     % snap across to the opposite pole
    else
      v = etr_axis_wrap(v + etr_axis_restoring(v));   % basin: restore toward band
    endif
    c(i) = v;
  endfor
  s.coord = c;
endfunction

% ---- per-axis zone classification for the snapshot ----
% Five zones: 'SNAP_IN' | 'SOFT' | 'IN_BAND' | 'INCOH' | 'SNAP_OUT'.
% The old magnitude->flavor naming (DREAD/BLUR/...) is DISOWNED [C1].
function st = etr_status(s)
  st = cell(1, 3);
  for i = 1:3
    st{i} = etr_axis_zone(s.coord(i));
  endfor
endfunction
