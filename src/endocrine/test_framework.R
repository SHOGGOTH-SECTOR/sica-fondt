# --- Minimal Test Framework ---
# Dependency-free assertion harness for the endocrine / Drive-Box R reference track.
# No external packages (no testthat) so it runs under a bare r-base-core install.
#
# Usage in a test_*.R file:
#   source("src/endocrine/test_framework.R")
#   source("src/endocrine/driver_<name>.R")
#   test_case("does the thing", function() {
#     expect_equal(f(2), 4)
#     expect_true(is_alive(state))
#   })
#   test_summary()        # prints results and quits with status 0 (all pass) or 1 (any fail)
#
# All source() paths are repo-root-relative; run from the repository root
# (run_tests.sh handles the cd).

.TEST <- new.env()
.TEST$pass <- 0L
.TEST$fail <- 0L
.TEST$failures <- character(0)
.TEST$current <- "(top level)"

.record_pass <- function() {
  .TEST$pass <- .TEST$pass + 1L
}

.record_fail <- function(msg) {
  .TEST$fail <- .TEST$fail + 1L
  full <- sprintf("[%s] %s", .TEST$current, msg)
  .TEST$failures <- c(.TEST$failures, full)
  cat(sprintf("  FAIL: %s\n", full))
}

# Assert two values are equal. Numerics compared within tolerance; everything
# else with identical().
expect_equal <- function(actual, expected, tol = 1e-9, label = "") {
  ok <- FALSE
  if (is.numeric(actual) && is.numeric(expected) &&
      length(actual) == length(expected)) {
    ok <- all(abs(actual - expected) <= tol)
  } else {
    ok <- identical(actual, expected)
  }
  if (isTRUE(ok)) {
    .record_pass()
  } else {
    .record_fail(sprintf("%sexpected %s, got %s",
                         if (nzchar(label)) paste0(label, ": ") else "",
                         format(expected), format(actual)))
  }
  invisible(ok)
}

expect_true <- function(cond, label = "") {
  if (isTRUE(cond)) {
    .record_pass()
  } else {
    .record_fail(sprintf("%sexpected TRUE, got %s",
                         if (nzchar(label)) paste0(label, ": ") else "",
                         format(cond)))
  }
  invisible(isTRUE(cond))
}

expect_false <- function(cond, label = "") {
  if (identical(cond, FALSE)) {
    .record_pass()
  } else {
    .record_fail(sprintf("%sexpected FALSE, got %s",
                         if (nzchar(label)) paste0(label, ": ") else "",
                         format(cond)))
  }
  invisible(identical(cond, FALSE))
}

# Assert that evaluating expr raises an R error.
expect_error <- function(expr, label = "") {
  raised <- FALSE
  tryCatch(
    force(expr),
    error = function(e) { raised <<- TRUE }
  )
  if (raised) {
    .record_pass()
  } else {
    .record_fail(sprintf("%sexpected an error, none raised",
                         if (nzchar(label)) paste0(label, ": ") else ""))
  }
  invisible(raised)
}

# Group assertions under a description. Errors thrown inside body count as a
# failure rather than aborting the whole test file.
test_case <- function(desc, body) {
  prev <- .TEST$current
  .TEST$current <- desc
  cat(sprintf("- %s\n", desc))
  tryCatch(
    body(),
    error = function(e) .record_fail(sprintf("unexpected error: %s", conditionMessage(e)))
  )
  .TEST$current <- prev
  invisible(NULL)
}

# Print the tally and exit with a CI-friendly status code.
test_summary <- function() {
  cat(sprintf("\nRESULT: PASS %d / FAIL %d\n", .TEST$pass, .TEST$fail))
  if (.TEST$fail > 0L) {
    cat("Failures:\n")
    for (f in .TEST$failures) cat(sprintf("  - %s\n", f))
    quit(save = "no", status = 1L)
  }
  quit(save = "no", status = 0L)
}
