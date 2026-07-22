# sde_sims.R — hand-rolled stochastic simulations (M3a spec §3).
# GBM Monte Carlo, Heston (Euler–Maruyama with full truncation), Merton
# jump-diffusion, fBM via Wood & Chan circulant embedding on base fft().
# Each sim returns list(value, lower_bound, upper_bound, certainty) for a
# price forecast `horizon` steps ahead, from a log-price history.

.log_returns <- function(prices) diff(log(prices))

# Geometric Brownian motion: mu/sigma estimated from history, terminal
# distribution is lognormal so quantiles are closed-form; MC paths give the
# certainty estimate (dispersion-based).
sim_gbm <- function(prices, horizon, n_paths = 5000L, level = 0.90) {
  r <- .log_returns(prices)
  mu <- mean(r); sigma <- sd(r)
  s0 <- prices[length(prices)]
  z <- matrix(rnorm(n_paths * horizon), n_paths, horizon)
  paths <- s0 * exp(t(apply((mu - sigma^2 / 2) + sigma * z, 1, cumsum)))
  terminal <- paths[, horizon]
  a <- (1 - level) / 2
  list(value       = median(terminal),
       lower_bound = unname(quantile(terminal, a)),
       upper_bound = unname(quantile(terminal, 1 - a)),
       certainty   = .dispersion_certainty(terminal, s0))
}

# Heston stochastic volatility, Euler–Maruyama with full truncation for the
# variance process (v is floored inside the drift/diffusion, not clamped
# after, which avoids the classical bias at low kappa*theta).
sim_heston <- function(prices, horizon, n_paths = 5000L, level = 0.90,
                       kappa = 2.0, rho = -0.7) {
  r <- .log_returns(prices)
  mu <- mean(r)
  theta <- var(r)                      # long-run variance
  v0 <- .ewma_var(r)                   # spot variance
  xi <- sd((r - mean(r))^2) * sqrt(2)  # crude vol-of-vol from squared returns
  s0 <- prices[length(prices)]

  s <- rep(log(s0), n_paths)
  v <- rep(v0, n_paths)
  for (t in seq_len(horizon)) {
    z1 <- rnorm(n_paths)
    z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n_paths)
    vp <- pmax(v, 0)
    s <- s + (mu - vp / 2) + sqrt(vp) * z1
    v <- v + kappa * (theta - vp) + xi * sqrt(vp) * z2
  }
  terminal <- exp(s)
  a <- (1 - level) / 2
  list(value       = median(terminal),
       lower_bound = unname(quantile(terminal, a)),
       upper_bound = unname(quantile(terminal, 1 - a)),
       certainty   = .dispersion_certainty(terminal, s0))
}

# Merton jump-diffusion: jumps detected as |return| > 3 sd of the
# jump-cleaned series (iterated once); Poisson arrivals, lognormal sizes.
sim_jump_diffusion <- function(prices, horizon, n_paths = 5000L, level = 0.90) {
  r <- .log_returns(prices)
  thresh <- 3 * sd(r)
  jumps <- abs(r - mean(r)) > thresh
  diffusive <- r[!jumps]
  mu <- mean(diffusive); sigma <- sd(diffusive)
  lambda <- max(sum(jumps) / length(r), 1e-6)   # jumps per step
  jump_mu <- if (any(jumps)) mean(r[jumps]) else 0
  jump_sd <- if (sum(jumps) > 1) sd(r[jumps]) else sigma
  s0 <- prices[length(prices)]

  logret <- matrix(rnorm(n_paths * horizon, mu - sigma^2 / 2, sigma),
                   n_paths, horizon)
  n_jumps <- matrix(rpois(n_paths * horizon, lambda), n_paths, horizon)
  jump_part <- matrix(rnorm(n_paths * horizon,
                            n_jumps * jump_mu,
                            sqrt(pmax(n_jumps, 1e-12)) * jump_sd),
                      n_paths, horizon)
  jump_part[n_jumps == 0] <- 0
  terminal <- s0 * exp(rowSums(logret + jump_part))
  a <- (1 - level) / 2
  list(value       = median(terminal),
       lower_bound = unname(quantile(terminal, a)),
       upper_bound = unname(quantile(terminal, 1 - a)),
       certainty   = .dispersion_certainty(terminal, s0))
}

# Fractional Brownian motion increments (fGn) by Wood & Chan (1994)
# circulant embedding: exact in distribution, O(n log n) via fft. Hurst
# exponent estimated from history by aggregated-variance slope.
sim_fbm <- function(prices, horizon, n_paths = 2000L, level = 0.90) {
  r <- .log_returns(prices)
  H <- .hurst_aggvar(r)
  sigma <- sd(r); mu <- mean(r)
  s0 <- prices[length(prices)]

  n <- horizon
  # fGn autocovariance gamma(k), circulant embedding of size 2m
  k <- 0:n
  gam <- 0.5 * (abs(k - 1)^(2 * H) - 2 * abs(k)^(2 * H) + abs(k + 1)^(2 * H))
  circ <- c(gam, rev(gam[2:n]))          # length 2n
  lam <- Re(fft(circ))
  lam[lam < 0] <- 0                      # numerical guard; embedding may fail
  m2 <- length(circ)

  terminal <- numeric(n_paths)
  for (p in seq_len(n_paths)) {
    zr <- rnorm(m2); zi <- rnorm(m2)
    w <- fft(sqrt(lam / m2) * complex(real = zr, imaginary = zi),
             inverse = FALSE)
    fgn <- Re(w)[1:n] * sigma
    terminal[p] <- s0 * exp(sum(mu + fgn))
  }
  a <- (1 - level) / 2
  list(value       = median(terminal),
       lower_bound = unname(quantile(terminal, a)),
       upper_bound = unname(quantile(terminal, 1 - a)),
       certainty   = .dispersion_certainty(terminal, s0) *
                     (1 - abs(H - 0.5)))  # discount when H estimate is extreme
}

# --- shared estimators ------------------------------------------------------

.ewma_var <- function(r, lambda = 0.94) {
  v <- var(r)
  for (x in r) v <- lambda * v + (1 - lambda) * x^2
  v
}

.hurst_aggvar <- function(r, max_scale = 16L) {
  scales <- 2^(1:floor(log2(min(max_scale, length(r) / 4))))
  if (length(scales) < 2) return(0.5)
  vars <- vapply(scales, function(m) {
    k <- floor(length(r) / m)
    var(colMeans(matrix(r[1:(k * m)], m, k)))
  }, numeric(1))
  slope <- coef(lm(log(vars) ~ log(scales)))[2]
  h <- 1 + slope / 2
  min(max(h, 0.05), 0.95)
}

# Map MC dispersion into (0,1]: tight terminal distribution relative to the
# spot price = high certainty. Purely internal to M3a; the Hub calibrates.
.dispersion_certainty <- function(terminal, s0) {
  spread <- IQR(terminal) / s0
  unname(1 / (1 + 5 * spread))
}
