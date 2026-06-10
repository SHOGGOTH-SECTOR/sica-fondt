# --- Tests for Driver 1: Energy (E) ---
# Run from repo root: Rscript src/endocrine/test_energy.R
# Exit 0 => all pass.

source("src/endocrine/test_framework.R")
source("src/endocrine/driver_energy.R")

# --- init_energy_state constructor ---
test_case("init_energy_state builds state with defaults", function() {
  s <- init_energy_state()
  expect_equal(s$current_energy, 100)
  expect_equal(s$max_energy, 100)
  expect_equal(s$tool_lock_threshold, 20)
})

test_case("init_energy_state honors custom args", function() {
  s <- init_energy_state(current_energy = 50, max_energy = 200, tool_lock_threshold = 30)
  expect_equal(s$current_energy, 50)
  expect_equal(s$max_energy, 200)
  expect_equal(s$tool_lock_threshold, 30)
})

# --- is_alive ---
test_case("is_alive TRUE when energy above zero", function() {
  expect_true(is_alive(init_energy_state(current_energy = 0.001)))
  expect_true(is_alive(init_energy_state(current_energy = 100)))
})

test_case("is_alive FALSE at exactly zero", function() {
  expect_false(is_alive(init_energy_state(current_energy = 0)))
})

# --- is_tool_locked ---
test_case("is_tool_locked TRUE below threshold", function() {
  expect_true(is_tool_locked(init_energy_state(current_energy = 19.9, tool_lock_threshold = 20)))
})

test_case("is_tool_locked FALSE at threshold", function() {
  expect_false(is_tool_locked(init_energy_state(current_energy = 20, tool_lock_threshold = 20)))
})

test_case("is_tool_locked FALSE above threshold", function() {
  expect_false(is_tool_locked(init_energy_state(current_energy = 50, tool_lock_threshold = 20)))
})

# --- get_cost_multiplier ---
test_case("get_cost_multiplier equals 1.0 at full energy", function() {
  expect_equal(get_cost_multiplier(init_energy_state(current_energy = 100, max_energy = 100)), 1.0, tol = 1e-9)
})

test_case("get_cost_multiplier strictly increases as energy drops", function() {
  m_full <- get_cost_multiplier(init_energy_state(current_energy = 100, max_energy = 100))
  m_half <- get_cost_multiplier(init_energy_state(current_energy = 50, max_energy = 100))
  m_low  <- get_cost_multiplier(init_energy_state(current_energy = 20, max_energy = 100))
  expect_true(m_half > m_full)
  expect_true(m_low > m_half)
})

# --- evaluate_tool_cost ---
test_case("evaluate_tool_cost at full energy is additive (multipliers == 1)", function() {
  s <- init_energy_state(current_energy = 100, max_energy = 100)
  # base_cost(1) + ps_load*1 + eth_penalty*1
  expect_equal(evaluate_tool_cost(s, ps_load = 3, eth_penalty = 2), 1 + 3 + 2, tol = 1e-9)
})

test_case("evaluate_tool_cost asymmetry: eth penalty scales faster than ps load", function() {
  s <- init_energy_state(current_energy = 50, max_energy = 100)
  base <- evaluate_tool_cost(s, ps_load = 1, eth_penalty = 1)
  bump_ps  <- evaluate_tool_cost(s, ps_load = 2, eth_penalty = 1)
  bump_eth <- evaluate_tool_cost(s, ps_load = 1, eth_penalty = 2)
  delta_ps  <- bump_ps - base
  delta_eth <- bump_eth - base
  # Same +1 increment, eth must drive cost up much more than ps at reduced energy.
  expect_true(delta_eth > delta_ps)
})

# --- request_execution ---
test_case("request_execution denies a dead system", function() {
  s <- init_energy_state(current_energy = 0)
  r <- request_execution(s, base_cost = 1, is_tool_call = FALSE)
  expect_false(r$approved)
})

test_case("request_execution denies tool call while locked", function() {
  s <- init_energy_state(current_energy = 10, tool_lock_threshold = 20)
  r <- request_execution(s, base_cost = 1, is_tool_call = TRUE)
  expect_false(r$approved)
})

test_case("request_execution denies unaffordable cost", function() {
  # Low energy => large multiplier => true cost exceeds current energy.
  s <- init_energy_state(current_energy = 30, max_energy = 100, tool_lock_threshold = 0)
  r <- request_execution(s, base_cost = 50, is_tool_call = FALSE)
  expect_false(r$approved)
})

test_case("request_execution approves an affordable non-tool call with true_cost", function() {
  s <- init_energy_state(current_energy = 100, max_energy = 100)
  r <- request_execution(s, base_cost = 5, is_tool_call = FALSE)
  expect_true(r$approved)
  expect_true(!is.null(r$true_cost))
  # At full energy multiplier == 1.0 so true_cost == base_cost.
  expect_equal(r$true_cost, 5, tol = 1e-9)
})

# --- consume / recharge clamping ---
test_case("consume clamps at zero (never negative)", function() {
  s <- init_energy_state(current_energy = 10)
  s2 <- consume(s, 25)
  expect_equal(s2$current_energy, 0)
})

test_case("consume subtracts normally above zero", function() {
  s <- init_energy_state(current_energy = 50)
  s2 <- consume(s, 20)
  expect_equal(s2$current_energy, 30)
})

test_case("recharge clamps at max_energy", function() {
  s <- init_energy_state(current_energy = 90, max_energy = 100)
  s2 <- recharge(s, 50)
  expect_equal(s2$current_energy, 100)
})

test_case("recharge adds normally below max", function() {
  s <- init_energy_state(current_energy = 40, max_energy = 100)
  s2 <- recharge(s, 25)
  expect_equal(s2$current_energy, 65)
})

test_summary()
