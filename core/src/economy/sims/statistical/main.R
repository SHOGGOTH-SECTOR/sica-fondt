#!/usr/bin/env Rscript
# main.R — M3a statistical sims, Hub stdin/stdout protocol entry point.
#
# Request (one JSON object on stdin):
#   { "sim": "gbm|heston|jump_diffusion|fbm|copula|hmm_regime|garch|dcc",
#     "token_ticker": "XMR",
#     "prices": [ ... ],           # price history, oldest first
#     "ref_prices": [ ... ],       # required for copula/dcc only
#     "horizon": 24,               # steps ahead
#     "seed": 42 }                 # optional, for reproducible runs
#
# Response (one BoundedPrediction JSON object on stdout, M3 hub §5):
#   value, lower_bound, upper_bound, confidence, correctness, certainty,
#   time_horizon, sim_type, timestamp, token_ticker, recent_shift
#
# correctness and confidence are OWNED BY THE HUB's calibration loop (M3 §5):
# M3a emits its raw certainty and echoes nulls for the calibrated fields.
# Errors go to stderr + exit 1; stdout carries only valid JSON.

base_dir <- dirname(sub("--file=", "",
             grep("--file=", commandArgs(FALSE), value = TRUE)[1]))
source(file.path(base_dir, "json_io.R"))
source(file.path(base_dir, "sde_sims.R"))
source(file.path(base_dir, "copula.R"))

fail <- function(msg) { cat(msg, "\n", file = stderr()); quit(status = 1) }

req <- tryCatch(json_parse(paste(readLines("stdin"), collapse = "\n")),
                error = function(e) fail(paste("bad request:", e$message)))

sim     <- req$sim
ticker  <- req$token_ticker
horizon <- as.integer(req$horizon)
prices  <- as.numeric(unlist(req$prices))
if (is.null(sim) || is.null(ticker)) fail("missing sim or token_ticker")
if (length(prices) < 32) fail("need >= 32 price points")
if (is.na(horizon) || horizon < 1) fail("bad horizon")
if (!is.null(req$seed)) set.seed(as.integer(req$seed))

needs_ref <- sim %in% c("copula", "dcc")
ref <- if (needs_ref) as.numeric(unlist(req$ref_prices)) else NULL
if (needs_ref && length(ref) < 32) fail("sim needs ref_prices (>= 32 points)")

res <- switch(sim,
  gbm            = sim_gbm(prices, horizon),
  heston         = sim_heston(prices, horizon),
  jump_diffusion = sim_jump_diffusion(prices, horizon),
  fbm            = sim_fbm(prices, horizon),
  copula         = sim_copula(prices, ref, horizon),
  hmm_regime     = ,
  garch          = ,
  dcc            = {
    # vital-package sims live in their own file so the light sims don't pay
    # the rugarch/rmgarch load time
    source(file.path(base_dir, "regimes_garch.R"))
    switch(sim,
      hmm_regime = sim_hmm_regime(prices, horizon),
      garch      = sim_garch(prices, horizon),
      dcc        = sim_dcc(prices, ref, horizon))
  },
  fail(paste("unknown sim:", sim)))

# recent_shift: realized log-return over the trailing horizon window —
# same ground-truth window M2 uses for correctness scoring (M3 hub §5)
window <- min(horizon, length(prices) - 1)
recent_shift <- log(prices[length(prices)]) -
                log(prices[length(prices) - window])

out <- list(
  value        = res$value,
  lower_bound  = res$lower_bound,
  upper_bound  = res$upper_bound,
  confidence   = NULL,             # Hub calibration owns this
  correctness  = NULL,             # Hub scoring owns this
  certainty    = res$certainty,
  time_horizon = horizon,
  sim_type     = paste0("statistical/", sim),
  timestamp    = as.integer(Sys.time()),
  token_ticker = ticker,
  recent_shift = recent_shift)

cat(json_emit(out), "\n")
