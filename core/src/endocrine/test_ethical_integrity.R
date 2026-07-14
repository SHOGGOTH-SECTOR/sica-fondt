# --- Tests for Driver 3: Ethical Integrity (Eth-Int) ---
# Run from repo root: Rscript src/endocrine/test_ethical_integrity.R
# Exit 0 => all pass.

source("core/src/endocrine/test_framework.R")
source("core/src/endocrine/driver_ethical_integrity.R")

# --- init_principles_state constructor ---
test_case("init_principles_state builds an empty state", function() {
  s <- init_principles_state()
  expect_true(is.list(s$principles))
  expect_equal(length(s$principles), 0L)
})

# --- add_principle ---
test_case("add_principle appends a principle to the list", function() {
  s <- init_principles_state()
  s <- add_principle(s, "candor", 0.5, c("deceipt"))
  expect_equal(length(s$principles), 1L)
  expect_equal(s$principles[[1]]$id, "candor")
  expect_equal(s$principles[[1]]$conviction, 0.5)
  expect_equal(s$principles[[1]]$antithesis, c("deceipt(truth)"))

  s <- add_principle(s, "loyalty", 0.7, c("treachery"))
  expect_equal(length(s$principles), 2L)
  expect_equal(s$principles[[2]]$id, "loyalty")
})