# test_etr.R — invariants tests for the R port of the ETR five-zone torus.
# Mirrors src/endocrine/etr/test_etr.m (same laws, same source of truth). Run
# from the repo root via run_tests.sh.

source("core/src/endocrine/test_framework.R")
source("core/src/endocrine/driver_etr.R")

# --- L1 wrap ----------------------------------------------------------
test_case("etr_axis_wrap: +50 wraps to -50", function() {
  expect_equal(etr_axis_wrap(50), -50, tol = 1e-9)
})
test_case("etr_axis_wrap: 60 -> -40, -60 -> 40", function() {
  expect_equal(etr_axis_wrap(60), -40, tol = 1e-9)
  expect_equal(etr_axis_wrap(-60), 40, tol = 1e-9)
})
test_case("etr_axis_wrap: in-range unchanged; edge continuity", function() {
  expect_equal(etr_axis_wrap(25), 25, tol = 1e-9)
  expect_equal(etr_axis_wrap(49.9), etr_axis_wrap(-50.1), tol = 1e-9)
})

# --- zones ------------------------------------------------------------
test_case("etr_axis_zone: five zones at 5/10/25/40/47", function() {
  expect_equal(etr_axis_zone(5),  "SNAP_IN")
  expect_equal(etr_axis_zone(10), "SOFT")
  expect_equal(etr_axis_zone(25), "IN_BAND")
  expect_equal(etr_axis_zone(40), "INCOH")
  expect_equal(etr_axis_zone(47), "SNAP_OUT")
})

# --- L3 restoring -----------------------------------------------------
test_case("etr_axis_restoring: SOFT pulls up, INCOH pulls down, band slack", function() {
  expect_true(etr_axis_restoring(10) > 0,  "SOFT (+v) pulls toward band")
  expect_true(etr_axis_restoring(-10) < 0, "SOFT (-v) pulls toward band")
  expect_true(etr_axis_restoring(40) < 0,  "INCOH (+v) pulls toward band")
  expect_true(etr_axis_restoring(-40) > 0, "INCOH (-v) pulls toward band")
  expect_equal(etr_axis_restoring(25), 0)
})
test_case("etr_axis_restoring: zero in snap zones", function() {
  expect_equal(etr_axis_restoring(5), 0)
  expect_equal(etr_axis_restoring(47), 0)
})
test_case("etr_axis_restoring: soft-pull weaker than incoherency", function() {
  expect_true(abs(etr_axis_restoring(8)) < abs(etr_axis_restoring(44)),
              "weak soft-pull")
})

# --- L2 convergence (same pole) ---------------------------------------
test_case("L2: SOFT start settles into band without flipping sign", function() {
  s <- init_etr_state(c(10, 10, 10))
  for (k in 1:200) s <- etr_step(s, c(0, 0, 0), 0)
  a <- abs(s$coordinate)
  expect_true(all(a >= ETR_BAND_LO & a <= ETR_BAND_HI), "in band")
  expect_true(all(s$coordinate > 0), "no flip")
})

# --- L7 snap-across flips ---------------------------------------------
test_case("L7: inner snap lands in opposite SOFT, settles in opposite band", function() {
  s <- init_etr_state(c(5, 5, 5))
  s1 <- etr_step(s, c(0, 0, 0), 0)
  a1 <- abs(s1$coordinate)
  expect_true(all(s1$coordinate < 0), "flipped sign")
  expect_true(all(a1 > ETR_SNAP_INNER & a1 < ETR_BAND_LO), "lands in SOFT")
  for (k in 1:200) s <- etr_step(s, c(0, 0, 0), 0)
  a <- abs(s$coordinate)
  expect_true(all(s$coordinate < 0) && all(a >= ETR_BAND_LO & a <= ETR_BAND_HI),
              "settles in opposite band")
})
test_case("L7: outer snap lands in opposite INCOH, settles in opposite band", function() {
  s <- init_etr_state(c(47, 47, 47))
  s1 <- etr_step(s, c(0, 0, 0), 0)
  a1 <- abs(s1$coordinate)
  expect_true(all(s1$coordinate < 0), "flipped sign")
  expect_true(all(a1 > ETR_BAND_HI & a1 <= ETR_SNAP_OUTER), "lands in INCOH")
  for (k in 1:200) s <- etr_step(s, c(0, 0, 0), 0)
  a <- abs(s$coordinate)
  expect_true(all(s$coordinate < 0) && all(a >= ETR_BAND_LO & a <= ETR_BAND_HI),
              "settles in opposite band")
})

# --- L4 drift required ------------------------------------------------
test_case("L4: etr_step refuses to invent drift", function() {
  expect_error(etr_step(init_etr_state()), "drift must be supplied")
})

# --- L6 Z-path --------------------------------------------------------
test_case("L6: z<0 -> alimentation (lattice); z>=0 -> transmutation (evolution)", function() {
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, -3))), "LATTICE_REINFORCEMENT")
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, 0))),  "EXPERIMENTAL_EVOLUTION")
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, 7))),  "EXPERIMENTAL_EVOLUTION")
})

# --- status -----------------------------------------------------------
test_case("etr_status: per-axis zone vector", function() {
  st <- etr_status(init_etr_state(c(25, 10, 40)))
  expect_equal(st, c("IN_BAND", "SOFT", "INCOH"))
})

test_summary()
