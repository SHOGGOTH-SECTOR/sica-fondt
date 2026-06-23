# --- Tests for Driver 2: Primal Sensates+ (PS+) ---
# Run from repo root:
#   cd /home/user/sica-fondt && Rscript src/endocrine/test_ps_plus.R

source("core/src/endocrine/test_framework.R")
source("core/src/endocrine/driver_ps_plus.R")

# Helper: does any string in a list contain the given substring?
.any_contains <- function(arguments, needle) {
  for (a in arguments) {
    if (is.character(a) && grepl(needle, a, fixed = TRUE)) return(TRUE)
  }
  return(FALSE)
}

test_case("fresh state has zero load, empty arguments, non-logical", function() {
  state <- init_ps_plus_state()
  result <- evaluate_reality(state)
  expect_equal(result$existential_load, 0.0, label = "fresh load")
  expect_true(is.list(result$arguments), label = "arguments is a list")
  expect_equal(length(result$arguments), 0L, label = "arguments empty")
  expect_false(result$is_logical, label = "fresh is_logical")
})

test_case("active contradictory channels raise load and emit VISCERAL + SYSTEMIC HEAT", function() {
  state <- init_ps_plus_state()
  # panic + clarity are a contradictory pair; magnitudes well above 0.1 threshold.
  state <- ps_set_vector(state, "panic", 0.9)
  state <- ps_set_vector(state, "clarity", 0.8)
  result <- evaluate_reality(state)

  expect_true(result$existential_load > 0, label = "load positive")
  expect_true(.any_contains(result$arguments, "VISCERAL ["), label = "has VISCERAL argument")
  expect_true(.any_contains(result$arguments, "SYSTEMIC HEAT"), label = "has SYSTEMIC HEAT argument")
  expect_false(result$is_logical, label = "active is_logical")
})

test_case("adding a high-salience prior strictly increases load and adds PRIOR argument", function() {
  state <- init_ps_plus_state()
  state <- ps_set_vector(state, "panic", 0.9)
  state <- ps_set_vector(state, "clarity", 0.8)

  before <- evaluate_reality(state)

  state <- ps_add_prior(state, "p1", "TRAUMA", 0.9, "the old wound reopens")
  after <- evaluate_reality(state)

  expect_true(after$existential_load > before$existential_load, label = "load strictly increases")
  expect_true(.any_contains(after$arguments, "PRIOR [TRAUMA]"), label = "has PRIOR [TRAUMA] argument")
  expect_true(.any_contains(after$arguments, "the old wound reopens"), label = "prior payload present")
})

test_case("is_logical is always FALSE", function() {
  s0 <- init_ps_plus_state()
  expect_false(evaluate_reality(s0)$is_logical, label = "empty")

  s1 <- ps_set_vector(init_ps_plus_state(), "curiosity", 0.7)
  expect_false(evaluate_reality(s1)$is_logical, label = "single channel")

  s2 <- ps_add_prior(s1, "p2", "TRIUMPH", 0.95, "the summit reached")
  expect_false(evaluate_reality(s2)$is_logical, label = "with prior")
})

test_summary()
