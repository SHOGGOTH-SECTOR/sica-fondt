# M3a statistical & quantitative simulator.
# Base R only: no Python bridge and no runtime dependency on CRAN packages.
# The heavier CRAN stack in the design remains optional acceleration/validation.

clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))
eps <- 1e-12

safe_sd <- function(x, floor=1e-8) {
  s <- sd(as.numeric(x))
  if (!is.finite(s) || s < floor) floor else s
}

normalize_prob <- function(x) {
  x <- pmax(as.numeric(x), 1e-300)
  x / sum(x)
}

returns_from_prices <- function(prices) {
  prices <- as.numeric(prices)
  stopifnot(length(prices) >= 3, all(is.finite(prices)), all(prices > 0))
  diff(log(prices))
}

# --- Monte Carlo price kernels ---------------------------------------------

gbm_terminal <- function(s0, mu, sigma, dt, steps, paths, seed=1L) {
  stopifnot(s0 > 0, sigma >= 0, dt > 0, steps >= 1, paths >= 2)
  set.seed(seed)
  z <- matrix(rnorm(steps * paths), nrow=steps)
  lr <- (mu - 0.5 * sigma^2) * dt + sigma * sqrt(dt) * z
  s0 * exp(colSums(lr))
}

merton_terminal <- function(s0, mu, sigma, lambda, jump_mu, jump_sigma,
                            dt, steps, paths, seed=1L) {
  stopifnot(s0 > 0, sigma >= 0, lambda >= 0, jump_sigma >= 0,
            dt > 0, steps >= 1, paths >= 2)
  set.seed(seed)
  z <- matrix(rnorm(steps * paths), nrow=steps)
  n <- matrix(rpois(steps * paths, lambda * dt), nrow=steps)
  jump_z <- matrix(rnorm(steps * paths), nrow=steps)
  jumps <- n * jump_mu + sqrt(pmax(n, 0)) * jump_sigma * jump_z
  compensator <- lambda * (exp(jump_mu + 0.5 * jump_sigma^2) - 1)
  drift <- (mu - 0.5*sigma^2 - compensator) * dt
  s0 * exp(colSums(drift + sigma*sqrt(dt)*z + jumps))
}

heston_terminal <- function(s0, v0, mu, kappa, theta, xi, rho,
                            dt, steps, paths, seed=1L) {
  stopifnot(s0 > 0, v0 >= 0, kappa >= 0, theta >= 0, xi >= 0,
            abs(rho) <= 1, dt > 0, steps >= 1, paths >= 2)
  set.seed(seed)
  s <- rep(s0, paths)
  v <- rep(v0, paths)
  for (i in seq_len(steps)) {
    z1 <- rnorm(paths)
    z2 <- rho*z1 + sqrt(max(0, 1-rho^2))*rnorm(paths)
    vp <- pmax(v, 0)
    s <- s * exp((mu - 0.5*vp)*dt + sqrt(vp*dt)*z1)
    v <- pmax(v + kappa*(theta-vp)*dt + xi*sqrt(vp*dt)*z2, 0)
  }
  s
}

# --- GARCH -----------------------------------------------------------------

garch11_filter <- function(r, omega, alpha, beta, mean_return=mean(r)) {
  r <- as.numeric(r)
  e <- r - mean_return
  h <- numeric(length(r))
  h[1] <- max(var(e), eps)
  if (length(r) >= 2) {
    for (i in 2:length(r)) {
      h[i] <- max(eps, omega + alpha*e[i-1]^2 + beta*h[i-1])
    }
  }
  h
}

garch11_fit <- function(r) {
  r <- as.numeric(r)
  stopifnot(length(r) >= 20, all(is.finite(r)))
  mean_return <- mean(r)
  e <- r - mean_return
  v0 <- max(var(e), 1e-10)

  unpack <- function(p) {
    alpha <- 0.98 * plogis(p[2])
    beta <- (0.999 - alpha) * plogis(p[3])
    c(omega=exp(p[1]), alpha=alpha, beta=beta)
  }

  nll <- function(p) {
    q <- unpack(p)
    h <- garch11_filter(r, q["omega"], q["alpha"], q["beta"], mean_return)
    0.5 * sum(log(2*pi) + log(h) + e^2/h)
  }

  init_alpha <- 0.08
  init_beta <- 0.88
  init <- c(
    log(max(v0 * (1-init_alpha-init_beta), 1e-12)),
    qlogis(init_alpha/0.98),
    qlogis(init_beta/(0.999-init_alpha))
  )
  opt <- tryCatch(optim(init, nll, method="BFGS", control=list(maxit=500)),
                  error=function(e) NULL)
  if (is.null(opt) || !is.finite(opt$value)) {
    q <- c(omega=max(v0*0.04,1e-12), alpha=0.08, beta=0.88)
    convergence <- 1L
  } else {
    q <- unpack(opt$par)
    convergence <- opt$convergence
  }
  h <- garch11_filter(r, q["omega"], q["alpha"], q["beta"], mean_return)
  list(
    omega=unname(q["omega"]),
    alpha=unname(q["alpha"]),
    beta=unname(q["beta"]),
    mean=mean_return,
    variance=h,
    sigma=sqrt(h),
    standardized=(r-mean_return)/sqrt(h),
    convergence=convergence
  )
}

garch11_forecast <- function(fit, last_return, steps=1L) {
  stopifnot(steps >= 1)
  out <- numeric(steps)
  h <- tail(fit$variance, 1)
  e2 <- (last_return-fit$mean)^2
  for (i in seq_len(steps)) {
    h <- fit$omega + fit$alpha*e2 + fit$beta*h
    out[i] <- max(h, eps)
    e2 <- h
  }
  out
}

# --- Three-state Gaussian HMM ----------------------------------------------

hmm_forward_backward <- function(x, initial, transition, state_mean, state_sd) {
  x <- as.numeric(x)
  n <- length(x)
  k <- length(state_mean)
  emission <- sapply(seq_len(k), function(j) {
    pmax(dnorm(x, mean=state_mean[j], sd=max(state_sd[j],1e-8)), 1e-300)
  })
  if (k == 1) emission <- matrix(emission, ncol=1)

  forward <- matrix(0, n, k)
  scale <- numeric(n)
  forward[1,] <- initial * emission[1,]
  scale[1] <- max(sum(forward[1,]), 1e-300)
  forward[1,] <- forward[1,] / scale[1]

  if (n >= 2) {
    for (t in 2:n) {
      forward[t,] <- as.numeric(forward[t-1,] %*% transition) * emission[t,]
      scale[t] <- max(sum(forward[t,]), 1e-300)
      forward[t,] <- forward[t,] / scale[t]
    }
  }

  backward <- matrix(1, n, k)
  if (n >= 2) {
    for (t in (n-1):1) {
      backward[t,] <- as.numeric(
        transition %*% (emission[t+1,] * backward[t+1,])
      ) / scale[t+1]
    }
  }

  gamma <- forward * backward
  gamma <- gamma / rowSums(gamma)

  xi_sum <- matrix(0, k, k)
  if (n >= 2) {
    for (t in 1:(n-1)) {
      xi <- transition * outer(
        forward[t,],
        emission[t+1,] * backward[t+1,]
      )
      den <- sum(xi)
      if (den > 0) xi_sum <- xi_sum + xi/den
    }
  }

  list(
    emission=emission,
    forward=forward,
    backward=backward,
    posterior=gamma,
    xi_sum=xi_sum,
    loglik=sum(log(scale))
  )
}

hmm3_fit <- function(returns, max_iter=80L, tol=1e-7) {
  x <- as.numeric(returns)
  stopifnot(length(x) >= 60, all(is.finite(x)))
  state_names <- c("bear","neutral","bull")
  state_mean <- as.numeric(quantile(x, c(0.15,0.50,0.85), names=FALSE))
  base_sd <- safe_sd(x)
  state_sd <- rep(base_sd, 3)
  initial <- rep(1/3, 3)
  transition <- matrix(0.015, 3, 3)
  diag(transition) <- 0.97
  previous_ll <- -Inf

  for (iter in seq_len(max_iter)) {
    fb <- hmm_forward_backward(x, initial, transition, state_mean, state_sd)
    w <- colSums(fb$posterior)
    initial <- normalize_prob(fb$posterior[1,])

    transition <- fb$xi_sum
    transition <- transition / pmax(rowSums(transition), 1e-300)
    transition[!is.finite(transition)] <- 1/3
    transition <- t(apply(transition, 1, normalize_prob))

    new_mean <- colSums(fb$posterior * x) / pmax(w, 1e-12)
    new_sd <- numeric(3)
    for (j in 1:3) {
      new_sd[j] <- sqrt(
        sum(fb$posterior[,j] * (x-new_mean[j])^2) / max(w[j],1e-12)
      )
    }
    state_mean <- new_mean
    state_sd <- pmax(new_sd, base_sd*0.05, 1e-8)

    ord <- order(state_mean)
    state_mean <- state_mean[ord]
    state_sd <- state_sd[ord]
    initial <- initial[ord]
    transition <- transition[ord,ord,drop=FALSE]

    if (is.finite(previous_ll) && abs(fb$loglik-previous_ll) < tol) break
    previous_ll <- fb$loglik
  }

  fb <- hmm_forward_backward(x, initial, transition, state_mean, state_sd)
  names(state_mean) <- state_names
  names(state_sd) <- state_names
  names(initial) <- state_names
  dimnames(transition) <- list(state_names,state_names)
  colnames(fb$posterior) <- state_names

  list(
    initial=initial,
    transition=transition,
    state_mean=state_mean,
    state_sd=state_sd,
    posterior=fb$posterior,
    loglik=fb$loglik
  )
}

hmm3_viterbi <- function(returns, model) {
  x <- as.numeric(returns)
  names_state <- names(model$state_mean)
  k <- length(names_state)
  n <- length(x)
  log_trans <- log(pmax(model$transition,1e-300))
  log_initial <- log(pmax(model$initial,1e-300))
  emit <- sapply(seq_len(k), function(j) {
    dnorm(x, model$state_mean[j], model$state_sd[j], log=TRUE)
  })
  if (k == 1) emit <- matrix(emit,ncol=1)

  delta <- matrix(-Inf,n,k)
  psi <- matrix(1L,n,k)
  delta[1,] <- log_initial + emit[1,]
  if (n >= 2) {
    for (t in 2:n) {
      for (j in seq_len(k)) {
        candidate <- delta[t-1,] + log_trans[,j]
        psi[t,j] <- which.max(candidate)
        delta[t,j] <- max(candidate) + emit[t,j]
      }
    }
  }
  path <- integer(n)
  path[n] <- which.max(delta[n,])
  if (n >= 2) {
    for (t in (n-1):1) path[t] <- psi[t+1,path[t+1]]
  }
  names_state[path]
}

regime_state <- function(returns) {
  x <- as.numeric(returns)
  if (length(x) < 60) {
    m <- mean(x)
    s <- safe_sd(x)
    if (m > 0.25*s) "bull" else if (m < -0.25*s) "bear" else "neutral"
  } else {
    model <- hmm3_fit(x)
    tail(hmm3_viterbi(x,model),1)
  }
}

# --- Rough volatility -------------------------------------------------------

hurst_variogram <- function(x, max_lag=NULL) {
  x <- as.numeric(x)
  n <- length(x)
  stopifnot(n >= 32, all(is.finite(x)))
  if (is.null(max_lag)) max_lag <- min(64L, floor(n/8))
  max_lag <- max(4L, min(as.integer(max_lag), floor(n/3)))
  raw_lags <- unique(as.integer(round(exp(seq(log(1),log(max_lag),length.out=12)))))
  lags <- raw_lags[raw_lags >= 1 & raw_lags < n]
  variogram <- sapply(lags, function(lag) {
    mean((x[(lag+1):n] - x[1:(n-lag)])^2)
  })
  keep <- is.finite(variogram) & variogram > 0
  if (sum(keep) < 3) return(0.5)
  slope <- unname(coef(lm(log(variogram[keep]) ~ log(lags[keep])))[2])
  clamp(slope/2, 0.02, 0.98)
}

hurst_rs <- function(x) {
  # Kept for API compatibility; variogram estimator is more appropriate for
  # the realized-variance rough-vol path used by M3a.
  hurst_variogram(cumsum(as.numeric(x)-mean(x)))
}

fgn_davies_harte <- function(n, H, seed=1L) {
  n <- as.integer(n)
  stopifnot(n >= 1, H > 0, H < 1)
  if (n == 1) {
    set.seed(seed)
    return(rnorm(1))
  }
  k <- 0:n
  gamma <- 0.5 * (
    abs(k-1)^(2*H) - 2*abs(k)^(2*H) + abs(k+1)^(2*H)
  )
  circulant <- c(gamma, rev(gamma[2:n]))
  lambda <- Re(fft(circulant))
  if (min(lambda) < -1e-8) stop("davies_harte_negative_eigenvalue")
  lambda <- pmax(lambda,0)

  set.seed(seed)
  w <- complex(length=2*n)
  w[1] <- sqrt(lambda[1]/(2*n))*rnorm(1)
  w[n+1] <- sqrt(lambda[n+1]/(2*n))*rnorm(1)
  if (n > 1) {
    for (j in 2:n) {
      z <- rnorm(2)
      w[j] <- sqrt(lambda[j]/(4*n)) * (z[1] + 1i*z[2])
      mirror <- 2*n-j+2
      w[mirror] <- Conj(w[j])
    }
  }
  Re(fft(w))[1:n]
}

rough_vol_terminal <- function(s0, mu, v0, H, eta, dt, steps, paths, seed=1L) {
  stopifnot(
    s0 > 0, v0 > 0, H > 0, H < 1, eta >= 0,
    dt > 0, steps >= 1, paths >= 2
  )
  steps <- as.integer(steps)
  paths <- as.integer(paths)
  terminal <- numeric(paths)
  for (p in seq_len(paths)) {
    fgn <- fgn_davies_harte(steps,H,seed+p-1L)
    set.seed(seed+100000L+p)
    price_noise <- rnorm(steps)
    logv <- log(v0)
    logp <- log(s0)
    for (i in seq_len(steps)) {
      logv <- logv + eta*(dt^H)*fgn[i]
      v <- max(exp(logv),eps)
      logp <- logp + (mu-0.5*v)*dt + sqrt(v*dt)*price_noise[i]
    }
    terminal[p] <- exp(logp)
  }
  terminal
}

realized_variance <- function(returns, window=24L) {
  x <- as.numeric(returns)
  stopifnot(window >= 2, length(x) >= window)
  idx <- window:length(x)
  vapply(idx, function(i) mean(x[(i-window+1):i]^2), numeric(1))
}

rough_vol_state <- function(realized_variance_series) {
  rv <- pmax(as.numeric(realized_variance_series), eps)
  stopifnot(length(rv) >= 32)
  logv <- log(rv)
  H <- hurst_variogram(logv)
  center <- mean(logv)
  if (length(logv) > 2) {
    phi <- suppressWarnings(cor(logv[-length(logv)], logv[-1]))
    if (!is.finite(phi)) phi <- 0
  } else {
    phi <- 0
  }
  phi <- clamp(phi, -0.99, 0.99)
  forecast_log <- center + phi*(tail(logv,1)-center)
  list(
    hurst=H,
    persistence=phi,
    current_variance=tail(rv,1),
    forecast_variance=exp(forecast_log),
    vol_of_log_vol=safe_sd(diff(logv))
  )
}

# --- DCC correlation + t-copula --------------------------------------------

dcc_core <- function(standardized_returns, a, b) {
  z <- as.matrix(standardized_returns)
  stopifnot(nrow(z) >= 20, ncol(z) >= 2, a >= 0, b >= 0, a+b < 1)
  z[!is.finite(z)] <- 0
  qbar <- cov(z) + diag(1e-10,ncol(z))
  q <- qbar
  n <- nrow(z)
  p <- ncol(z)
  history <- array(0,dim=c(p,p,n))
  nll <- 0

  for (t in seq_len(n)) {
    if (t >= 2) {
      q <- (1-a-b)*qbar + a*tcrossprod(z[t-1,]) + b*q
    }
    d <- sqrt(pmax(diag(q),eps))
    r <- q/outer(d,d)
    diag(r) <- 1
    history[,,t] <- r

    if (t >= 2) {
      det_r <- determinant(r,logarithm=TRUE)
      if (det_r$sign <= 0) {
        nll <- Inf
      } else if (is.finite(nll)) {
        solved <- tryCatch(solve(r,z[t,]),error=function(e) NULL)
        if (is.null(solved)) {
          nll <- Inf
        } else {
          quad <- sum(z[t,]*solved)
          nll <- nll + 0.5*(as.numeric(det_r$modulus)+quad)
        }
      }
    }
  }

  list(z=z,qbar=qbar,history=history,nll=nll)
}

dcc_fit <- function(standardized_returns, a=0.02, b=0.97) {
  core <- dcc_core(standardized_returns,a,b)
  p <- dim(core$history)[1]
  n <- dim(core$history)[3]
  correlation <- if (p == 2) {
    as.numeric(core$history[1,2,])
  } else {
    core$history
  }
  list(
    a=a,
    b=b,
    qbar=cov2cor(core$qbar),
    correlation=correlation,
    last_correlation=core$history[,,n,drop=TRUE],
    loglik=-core$nll
  )
}

dcc_estimate <- function(standardized_returns, start=c(a=0.03,b=0.94)) {
  z <- as.matrix(standardized_returns)
  stopifnot(nrow(z) >= 20, ncol(z) >= 2)
  a0 <- unname(start["a"])
  b0 <- unname(start["b"])
  if (!is.finite(a0) || !is.finite(b0) || a0 < 0 || b0 < 0 || a0+b0 >= 0.999) {
    a0 <- 0.03
    b0 <- 0.94
  }
  rest0 <- max(1-a0-b0,1e-4)
  p0 <- log(c(a0/rest0,b0/rest0))

  unpack <- function(p) {
    p <- clamp(p,-30,30)
    ea <- exp(p[1])
    eb <- exp(p[2])
    den <- 1+ea+eb
    c(a=0.999*ea/den,b=0.999*eb/den)
  }
  objective <- function(p) {
    q <- unpack(p)
    dcc_core(z,q["a"],q["b"])$nll
  }

  opt <- tryCatch(
    optim(p0,objective,method="BFGS",control=list(maxit=300,reltol=1e-8)),
    error=function(e) NULL
  )
  if (is.null(opt) || !is.finite(opt$value)) {
    q <- c(a=a0,b=b0)
    convergence <- 1L
  } else {
    q <- unpack(opt$par)
    convergence <- opt$convergence
  }
  fit <- dcc_fit(z,unname(q["a"]),unname(q["b"]))
  fit$convergence <- convergence
  fit
}

t_copula_tail_dependence <- function(rho, df=6) {
  stopifnot(df > 0)
  rho <- clamp(rho,-0.999999,0.999999)
  2 * pt(-sqrt((df+1)*(1-rho)/(1+rho)),df=df+1)
}

estimate_t_df <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  stopifnot(length(x) >= 50)
  centered <- x-mean(x)
  m2 <- mean(centered^2)
  if (m2 <= eps) return(50)
  excess <- mean(centered^4)/(m2^2)-3
  if (!is.finite(excess) || excess <= 0) return(50)
  clamp(4+6/excess,4.1,100)
}

calibrate_cross_asset <- function(return_matrix, a=NULL, b=NULL) {
  x <- as.matrix(return_matrix)
  stopifnot(nrow(x) >= 20, ncol(x) >= 2)
  fits <- lapply(seq_len(ncol(x)), function(j) garch11_fit(x[,j]))
  z <- do.call(cbind,lapply(fits,function(f) f$standardized))
  dcc <- if (is.null(a) || is.null(b)) dcc_estimate(z) else dcc_fit(z,a,b)
  df <- estimate_t_df(as.numeric(z))
  tail_dependence <- matrix(0,ncol(z),ncol(z))
  for (i in seq_len(ncol(z))) {
    for (j in seq_len(ncol(z))) {
      tail_dependence[i,j] <- if (i == j) 1 else
        t_copula_tail_dependence(dcc$last_correlation[i,j],df)
    }
  }
  list(
    univariate=fits,
    standardized=z,
    dcc=dcc,
    t_df=df,
    tail_dependence=tail_dependence,
    last_correlation=dcc$last_correlation
  )
}

# --- Bayesian calibration + time series ------------------------------------

normal_inverse_gamma_prior <- function(mu=0, kappa=1, alpha=2, beta=1e-4) {
  stopifnot(kappa > 0, alpha > 0, beta > 0)
  list(mu=mu,kappa=kappa,alpha=alpha,beta=beta)
}

bayes_return_update <- function(prior, observations) {
  x <- as.numeric(observations)
  stopifnot(length(x) >= 1, all(is.finite(x)))
  n <- length(x)
  xb <- mean(x)
  ss <- sum((x-xb)^2)
  kappa_n <- prior$kappa+n
  mu_n <- (prior$kappa*prior$mu+n*xb)/kappa_n
  alpha_n <- prior$alpha+n/2
  beta_n <- prior$beta + 0.5*ss +
    prior$kappa*n*(xb-prior$mu)^2/(2*kappa_n)
  list(mu=mu_n,kappa=kappa_n,alpha=alpha_n,beta=beta_n)
}

arima_forecast_base <- function(x, horizon=1L, order=c(1L,0L,0L)) {
  x <- as.numeric(x)
  stopifnot(length(x) >= 20, horizon >= 1)
  fit <- tryCatch(
    arima(x, order=order, include.mean=TRUE, method="ML"),
    error=function(e) NULL
  )
  if (is.null(fit)) {
    return(list(
      mean=rep(mean(x),horizon),
      sd=rep(safe_sd(x),horizon),
      fit=NULL
    ))
  }
  pred <- predict(fit,n.ahead=horizon)
  list(mean=as.numeric(pred$pred),sd=pmax(as.numeric(pred$se),0),fit=fit)
}

# --- Risk and parameter proxies --------------------------------------------

historical_var_es <- function(returns, alpha=0.99) {
  x <- as.numeric(returns)
  stopifnot(length(x) >= 20, alpha > 0.5, alpha < 1)
  q <- unname(quantile(x,1-alpha,type=8,na.rm=TRUE))
  tail_x <- x[x <= q]
  var_loss <- max(0,-q)
  es <- if (length(tail_x)) max(var_loss,-mean(tail_x)) else var_loss
  list(var=var_loss,expected_shortfall=es,quantile=q,alpha=alpha)
}

estimate_jump_intensity <- function(returns, threshold=4) {
  x <- as.numeric(returns)
  stopifnot(length(x) >= 20, threshold > 0)
  center <- median(x)
  scale <- mad(x,center=center,constant=1.4826)
  if (!is.finite(scale) || scale < eps) scale <- safe_sd(x)
  idx <- which(abs(x-center) > threshold*scale)
  jumps <- x[idx]
  list(
    lambda=length(idx)/length(x),
    count=length(idx),
    jump_mu=if (length(jumps)) mean(jumps) else 0,
    jump_sigma=if (length(jumps) > 1) sd(jumps) else 0,
    threshold=threshold*scale
  )
}

fit_heston_proxy <- function(prices, window=24L) {
  r <- returns_from_prices(prices)
  window <- min(as.integer(window), max(4L,floor(length(r)/4)))
  rv <- realized_variance(r,window)
  theta <- max(mean(rv),eps)
  v0 <- max(tail(rv,1),eps)

  if (length(rv) >= 3) {
    phi <- suppressWarnings(cor(rv[-length(rv)],rv[-1]))
    if (!is.finite(phi)) phi <- 0
    phi <- clamp(phi,-0.99,0.999)
    kappa <- max(0,1-phi)

    drv <- diff(rv)
    aligned_r <- tail(r,length(drv))
    rho <- suppressWarnings(cor(aligned_r,drv))
    if (!is.finite(rho)) rho <- 0
    rho <- clamp(rho,-0.999,0.999)

    base <- pmax(rv[-length(rv)],eps)
    xi <- safe_sd(drv/sqrt(base))
  } else {
    kappa <- 0
    rho <- 0
    xi <- 0
  }

  list(v0=v0,theta=theta,kappa=kappa,xi=max(xi,0),rho=rho)
}

coverage_correctness <- function(standardized_returns, target=0.95) {
  z <- as.numeric(standardized_returns)
  z <- z[is.finite(z)]
  if (!length(z)) return(5)
  observed <- mean(abs(z) <= 1.959964)
  clamp(10 - 25*abs(observed-target),0,10)
}

# --- Calibration state ------------------------------------------------------

calibrate_market <- function(prices, dt=1/365, ticker="ASSET") {
  p <- as.numeric(prices)
  stopifnot(length(p) >= 80, all(is.finite(p)), all(p > 0), dt > 0)
  r <- returns_from_prices(p)
  g <- garch11_fit(r)
  hmm_window <- tail(r,min(length(r),900))
  hmm <- hmm3_fit(hmm_window,max_iter=60,tol=1e-6)
  path <- hmm3_viterbi(hmm_window,hmm)
  regime <- tail(path,1)

  rv_window <- min(24L,max(4L,floor(length(r)/10)))
  rv <- realized_variance(r,rv_window)
  rough <- rough_vol_state(rv)
  rough$eta <- rough$vol_of_log_vol/(dt^rough$hurst)

  prior <- normal_inverse_gamma_prior(mu=0,kappa=1,alpha=2,beta=max(var(r),1e-6))
  posterior <- bayes_return_update(prior,r)
  jump <- estimate_jump_intensity(r)
  heston_step <- fit_heston_proxy(p,rv_window)

  # Convert per-observation estimates into per-unit-time rates used by SDEs.
  mu_rate <- posterior$mu/dt
  sigma_rate <- sqrt(max(tail(g$variance,1),eps)/dt)
  heston <- heston_step
  heston$v0 <- heston$v0/dt
  heston$theta <- heston$theta/dt
  heston$kappa <- heston$kappa/dt
  heston$xi <- heston$xi/sqrt(dt)
  jump$lambda <- jump$lambda/dt

  recent_n <- min(24L,length(p)-1)
  recent_shift <- tail(p,1)/p[length(p)-recent_n]-1
  last_posterior <- tail(hmm$posterior,1)
  regime_certainty <- max(last_posterior)

  list(
    ticker=ticker,
    spot=tail(p,1),
    dt=dt,
    returns=r,
    mu=mu_rate,
    sigma=sigma_rate,
    garch=g,
    hmm=hmm,
    regime=regime,
    regime_certainty=regime_certainty,
    rough=rough,
    posterior=posterior,
    jump=jump,
    heston=heston,
    risk=historical_var_es(r,0.99),
    correctness=coverage_correctness(g$standardized),
    recent_shift=recent_shift,
    calibrated_at=as.numeric(Sys.time())
  )
}

# --- Six concurrent forecast horizons --------------------------------------

m3a_horizon_specs <- function() {
  data.frame(
    name=c("tick_hourly","daily","weekly","monthly","annual","five_year"),
    label=c("1h","24h","7d","30d","1y","5y"),
    years=c(1/(24*365),1/365,7/365,30/365,1,5),
    model=c("rough","heston","merton","merton","heston","gbm"),
    stringsAsFactors=FALSE
  )
}

bounded_from_samples <- function(samples, state, label, model) {
  q <- as.numeric(quantile(samples,c(.025,.5,.975),names=FALSE,type=8))
  width <- (q[3]-q[1])/max(abs(q[2]),eps)
  confidence <- clamp(
    0.55*state$correctness +
      4.5*state$regime_certainty +
      2.0*(1-clamp(width,0,1)),
    0,10
  )
  certainty <- clamp(
    5.0*state$regime_certainty +
      5.0*(1-clamp(width,0,1)),
    0,10
  )
  list(
    value=q[2],
    lower_bound=q[1],
    upper_bound=q[3],
    confidence=confidence,
    correctness=clamp(state$correctness,0,10),
    certainty=certainty,
    time_horizon=label,
    sim_type="statistical",
    token_ticker=state$ticker,
    recent_shift=state$recent_shift,
    model=model,
    regime=state$regime
  )
}

forecast_horizon <- function(state, horizon_name, paths=4000L, seed=1L) {
  specs <- m3a_horizon_specs()
  row <- specs[specs$name==horizon_name,,drop=FALSE]
  if (!nrow(row)) stop("unknown_horizon")
  years <- row$years[1]
  model <- row$model[1]
  label <- row$label[1]

  steps <- max(1L,min(365L,as.integer(ceiling(years*365))))
  step_dt <- years/steps

  samples <- switch(
    model,
    rough=rough_vol_terminal(
      state$spot,
      state$mu,
      max(state$rough$current_variance/state$dt,eps),
      state$rough$hurst,
      max(state$rough$eta,0),
      step_dt,steps,paths,seed
    ),
    heston=heston_terminal(
      state$spot,
      max(state$heston$v0,eps),
      state$mu,
      max(state$heston$kappa,0),
      max(state$heston$theta,eps),
      max(state$heston$xi,0),
      state$heston$rho,
      step_dt,steps,paths,seed
    ),
    merton=merton_terminal(
      state$spot,state$mu,state$sigma,
      max(state$jump$lambda,0),
      state$jump$jump_mu,
      max(state$jump$jump_sigma,0),
      step_dt,steps,paths,seed
    ),
    gbm=gbm_terminal(
      state$spot,state$mu,state$sigma,
      step_dt,steps,paths,seed
    ),
    stop("unknown_model")
  )
  bounded_from_samples(samples,state,label,model)
}

forecast_all_horizons <- function(state, paths=4000L, seed=1L) {
  specs <- m3a_horizon_specs()
  out <- lapply(seq_len(nrow(specs)), function(i) {
    forecast_horizon(state,specs$name[i],paths,seed+i-1L)
  })
  names(out) <- specs$name
  out
}

bounded_price_prediction <- function(s0, mu, sigma, dt, steps,
                                     paths=4000L, seed=1L,
                                     horizon="24h", ticker="ASSET") {
  sims <- gbm_terminal(s0,mu,sigma,dt,steps,paths,seed)
  q <- as.numeric(quantile(sims,c(.025,.5,.975),names=FALSE,type=8))
  width <- (q[3]-q[1])/max(q[2],eps)
  list(
    value=q[2],
    lower_bound=q[1],
    upper_bound=q[3],
    confidence=clamp(10-5*width,0,10),
    correctness=5,
    certainty=clamp(10-8*width,0,10),
    time_horizon=horizon,
    sim_type="statistical",
    token_ticker=ticker,
    recent_shift=0
  )
}

# --- Minimal hand-rolled JSON line protocol --------------------------------

json_number <- function(line, key, default) {
  pat <- paste0('"',key,'"[[:space:]]*:[[:space:]]*(-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)')
  m <- regexec(pat,line,perl=TRUE)
  z <- regmatches(line,m)[[1]]
  if (length(z) < 2) default else as.numeric(z[2])
}

json_string <- function(line, key, default) {
  pat <- paste0('"',key,'"[[:space:]]*:[[:space:]]*"([^"]*)"')
  m <- regexec(pat,line,perl=TRUE)
  z <- regmatches(line,m)[[1]]
  if (length(z) < 2) default else z[2]
}

json_number_array <- function(line, key) {
  pat <- paste0('"',key,'"[[:space:]]*:[[:space:]]*\\[([^]]*)\\]')
  m <- regexec(pat,line,perl=TRUE)
  z <- regmatches(line,m)[[1]]
  if (length(z) < 2 || !nzchar(trimws(z[2]))) return(numeric())
  as.numeric(strsplit(z[2],",",fixed=TRUE)[[1]])
}

emit_prediction <- function(p) {
  cat(sprintf(
    '{"value":%.10g,"lower_bound":%.10g,"upper_bound":%.10g,"confidence":%.4f,"correctness":%.4f,"certainty":%.4f,"time_horizon":"%s","sim_type":"statistical","token_ticker":"%s","recent_shift":%.10g}\n',
    p$value,p$lower_bound,p$upper_bound,p$confidence,p$correctness,
    p$certainty,p$time_horizon,p$token_ticker,p$recent_shift
  ))
}

main <- function() {
  line <- readLines(file("stdin"),n=1,warn=FALSE)
  if (!length(line)) quit(status=2)

  prices <- json_number_array(line,"prices")
  if (length(prices) >= 80) {
    dt <- json_number(line,"dt",1/365)
    ticker <- json_string(line,"token_ticker","ASSET")
    horizon <- json_string(line,"horizon","daily")
    paths <- as.integer(json_number(line,"paths",4000))
    seed <- as.integer(json_number(line,"seed",1))
    state <- calibrate_market(prices,dt,ticker)
    emit_prediction(forecast_horizon(state,horizon,paths,seed))
  } else {
    p <- bounded_price_prediction(
      json_number(line,"spot",100),
      json_number(line,"mu",0),
      json_number(line,"sigma",0.2),
      json_number(line,"dt",1/365),
      as.integer(json_number(line,"steps",1)),
      as.integer(json_number(line,"paths",4000)),
      as.integer(json_number(line,"seed",1)),
      json_string(line,"time_horizon","24h"),
      json_string(line,"token_ticker","ASSET")
    )
    emit_prediction(p)
  }
}

if (sys.nframe() == 0) main()
