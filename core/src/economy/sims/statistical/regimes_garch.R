# regimes_garch.R — the vital-package sims (M3a spec §3).
# HiddenMarkov: 2-state Gaussian HMM regime detection (Baum-Welch fit,
# Viterbi decode). rugarch: univariate GARCH(1,1) volatility forecast.
# rmgarch: DCC-GARCH cross-asset correlation. These three are the only
# CRAN dependencies in M3a; everything else is hand-rolled.

suppressMessages({
  library(HiddenMarkov)
  library(rugarch)
})

# Two-regime (calm/stressed) HMM on log-returns. Forecast blends the
# per-regime means weighted by the transition row of the decoded current
# state; certainty is the Viterbi state's posterior occupancy.
sim_hmm_regime <- function(prices, horizon, level = 0.90) {
  r <- diff(log(prices))
  q1 <- unname(quantile(abs(r - mean(r)), 0.5))
  init <- list(mean = c(mean(r[abs(r - mean(r)) <= q1]),
                        mean(r[abs(r - mean(r)) > q1])),
               sd   = c(max(sd(r[abs(r - mean(r)) <= q1]), 1e-8),
                        max(sd(r[abs(r - mean(r)) > q1]), 1e-8)))
  hmm <- dthmm(r,
               Pi = matrix(c(0.95, 0.05, 0.05, 0.95), 2, 2, byrow = TRUE),
               delta = c(0.5, 0.5),
               distn = "norm",
               pm = init)
  fit <- tryCatch(
    BaumWelch(hmm, control = bwcontrol(maxiter = 200, tol = 1e-5,
                                       prt = FALSE)),
    error = function(e) hmm)
  states <- Viterbi(fit)
  cur <- states[length(states)]
  pi_row <- fit$Pi[cur, ]
  step_mu <- sum(pi_row * fit$pm$mean)
  step_sd <- sqrt(sum(pi_row * (fit$pm$sd^2 + fit$pm$mean^2)) - step_mu^2)
  s0 <- prices[length(prices)]
  zq <- qnorm(1 - (1 - level) / 2)
  list(value       = s0 * exp(step_mu * horizon),
       lower_bound = s0 * exp(step_mu * horizon - zq * step_sd * sqrt(horizon)),
       upper_bound = s0 * exp(step_mu * horizon + zq * step_sd * sqrt(horizon)),
       certainty   = mean(states == cur))
}

# GARCH(1,1) volatility-path forecast via rugarch. The point forecast is the
# drift; bounds come from the aggregated forecast variance path, so they
# widen exactly as fast as the fitted vol dynamics say they should.
sim_garch <- function(prices, horizon, level = 0.90) {
  r <- diff(log(prices))
  spec <- ugarchspec(variance.model = list(model = "sGARCH",
                                           garchOrder = c(1, 1)),
                     mean.model = list(armaOrder = c(0, 0),
                                       include.mean = TRUE),
                     distribution.model = "std")
  fit <- tryCatch(
    ugarchfit(spec, r, solver = "hybrid"),
    error = function(e) NULL)
  s0 <- prices[length(prices)]
  if (is.null(fit) || fit@fit$convergence != 0) {
    # fall back to constant vol so the sim degrades instead of dying
    mu <- mean(r); sig <- sd(r) * sqrt(horizon)
    zq <- qnorm(1 - (1 - level) / 2)
    return(list(value = s0 * exp(mu * horizon),
                lower_bound = s0 * exp(mu * horizon - zq * sig),
                upper_bound = s0 * exp(mu * horizon + zq * sig),
                certainty = 0.2))
  }
  fc <- ugarchforecast(fit, n.ahead = horizon)
  mu_path <- as.numeric(fitted(fc))
  sig_path <- as.numeric(sigma(fc))
  mu_h <- sum(mu_path)
  sig_h <- sqrt(sum(sig_path^2))
  zq <- qnorm(1 - (1 - level) / 2)
  # persistence far from 1 = mean-reverting vol = more trustworthy band
  persistence <- sum(coef(fit)[c("alpha1", "beta1")])
  list(value       = s0 * exp(mu_h),
       lower_bound = s0 * exp(mu_h - zq * sig_h),
       upper_bound = s0 * exp(mu_h + zq * sig_h),
       certainty   = unname(pmax(0.05, pmin(0.95, 1 - persistence^4))))
}

# DCC-GARCH conditional correlation of target vs reference (rmgarch).
# Loaded lazily: rmgarch is heavy, and only this sim needs it.
sim_dcc <- function(prices, ref_prices, horizon, level = 0.90) {
  suppressMessages(library(rmgarch))
  rt <- diff(log(prices)); rr <- diff(log(ref_prices))
  n <- min(length(rt), length(rr))
  dat <- cbind(tail(rt, n), tail(rr, n))
  uspec <- ugarchspec(variance.model = list(model = "sGARCH",
                                            garchOrder = c(1, 1)),
                      mean.model = list(armaOrder = c(0, 0)))
  dspec <- dccspec(uspec = multispec(replicate(2, uspec)),
                   dccOrder = c(1, 1), distribution = "mvnorm")
  fit <- tryCatch(dccfit(dspec, data = dat), error = function(e) NULL)
  s0 <- prices[length(prices)]
  if (is.null(fit)) {
    rho <- cor(dat[, 1], dat[, 2])
  } else {
    fc <- dccforecast(fit, n.ahead = horizon)
    rho <- mean(rcor(fc)[[1]][1, 2, ])
  }
  # forecast: target drift conditioned on reference drift through rho
  mu_t <- mean(dat[, 1]); mu_r <- mean(dat[, 2])
  st <- sd(dat[, 1]); sr <- sd(dat[, 2])
  cond_mu <- (mu_t + rho * (st / sr) * mu_r) * horizon
  cond_sd <- st * sqrt(pmax(1 - rho^2, 1e-12)) * sqrt(horizon)
  zq <- qnorm(1 - (1 - level) / 2)
  list(value       = s0 * exp(cond_mu),
       lower_bound = s0 * exp(cond_mu - zq * cond_sd),
       upper_bound = s0 * exp(cond_mu + zq * cond_sd),
       certainty   = abs(rho))
}
