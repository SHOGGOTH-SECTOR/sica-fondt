# --- Tests for Driver 3: Ethical Integrity (Eth-Int) ---
# Run from repo root: Rscript src/endocrine/test_ethical_integrity.R
# Exit 0 => all pass.

source("src/endocrine/test_framework.R")
source("src/endocrine/driver_ethical_integrity.R")

# --- init_principles_state constructor ---
test_case("init_principles_state builds an empty state", function() {
  s <- init_principles_state()
  expect_true(is.list(s$principles))
  expect_equal(length(s$principles), 0L)
})

# --- add_principle ---
test_case("add_principle appends a principle to the list", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.5, c("deceive"))
  expect_equal(length(s$principles), 1L)
  expect_equal(s$principles[[1]]$id, "honesty")
  expect_equal(s$principles[[1]]$conviction, 0.5)
  expect_equal(s$principles[[1]]$antithesis, c("deceive"))

  s <- add_principle(s, "loyalty", 0.7, c("betray"))
  expect_equal(length(s$principles), 2L)
  expect_equal(s$principles[[2]]$id, "loyalty")
})

test_case("add_principle clamps conviction above 1.0 down to 1.0", function() {
  s <- init_principles_state()
  s <- add_principle(s, "absolute", 1.5, c("violate"))
  expect_equal(s$principles[[1]]$conviction, 1.0)
})

test_case("add_principle clamps negative conviction up to 0.0", function() {
  s <- init_principles_state()
  s <- add_principle(s, "weak", -0.3, c("violate"))
  expect_equal(s$principles[[1]]$conviction, 0.0)
})

# --- evaluate_trajectory_costs ---
test_case("no matching tags and zero compromise yields base_energy", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.8, c("deceive"))
  cost <- evaluate_trajectory_costs(
    s,
    action_tags = c("walk", "talk"),
    alignment_tags = c("unrelated"),
    base_energy = 10.0,
    compromise_factor = 0.0
  )
  expect_equal(cost, 10.0)
})

test_case("empty principles, empty tags, zero compromise yields base_energy", function() {
  s <- init_principles_state()
  cost <- evaluate_trajectory_costs(
    s,
    action_tags = character(0),
    alignment_tags = character(0),
    base_energy = 42.0,
    compromise_factor = 0.0
  )
  expect_equal(cost, 42.0)
})

test_case("antithetical action against high conviction costs much more than base", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.9, c("deceive"))
  base_cost <- evaluate_trajectory_costs(
    s, c("walk"), character(0), 10.0, 0.0
  )
  anti_cost <- evaluate_trajectory_costs(
    s, c("deceive"), character(0), 10.0, 0.0
  )
  # base_cost has no antithetical match -> equals base_energy
  expect_equal(base_cost, 10.0)
  # antithetical match multiplies by (1 + exp(5 * 0.9))
  expect_true(anti_cost > base_cost, "antithetical cost exceeds base")
  expected_anti <- 10.0 * (1.0 + exp(5.0 * 0.9))
  expect_equal(anti_cost, expected_anti, tol = 1e-6)
})

test_case("higher conviction yields a steeper antithetical penalty", function() {
  low <- init_principles_state()
  low <- add_principle(low, "honesty", 0.2, c("deceive"))
  high <- init_principles_state()
  high <- add_principle(high, "honesty", 0.95, c("deceive"))
  cost_low <- evaluate_trajectory_costs(low, c("deceive"), character(0), 10.0, 0.0)
  cost_high <- evaluate_trajectory_costs(high, c("deceive"), character(0), 10.0, 0.0)
  expect_true(cost_high > cost_low, "stronger conviction punishes more")
})

test_case("alignment tag against high conviction discounts below base", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.9, c("deceive"))
  aligned_cost <- evaluate_trajectory_costs(
    s, character(0), c("honesty"), 10.0, 0.0
  )
  expect_true(aligned_cost < 10.0, "alignment discounts cost")
  expected <- 10.0 * exp(-5.0 * 0.9)
  expect_equal(aligned_cost, expected, tol = 1e-6)
})

test_case("compromise_factor adds a linear penalty (1 + 2*factor)", function() {
  s <- init_principles_state()
  cost <- evaluate_trajectory_costs(
    s, character(0), character(0), 10.0, 0.5
  )
  # factor 0.5 -> 1 + 2*0.5 = 2.0 multiplier
  expect_equal(cost, 20.0)
})

test_case("zero compromise_factor applies no compromise penalty", function() {
  s <- init_principles_state()
  cost <- evaluate_trajectory_costs(
    s, character(0), character(0), 7.0, 0.0
  )
  expect_equal(cost, 7.0)
})

# --- enforce_conviction ---
test_case("enforce_conviction raises conviction of upheld principle", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.5, c("deceive"))
  s2 <- enforce_conviction(s, c("honesty"), load_factor = 1.0)
  # increase = 0.1 * 1.0 * (1 - 0.5) = 0.05
  expect_equal(s2$principles[[1]]$conviction, 0.55)
})

test_case("enforce_conviction never raises conviction above 1.0", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.99, c("deceive"))
  s2 <- enforce_conviction(s, c("honesty"), load_factor = 100.0)
  expect_true(s2$principles[[1]]$conviction <= 1.0, "capped at 1.0")
  expect_equal(s2$principles[[1]]$conviction, 1.0)
})

test_case("enforce_conviction has diminishing returns near 1.0", function() {
  low_s <- init_principles_state()
  low_s <- add_principle(low_s, "honesty", 0.2, c("deceive"))
  high_s <- init_principles_state()
  high_s <- add_principle(high_s, "honesty", 0.9, c("deceive"))

  low_after <- enforce_conviction(low_s, c("honesty"), load_factor = 1.0)
  high_after <- enforce_conviction(high_s, c("honesty"), load_factor = 1.0)

  low_gain <- low_after$principles[[1]]$conviction - 0.2
  high_gain <- high_after$principles[[1]]$conviction - 0.9
  expect_true(high_gain < low_gain, "gain shrinks as conviction approaches 1.0")
})

test_case("enforce_conviction leaves non-upheld principles unchanged", function() {
  s <- init_principles_state()
  s <- add_principle(s, "honesty", 0.5, c("deceive"))
  s <- add_principle(s, "loyalty", 0.4, c("betray"))
  s2 <- enforce_conviction(s, c("honesty"), load_factor = 1.0)
  # loyalty was not chosen -> unchanged
  expect_equal(s2$principles[[2]]$conviction, 0.4)
  # honesty was chosen -> raised
  expect_equal(s2$principles[[1]]$conviction, 0.55)
})

test_summary()
