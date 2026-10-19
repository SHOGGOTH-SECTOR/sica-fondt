args <- commandArgs(trailingOnly=FALSE)
f <- sub("^--file=", "", args[grep("^--file=", args)])
source(file.path(dirname(normalizePath(f)), "engine.R"))

near <- function(x, y, tol) abs(x-y) <= tol

# Existing stochastic kernels -------------------------------------------------
x <- gbm_terminal(100,0.05,0.2,1/252,252,20000,7)
expected <- 100*exp(0.05)
stopifnot(abs(mean(x)-expected)/expected < 0.02)

j <- merton_terminal(100,0.05,0.15,2,-0.08,0.15,1/252,252,10000,9)
kurtosis <- mean((j-mean(j))^4)/(var(j)^2)
stopifnot(kurtosis > 3)

h <- heston_terminal(100,0.04,0.03,2,0.04,0.3,-0.6,1/252,252,5000,3)
stopifnot(all(h > 0))

set.seed(12)
r <- c(rnorm(100,0,.01), rnorm(100,0,.05))
fit <- garch11_fit(r)
stopifnot(fit$alpha >= 0, fit$beta >= 0, fit$alpha+fit$beta < 1)
stopifnot(length(fit$variance) == length(r))
stopifnot(all(fit$variance > 0))

p <- bounded_price_prediction(100,.03,.2,1/365,30,5000,4,"30d","TEST")
stopifnot(p$lower_bound <= p$value, p$value <= p$upper_bound)

# HMM regime filter -----------------------------------------------------------
set.seed(40)
regime_returns <- c(
  rnorm(160,-0.012,0.006),
  rnorm(160, 0.000,0.004),
  rnorm(160, 0.012,0.006)
)
hmm <- hmm3_fit(regime_returns, max_iter=40, tol=1e-6)
path <- hmm3_viterbi(regime_returns, hmm)
stopifnot(identical(sort(names(hmm$state_mean)), c("bear","bull","neutral")))
stopifnot(mean(path[1:140] == "bear") > 0.70)
stopifnot(mean(path[181:300] == "neutral") > 0.60)
stopifnot(mean(path[341:480] == "bull") > 0.70)
stopifnot(all(abs(rowSums(hmm$transition)-1) < 1e-8))

# Rough-vol / Hurst estimation ------------------------------------------------
set.seed(41)
brownian <- cumsum(rnorm(2048))
H <- hurst_variogram(brownian)
stopifnot(is.finite(H), H > 0.30, H < 0.70)

rv <- exp(arima.sim(model=list(ar=-0.55), n=800, sd=0.2))
rough <- rough_vol_state(rv)
stopifnot(rough$hurst > 0.01, rough$hurst < 0.80)
stopifnot(rough$forecast_variance > 0)

# Cross-asset DCC and t-copula tail dependence -------------------------------
set.seed(42)
n <- 700
z1 <- rnorm(n)
rho <- c(rep(0.10,350),rep(0.85,350))
z2 <- rho*z1 + sqrt(1-rho^2)*rnorm(n)
dcc <- dcc_fit(cbind(z1,z2), a=0.03, b=0.94)
stopifnot(length(dcc$correlation) == n)
stopifnot(mean(dcc$correlation[500:700]) > mean(dcc$correlation[50:250]) + 0.15)
td_lo <- t_copula_tail_dependence(0.2, 6)
td_hi <- t_copula_tail_dependence(0.8, 6)
stopifnot(td_hi > td_lo, td_lo >= 0, td_hi <= 1)

# Bayesian calibration + AR forecast -----------------------------------------
set.seed(43)
prior <- normal_inverse_gamma_prior(mu=0, kappa=1, alpha=2, beta=0.001)
post_pos <- bayes_return_update(prior, rnorm(300,0.01,0.02))
post_neg <- bayes_return_update(prior, rnorm(300,-0.01,0.02))
stopifnot(post_pos$mu > 0, post_neg$mu < 0)
stopifnot(post_pos$alpha > prior$alpha, post_pos$beta > 0)

ar_data <- as.numeric(arima.sim(model=list(ar=0.75), n=500, sd=0.01))
arf <- arima_forecast_base(ar_data, horizon=5)
stopifnot(length(arf$mean) == 5, length(arf$sd) == 5)
stopifnot(all(is.finite(arf$mean)), all(arf$sd >= 0))

# Risk measures ---------------------------------------------------------------
set.seed(44)
risk_returns <- rt(5000, df=5) * 0.02
risk <- historical_var_es(risk_returns, alpha=0.99)
stopifnot(risk$var > 0, risk$expected_shortfall >= risk$var)

# Jump + Heston calibration proxies ------------------------------------------
set.seed(45)
plain <- rnorm(1000,0,0.01)
jumpy <- plain
jumpy[seq(50,1000,by=100)] <- jumpy[seq(50,1000,by=100)] - 0.10
ji_plain <- estimate_jump_intensity(plain)
ji_jump <- estimate_jump_intensity(jumpy)
stopifnot(ji_jump$lambda > ji_plain$lambda)

prices_proxy <- 100*exp(cumsum(rnorm(1000,0,0.01)))
hp <- fit_heston_proxy(prices_proxy, window=24)
stopifnot(hp$v0 > 0, hp$theta > 0, hp$kappa >= 0, hp$xi >= 0, abs(hp$rho) <= 1)

# Full calibration and six concurrent horizons -------------------------------
set.seed(46)
returns <- c(
  rnorm(500,0.0004,0.012),
  rnorm(400,-0.0002,0.025)
)
prices <- 100*exp(cumsum(returns))
state <- calibrate_market(prices, dt=1/365, ticker="TEST")
stopifnot(state$spot > 0)
stopifnot(state$garch$alpha + state$garch$beta < 1)
stopifnot(state$rough$hurst > 0, state$rough$hurst < 1)
stopifnot(state$heston$theta > 0)
stopifnot(state$jump$lambda >= 0)
stopifnot(state$regime %in% c("bear","neutral","bull"))

forecasts <- forecast_all_horizons(state, paths=2500, seed=90)
expected_horizons <- c("tick_hourly","daily","weekly","monthly","annual","five_year")
stopifnot(identical(names(forecasts), expected_horizons))
for (name in names(forecasts)) {
  q <- forecasts[[name]]
  stopifnot(q$lower_bound <= q$value, q$value <= q$upper_bound)
  stopifnot(q$confidence >= 0, q$confidence <= 10)
  stopifnot(q$correctness >= 0, q$correctness <= 10)
  stopifnot(q$certainty >= 0, q$certainty <= 10)
  stopifnot(q$sim_type == "statistical")
  stopifnot(q$token_ticker == "TEST")
}

# DCC accepts calibrated GARCH residuals from a return matrix -----------------
set.seed(47)
m <- cbind(
  rnorm(450,0,0.015),
  0.6*rnorm(450,0,0.015) + 0.4*rnorm(450,0,0.015),
  rnorm(450,0,0.020)
)
cross <- calibrate_cross_asset(m)
stopifnot(all(dim(cross$last_correlation) == c(3,3)))
stopifnot(max(abs(diag(cross$last_correlation)-1)) < 1e-10)
stopifnot(max(abs(cross$last_correlation-t(cross$last_correlation))) < 1e-10)

cat("STATISTICAL TESTS PASSED\n")
