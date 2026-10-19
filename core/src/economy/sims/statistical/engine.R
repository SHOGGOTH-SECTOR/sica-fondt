# M3a statistical simulator kernels. Base R only; no Python bridge.
clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))

gbm_terminal <- function(s0, mu, sigma, dt, steps, paths, seed=1L) {
  stopifnot(s0 > 0, sigma >= 0, dt > 0, steps >= 1, paths >= 2)
  set.seed(seed)
  z <- matrix(rnorm(steps * paths), nrow=steps)
  lr <- (mu - 0.5 * sigma^2) * dt + sigma * sqrt(dt) * z
  s0 * exp(colSums(lr))
}

merton_terminal <- function(s0, mu, sigma, lambda, jump_mu, jump_sigma, dt, steps, paths, seed=1L) {
  stopifnot(lambda >= 0, jump_sigma >= 0)
  set.seed(seed)
  z <- matrix(rnorm(steps * paths), nrow=steps)
  n <- matrix(rpois(steps * paths, lambda * dt), nrow=steps)
  jumps <- matrix(rnorm(steps * paths, jump_mu, jump_sigma), nrow=steps) * n
  drift <- (mu - 0.5*sigma^2 - lambda*(exp(jump_mu + 0.5*jump_sigma^2)-1)) * dt
  s0 * exp(colSums(drift + sigma*sqrt(dt)*z + jumps))
}

heston_terminal <- function(s0, v0, mu, kappa, theta, xi, rho, dt, steps, paths, seed=1L) {
  stopifnot(s0 > 0, v0 >= 0, kappa >= 0, theta >= 0, xi >= 0, abs(rho) <= 1)
  set.seed(seed); s <- rep(s0, paths); v <- rep(v0, paths)
  for (i in seq_len(steps)) {
    z1 <- rnorm(paths); z2 <- rho*z1 + sqrt(max(0, 1-rho^2))*rnorm(paths)
    vp <- pmax(v, 0)
    s <- s * exp((mu - 0.5*vp)*dt + sqrt(vp*dt)*z1)
    v <- pmax(v + kappa*(theta-vp)*dt + xi*sqrt(vp*dt)*z2, 0)
  }
  s
}

garch11_fit <- function(r) {
  r <- as.numeric(r); stopifnot(length(r) >= 20)
  v0 <- var(r)
  nll <- function(p) {
    omega <- exp(p[1]); alpha <- plogis(p[2]); beta <- plogis(p[3])*(1-alpha)
    h <- numeric(length(r)); h[1] <- max(v0, 1e-12)
    for (i in 2:length(r)) h[i] <- max(1e-12, omega + alpha*r[i-1]^2 + beta*h[i-1])
    0.5*sum(log(h) + r^2/h)
  }
  opt <- optim(c(log(max(v0*0.05,1e-12)), qlogis(0.1), qlogis(0.85/0.9)), nll)
  alpha <- plogis(opt$par[2]); beta <- plogis(opt$par[3])*(1-alpha)
  list(omega=exp(opt$par[1]), alpha=alpha, beta=beta)
}

hurst_rs <- function(x) {
  x <- as.numeric(x); n <- length(x); stopifnot(n >= 32)
  scales <- c(4,8,16,32); scales <- scales[scales <= n/2]
  rs <- sapply(scales, function(m) {
    chunks <- split(x[seq_len(floor(n/m)*m)], rep(seq_len(floor(n/m)), each=m))
    vals <- sapply(chunks, function(y) { z <- cumsum(y-mean(y)); sdv <- sd(y); if (sdv==0) NA else (max(z)-min(z))/sdv })
    mean(vals, na.rm=TRUE)
  })
  unname(coef(lm(log(rs) ~ log(scales)))[2])
}

regime_state <- function(returns) {
  m <- mean(returns); s <- sd(returns)
  if (!is.finite(s) || s == 0) return("neutral")
  if (m > 0.25*s) "bull" else if (m < -0.25*s) "bear" else "neutral"
}

bounded_price_prediction <- function(s0, mu, sigma, dt, steps, paths=4000L, seed=1L, horizon="24h", ticker="ASSET") {
  sims <- gbm_terminal(s0, mu, sigma, dt, steps, paths, seed)
  q <- as.numeric(quantile(sims, c(.025,.5,.975), names=FALSE))
  width <- (q[3]-q[1])/max(q[2],1e-12)
  list(value=q[2], lower_bound=q[1], upper_bound=q[3], confidence=clamp(10-5*width,0,10), correctness=5, certainty=clamp(10-8*width,0,10), time_horizon=horizon, sim_type="statistical", token_ticker=ticker, recent_shift=0)
}

json_number <- function(line, key, default) {
  pat <- paste0('"', key, '"[[:space:]]*:[[:space:]]*(-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)')
  m <- regexec(pat, line, perl=TRUE); z <- regmatches(line,m)[[1]]
  if (length(z) < 2) default else as.numeric(z[2])
}
json_string <- function(line, key, default) {
  pat <- paste0('"', key, '"[[:space:]]*:[[:space:]]*"([^"]*)"')
  m <- regexec(pat, line, perl=TRUE); z <- regmatches(line,m)[[1]]
  if (length(z) < 2) default else z[2]
}
emit_prediction <- function(p) {
  cat(sprintf('{"value":%.10g,"lower_bound":%.10g,"upper_bound":%.10g,"confidence":%.4f,"correctness":%.4f,"certainty":%.4f,"time_horizon":"%s","sim_type":"statistical","token_ticker":"%s","recent_shift":%.10g}\n', p$value,p$lower_bound,p$upper_bound,p$confidence,p$correctness,p$certainty,p$time_horizon,p$token_ticker,p$recent_shift))
}
main <- function() {
  line <- readLines(file("stdin"), n=1, warn=FALSE)
  if (!length(line)) quit(status=2)
  p <- bounded_price_prediction(json_number(line,"spot",100), json_number(line,"mu",0), json_number(line,"sigma",0.2), json_number(line,"dt",1/365), as.integer(json_number(line,"steps",1)), as.integer(json_number(line,"paths",4000)), as.integer(json_number(line,"seed",1)), json_string(line,"time_horizon","24h"), json_string(line,"token_ticker","ASSET"))
  emit_prediction(p)
}
if (sys.nframe() == 0) main()
