# copula.R — hand-rolled copula tail-dependence (M3a spec §3).
# Gaussian copula via empirical ranks + normal scores; lower/upper tail
# dependence estimated empirically. Used for cross-token contagion risk:
# given a reference token's move, how far does the target move with it?

# Empirical copula pseudo-observations.
.pobs <- function(x) rank(x, ties.method = "average") / (length(x) + 1)

# Pearson correlation of normal scores = Gaussian-copula rho.
copula_rho <- function(x, y) {
  cor(qnorm(.pobs(x)), qnorm(.pobs(y)))
}

# Empirical tail dependence at quantile q: P(V <= q | U <= q) (lower) and
# P(V > 1-q | U > 1-q) (upper).
copula_tails <- function(x, y, q = 0.05) {
  u <- .pobs(x); v <- .pobs(y)
  lo <- if (any(u <= q)) mean(v[u <= q] <= q) else 0
  hi <- if (any(u >= 1 - q)) mean(v[u >= 1 - q] >= 1 - q) else 0
  list(lower = lo, upper = hi)
}

# Conditional co-move forecast: if the reference asset shifts by ref_shift
# (log-return), the Gaussian copula conditional mean of the target's return
# is rho * (sigma_t / sigma_r) * ref_shift, with conditional sd
# sigma_t * sqrt(1 - rho^2). Returns a price band for the target.
sim_copula <- function(prices, ref_prices, horizon, ref_shift = NULL,
                       level = 0.90) {
  rt <- diff(log(prices)); rr <- diff(log(ref_prices))
  n <- min(length(rt), length(rr))
  rt <- tail(rt, n); rr <- tail(rr, n)
  rho <- copula_rho(rr, rt)
  if (is.null(ref_shift)) ref_shift <- mean(rr) * horizon
  st <- sd(rt); sr <- sd(rr)
  cond_mu <- mean(rt) * horizon + rho * (st / sr) * (ref_shift - mean(rr) * horizon)
  cond_sd <- st * sqrt(pmax(1 - rho^2, 1e-12)) * sqrt(horizon)
  s0 <- prices[length(prices)]
  zq <- qnorm(1 - (1 - level) / 2)
  tails <- copula_tails(rr, rt)
  list(value       = s0 * exp(cond_mu),
       lower_bound = s0 * exp(cond_mu - zq * cond_sd),
       upper_bound = s0 * exp(cond_mu + zq * cond_sd),
       certainty   = abs(rho) * (1 - abs(tails$lower - tails$upper)))
}
