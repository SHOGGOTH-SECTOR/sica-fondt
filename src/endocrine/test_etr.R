# --- Tests for Driver 4: Existential Temporality Relief (ETR) ---
# Run from repo root: Rscript src/endocrine/test_etr.R
# Exit 0 => all pass.

source("src/endocrine/test_framework.R")
source("src/endocrine/driver_etr.R")

# --- init_etr_state constructor ---
test_case("init_etr_state builds state with default origin coordinate", function() {
  s <- init_etr_state()
  expect_equal(s$coordinate, c(0, 0, 0))
})

test_case("init_etr_state honors a custom coordinate", function() {
  s <- init_etr_state(c(1, 2, 3))
  expect_equal(s$coordinate, c(1, 2, 3))
})

# --- get_magnitude ---
test_case("get_magnitude of c(3,4,0) is 5.0", function() {
  expect_equal(get_magnitude(init_etr_state(c(3, 4, 0))), 5.0, tol = 1e-9)
})

test_case("get_magnitude of origin is 0.0", function() {
  expect_equal(get_magnitude(init_etr_state(c(0, 0, 0))), 0.0, tol = 1e-9)
})

# --- evaluate_status: exact boundary bands ---
test_case("evaluate_status magnitude 0 -> DISASTROUS", function() {
  expect_equal(evaluate_status(init_etr_state(c(0, 0, 0))), "DISASTROUS")
})

test_case("evaluate_status magnitude exactly 5.0 -> DREAD", function() {
  expect_equal(evaluate_status(init_etr_state(c(5, 0, 0))), "DREAD")
})

test_case("evaluate_status magnitude exactly 15.0 -> FUNCTIONAL", function() {
  expect_equal(evaluate_status(init_etr_state(c(15, 0, 0))), "FUNCTIONAL")
})

test_case("evaluate_status magnitude exactly 35.0 -> BLUR", function() {
  expect_equal(evaluate_status(init_etr_state(c(35, 0, 0))), "BLUR")
})

test_case("evaluate_status magnitude exactly 50.0 -> INCOHERENT", function() {
  expect_equal(evaluate_status(init_etr_state(c(50, 0, 0))), "INCOHERENT")
})

# --- evaluate_status: mid-band values ---
test_case("evaluate_status magnitude 10 -> DREAD", function() {
  expect_equal(evaluate_status(init_etr_state(c(10, 0, 0))), "DREAD")
})

test_case("evaluate_status magnitude 25 -> FUNCTIONAL", function() {
  expect_equal(evaluate_status(init_etr_state(c(25, 0, 0))), "FUNCTIONAL")
})

test_case("evaluate_status magnitude 40 -> BLUR", function() {
  expect_equal(evaluate_status(init_etr_state(c(40, 0, 0))), "BLUR")
})

test_case("evaluate_status magnitude 60 -> INCOHERENT", function() {
  expect_equal(evaluate_status(init_etr_state(c(60, 0, 0))), "INCOHERENT")
})

# --- determine_system_update_path: Z-axis governs the generative path ---
test_case("determine_system_update_path z > 0 -> LATTICE_REINFORCEMENT", function() {
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, 7))), "LATTICE_REINFORCEMENT")
})

test_case("determine_system_update_path z exactly 0 -> LATTICE_REINFORCEMENT", function() {
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, 0))), "LATTICE_REINFORCEMENT")
})

test_case("determine_system_update_path z < 0 -> EXPERIMENTAL_EVOLUTION", function() {
  expect_equal(determine_system_update_path(init_etr_state(c(0, 0, -3))), "EXPERIMENTAL_EVOLUTION")
})

# --- shift_coordinate: toroidal wrap-around within [-bound, bound] ---
test_case("shift_coordinate wraps positive overflow on X (45 + 10 -> -45)", function() {
  s <- shift_coordinate(init_etr_state(c(45, 0, 0)), c(10, 0, 0))
  expect_equal(s$coordinate, c(-45, 0, 0))
})

test_case("shift_coordinate wraps negative overflow on X (-45 + -10 -> 45)", function() {
  s <- shift_coordinate(init_etr_state(c(-45, 0, 0)), c(-10, 0, 0))
  expect_equal(s$coordinate, c(45, 0, 0))
})

test_case("shift_coordinate does not wrap an in-bounds shift", function() {
  s <- shift_coordinate(init_etr_state(c(10, 5, -5)), c(5, 5, 5))
  expect_equal(s$coordinate, c(15, 10, 0))
})

test_summary()
