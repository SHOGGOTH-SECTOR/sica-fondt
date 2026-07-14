#!/usr/bin/env Rscript
#
# M3a — Statistical & quantitative sims
# Language: R (native stats ecosystem)
# Protocol: line-delimited JSON on stdin/stdout to hub.tcl

# -- BoundedPrediction output ---------------------------------------------

bounded_prediction <- function(value, lower, upper, confidence,
                               horizon, sim_type = "statistical") {
  stopifnot(lower <= value, value <= upper)
  stopifnot(confidence >= 0.0, confidence <= 10.0)
  list(
    value       = value,
    lower_bound = lower,
    upper_bound = upper,
    confidence  = confidence,
    time_horizon = horizon,
    sim_type    = sim_type,
    timestamp   = as.numeric(Sys.time()) * 1000
  )
}

# -- Geometric Brownian Motion (Monte Carlo) -------------------------------

gbm_paths <- function(S0, mu, sigma, dt, n_steps, n_paths) {
  Z <- matrix(rnorm(n_steps * n_paths), nrow = n_steps)
  log_returns <- (mu - 0.5 * sigma^2) * dt + sigma * sqrt(dt) * Z
  S <- matrix(S0, nrow = n_steps + 1, ncol = n_paths)
  for (t in seq_len(n_steps)) {
    S[t + 1, ] <- S[t, ] * exp(log_returns[t, ])
  }
  S
}

gbm_predict <- function(S0, mu, sigma, horizon_hours, n_paths = 10000L) {
  dt <- 1 / (252 * 24)
  n_steps <- as.integer(horizon_hours)
  paths <- gbm_paths(S0, mu, sigma, dt, n_steps, n_paths)
  final <- paths[n_steps + 1, ]
  bounded_prediction(
    value  = median(final),
    lower  = quantile(final, 0.025, names = FALSE),
    upper  = quantile(final, 0.975, names = FALSE),
    confidence = 9.50,
    horizon = paste0(horizon_hours, "h")
  )
}

# -- Heston stochastic volatility -----------------------------------------
# dS = mu*S*dt + sqrt(nu)*S*dW^S
# dnu = kappa*(theta - nu)*dt + xi*sqrt(nu)*dW^nu
# corr(dW^S, dW^nu) = rho
# Euler-Maruyama with full truncation (nu >= 0)

heston_paths <- function(S0, nu0, mu, kappa, theta, xi, rho,
                         dt, n_steps, n_paths) {
  S  <- matrix(S0,  nrow = n_steps + 1, ncol = n_paths)
  nu <- matrix(nu0, nrow = n_steps + 1, ncol = n_paths)

  for (t in seq_len(n_steps)) {
    Z1 <- rnorm(n_paths)
    Z2 <- rho * Z1 + sqrt(1 - rho^2) * rnorm(n_paths)

    nu_pos <- pmax(nu[t, ], 0)
    sqrt_nu <- sqrt(nu_pos)

    nu[t + 1, ] <- pmax(
      nu[t, ] + kappa * (theta - nu_pos) * dt + xi * sqrt_nu * sqrt(dt) * Z1,
      0
    )
    S[t + 1, ] <- S[t, ] * exp(
      (mu - 0.5 * nu_pos) * dt + sqrt_nu * sqrt(dt) * Z2
    )
  }
  list(S = S, nu = nu)
}

heston_predict <- function(S0, nu0, mu, kappa, theta, xi, rho,
                           horizon_hours, n_paths = 5000L) {
  dt <- 1 / (252 * 24)
  n_steps <- as.integer(horizon_hours)
  result <- heston_paths(S0, nu0, mu, kappa, theta, xi, rho,
                         dt, n_steps, n_paths)
  final_S <- result$S[n_steps + 1, ]
  final_nu <- result$nu[n_steps + 1, ]

  price_pred <- bounded_prediction(
    value  = median(final_S),
    lower  = quantile(final_S, 0.025, names = FALSE),
    upper  = quantile(final_S, 0.975, names = FALSE),
    confidence = 9.00,
    horizon = paste0(horizon_hours, "h")
  )
  vol_pred <- bounded_prediction(
    value  = median(sqrt(final_nu)),
    lower  = quantile(sqrt(pmax(final_nu, 0)), 0.025, names = FALSE),
    upper  = quantile(sqrt(pmax(final_nu, 0)), 0.975, names = FALSE),
    confidence = 8.50,
    horizon = paste0(horizon_hours, "h")
  )
  list(price = price_pred, volatility = vol_pred)
}

# -- Merton jump-diffusion ------------------------------------------------
# dS = (mu - lambda*k)*S*dt + sigma*S*dW + S*dJ
# J ~ Poisson(lambda*dt), jump size ~ LogNormal(mu_j, sigma_j)

merton_paths <- function(S0, mu, sigma, lambda, mu_j, sigma_j,
                         dt, n_steps, n_paths) {
  S <- matrix(S0, nrow = n_steps + 1, ncol = n_paths)
  k <- exp(mu_j + 0.5 * sigma_j^2) - 1

  for (t in seq_len(n_steps)) {
    Z <- rnorm(n_paths)
    N_jumps <- rpois(n_paths, lambda * dt)
    J <- ifelse(N_jumps > 0,
                exp(rnorm(n_paths, mu_j * N_jumps, sigma_j * sqrt(N_jumps))),
                1)
    S[t + 1, ] <- S[t, ] * exp(
      (mu - lambda * k - 0.5 * sigma^2) * dt + sigma * sqrt(dt) * Z
    ) * J
  }
  S
}

# -- HMM regime detection (3-state: Bull, Neutral, Bear) ------------------
# r_t | s_t ~ N(mu_{s_t}, sigma_{s_t}^2)
# Forward algorithm for online filtering

hmm_states <- c("bull", "neutral", "bear")

hmm_filter <- function(returns, mu_vec, sigma_vec, trans_mat, init_prob) {
  n <- length(returns)
  K <- length(mu_vec)
  alpha <- matrix(0, nrow = n, ncol = K)

  emit <- dnorm(returns[1], mu_vec, sigma_vec)
  alpha[1, ] <- init_prob * emit
  alpha[1, ] <- alpha[1, ] / sum(alpha[1, ])

  for (t in 2:n) {
    emit <- dnorm(returns[t], mu_vec, sigma_vec)
    for (j in seq_len(K)) {
      alpha[t, j] <- emit[j] * sum(alpha[t - 1, ] * trans_mat[, j])
    }
    alpha[t, ] <- alpha[t, ] / sum(alpha[t, ])
  }
  alpha
}

hmm_current_regime <- function(returns, mu_vec, sigma_vec, trans_mat,
                               init_prob) {
  alpha <- hmm_filter(returns, mu_vec, sigma_vec, trans_mat, init_prob)
  last_row <- alpha[nrow(alpha), ]
  state_idx <- which.max(last_row)
  bounded_prediction(
    value  = state_idx,
    lower  = state_idx,
    upper  = state_idx,
    confidence = round(max(last_row) * 10, 2),
    horizon = "current"
  )
}

# -- GARCH(1,1) volatility ------------------------------------------------

garch11_fit <- function(returns) {
  n <- length(returns)
  omega <- var(returns) * 0.05
  alpha <- 0.10
  beta  <- 0.85
  sigma2 <- numeric(n)
  sigma2[1] <- var(returns)

  for (t in 2:n) {
    sigma2[t] <- omega + alpha * returns[t - 1]^2 + beta * sigma2[t - 1]
  }
  list(sigma2 = sigma2, omega = omega, alpha = alpha, beta = beta)
}

garch_predict <- function(returns, horizon_hours) {
  fit <- garch11_fit(returns)
  last_var <- tail(fit$sigma2, 1)
  unconditional_var <- fit$omega / (1 - fit$alpha - fit$beta)
  forecast_var <- numeric(horizon_hours)
  forecast_var[1] <- last_var

  for (h in 2:horizon_hours) {
    forecast_var[h] <- fit$omega +
      (fit$alpha + fit$beta) * forecast_var[h - 1]
  }

  vol <- sqrt(mean(forecast_var))
  bounded_prediction(
    value  = vol,
    lower  = vol * 0.7,
    upper  = vol * 1.4,
    confidence = 8.50,
    horizon = paste0(horizon_hours, "h")
  )
}

# -- Sim state (mutable, updated by ticks and calibration) -----------------

sim_state <- new.env(parent = emptyenv())
sim_state$params <- list(
  S0    = 1800,
  mu    = 0.05,
  sigma = 0.60,
  nu0   = 0.36,
  kappa = 2.0,
  theta = 0.36,
  xi    = 0.50,
  rho   = -0.70,
  lambda = 5.0,
  mu_j   = -0.02,
  sigma_j = 0.05,
  hmm_mu    = c(0.001, 0.0, -0.001),
  hmm_sigma = c(0.01, 0.015, 0.025),
  hmm_trans = matrix(c(
    0.95, 0.03, 0.02,
    0.05, 0.90, 0.05,
    0.02, 0.03, 0.95
  ), nrow = 3, byrow = TRUE),
  hmm_init = c(1/3, 1/3, 1/3)
)
sim_state$price_history <- numeric(0)
sim_state$tick_count <- 0L

# -- Self-test when run directly -------------------------------------------

if (!interactive() && identical(commandArgs(trailingOnly = TRUE), character(0))) {
  cat("M3a Statistical Sim — R", paste(R.version$major, R.version$minor, sep = "."), "\n")

  cat("\nGBM Monte Carlo (24h, 1000 paths):\n")
  bp <- gbm_predict(1800, 0.05, 0.60, 24, 1000L)
  cat(sprintf("  price: %.2f [%.2f, %.2f] confidence: %.2f/10.00\n",
              bp$value, bp$lower_bound, bp$upper_bound, bp$confidence))

  cat("\nHeston SV (24h, 1000 paths):\n")
  hp <- heston_predict(1800, 0.36, 0.05, 2.0, 0.36, 0.50, -0.70, 24, 1000L)
  cat(sprintf("  price: %.2f [%.2f, %.2f]\n",
              hp$price$value, hp$price$lower_bound, hp$price$upper_bound))
  cat(sprintf("  vol:   %.4f [%.4f, %.4f]\n",
              hp$volatility$value, hp$volatility$lower_bound,
              hp$volatility$upper_bound))

  cat("\nHMM regime (synthetic returns):\n")
  set.seed(42)
  returns <- c(rnorm(50, 0.001, 0.01), rnorm(50, -0.001, 0.025))
  rp <- hmm_current_regime(returns,
                           c(0.001, 0.0, -0.001),
                           c(0.01, 0.015, 0.025),
                           matrix(c(0.95,0.03,0.02,
                                    0.05,0.90,0.05,
                                    0.02,0.03,0.95), 3, byrow = TRUE),
                           c(1/3, 1/3, 1/3))
  cat(sprintf("  regime: %s (confidence: %.2f/10.00)\n",
              hmm_states[rp$value], rp$confidence))

  cat("\nGARCH(1,1) vol forecast:\n")
  gp <- garch_predict(returns, 24)
  cat(sprintf("  vol: %.6f [%.6f, %.6f]\n",
              gp$value, gp$lower_bound, gp$upper_bound))

  cat("\nMerton jump-diffusion (24h, 1000 paths):\n")
  set.seed(42)
  mp <- merton_paths(1800, 0.05, 0.60, 5.0, -0.02, 0.05, 1/(252*24), 24, 1000L)
  final <- mp[25, ]
  cat(sprintf("  median: %.2f [%.2f, %.2f]\n",
              median(final), quantile(final, 0.025), quantile(final, 0.975)))

  cat("\nAll models operational.\n")
}
