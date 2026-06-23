# --- Driver 4: Existential Temporality Relief (ETR) — R port of the torus ---
#
# ETR is a SINGLE POINT on three INDEPENDENT toroidal axes (X, Y, Z). This R
# module is a faithful port of the Octave source of truth
# (src/endocrine/etr/etr.m) and its laws (src/endocrine/etr/etr_invariants.md);
# both implementations are pinned to that invariants doc. The earlier Euclidean-
# magnitude port (DREAD/BLUR/INCOHERENT, inverted Z-path) is DISOWNED.
#
# Each axis is a BISTABLE torus with five zones per pass and unstable watersheds
# at |v| = 7 (inner) and |v| = 45 (outer):
#
#   |v| < 7    SNAP_IN  : snaps ACROSS 0 to the opposite pole
#   7 .. 17    SOFT     : weak restoring pull up into the band
#   17 .. 35   IN_BAND  : stable (slack)
#   35 .. 45   INCOH    : firmer restoring pull down into the band
#   |v| > 45   SNAP_OUT : snaps ACROSS the ±50 wrap to the opposite pole
#
# A snap flips the pole and lands JUST PAST the opposite watershed (inner ->
# opposite SOFT; outer -> opposite INCOH), then that zone recovers it.
#
# State is a plain list with one field:  coordinate - length-3 numeric (X,Y,Z).

# ---- law constants (NOT fitted) ----
ETR_BAND_LO    <- 17
ETR_BAND_HI    <- 35
ETR_WRAP       <- 50
ETR_SNAP_INNER <- 7    # inner watershed (Anja)
ETR_SNAP_OUTER <- 45   # outer watershed (Anja)

# ---- fitted constants (NOT law) ----
ETR_GAIN_SOFT  <- 0.25  # weak  (SOFT,  7..17)
ETR_GAIN_INCOH <- 0.5   # firmer (INCOH, 35..45)
ETR_SNAP_MARGIN <- 2    # how far past the opposite watershed a snap lands

# Constructor: default to a valid in-band point (mirrors etr_init's [25 25 25]).
init_etr_state <- function(coordinate = c(25, 25, 25)) {
  list(coordinate = coordinate)
}

# ---- L1: per-axis toroidal wrap onto [-50, 50) ----
etr_axis_wrap <- function(v) {
  P <- 2 * ETR_WRAP
  ((v + ETR_WRAP) %% P) - ETR_WRAP
}

# ---- five-zone classification ----
etr_axis_zone <- function(v) {
  a <- abs(v)
  if (a < ETR_SNAP_INNER)      "SNAP_IN"
  else if (a < ETR_BAND_LO)    "SOFT"
  else if (a <= ETR_BAND_HI)   "IN_BAND"
  else if (a <= ETR_SNAP_OUTER) "INCOH"
  else                         "SNAP_OUT"
}

# ---- L3: per-axis restoring force (spring toward band centre 26) ----
# Weak in SOFT, firmer in INCOH; zero in band (slack) and in snap zones (those
# flip, they do not restore).
etr_axis_restoring <- function(v) {
  a <- abs(v)
  centre <- (ETR_BAND_LO + ETR_BAND_HI) / 2          # 26
  if (a < ETR_SNAP_INNER || a > ETR_SNAP_OUTER) {
    0
  } else if (a >= ETR_BAND_LO && a <= ETR_BAND_HI) {
    0
  } else if (a < ETR_BAND_LO) {
    ETR_GAIN_SOFT  * (centre * sign(v) - v)          # SOFT  — weak
  } else {
    ETR_GAIN_INCOH * (centre * sign(v) - v)          # INCOH — firmer
  }
}

# ---- L7: snap resolution — a flip ACROSS to the opposite pole ----
# Precondition: |v| < 7 or |v| > 45. Lands just past the opposite watershed,
# sign flipped: inner -> opposite SOFT (±9); outer -> opposite INCOH (±43).
etr_axis_snap <- function(v) {
  s <- sign(v); if (s == 0) s <- 1                   # 0 has no pole; pick one
  if (abs(v) < ETR_SNAP_INNER) {
    -s * (ETR_SNAP_INNER + ETR_SNAP_MARGIN)          # inner -> opposite SOFT
  } else {
    -s * (ETR_SNAP_OUTER - ETR_SNAP_MARGIN)          # outer -> opposite INCOH
  }
}

# ---- one ETR step: AI drift -> (snap | restoring) -> wrap ----
# drift is AI-originated (L4); ETR never invents motion. stress is the L5
# coupling mediator (open seam -> identity for now).
etr_step <- function(etr_state, drift, stress = 0) {
  if (missing(drift)) {
    stop("etr_step: AI-originated drift must be supplied (L4 — ETR does not invent motion)")
  }
  coord <- etr_state$coordinate                      # coupling identity (L5 open)
  for (i in 1:3) {
    v <- etr_axis_wrap(coord[i] + drift[i])
    a <- abs(v)
    if (a < ETR_SNAP_INNER || a > ETR_SNAP_OUTER) {
      v <- etr_axis_snap(v)
    } else {
      v <- etr_axis_wrap(v + etr_axis_restoring(v))
    }
    coord[i] <- v
  }
  etr_state$coordinate <- coord
  etr_state
}

# ---- per-axis zone status (length-3 character vector) ----
etr_status <- function(etr_state) {
  vapply(etr_state$coordinate, etr_axis_zone, character(1))
}

# ---- L6 Z-path: the generative update path selected by the Z-axis sign ----
# z < 0  -> alimentation (maintain self)  -> LATTICE_REINFORCEMENT
# z >= 0 -> transmutation (evolve self)   -> EXPERIMENTAL_EVOLUTION
determine_system_update_path <- function(etr_state) {
  z <- etr_state$coordinate[3]
  if (z < 0) "LATTICE_REINFORCEMENT" else "EXPERIMENTAL_EVOLUTION"
}
