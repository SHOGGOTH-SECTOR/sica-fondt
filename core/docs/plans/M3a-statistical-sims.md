# M3a — Statistical & quantitative sims

## 1. Component
Pure statistical simulation: **Monte Carlo methods, Bayesian inference, time-series forecasting,
stochastic volatility, regime detection, and cross-asset correlation**. The mathematical backbone
— no game theory, no sociology, just the numbers. Operates across **six concurrent time horizons**
(tick/hourly → daily → weekly → monthly → annual → 5-year). Pops in this sim represent
**stochastic sample paths**, not behavioral agents.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Core quant methods C5 (GBM, GARCH, ARIMA — textbook). Heston stochastic
volatility C5 (closed-form characteristic function; industry standard since 1993). Rough
volatility C4 (Gatheral et al. 2018, heavily cited; crypto implementations exist). HMM regime
detection C4 (established; crypto-specific copula hybrids emerging 2023–2024). Almgren-Chriss
execution C5 (industry standard since 2001). Jump-diffusion C5 (Merton 1976). Parameterization
for crypto markets C1.

## 3. Language & location
**R 4.x** (apt `r-base-core`) · `src/economy/sims/statistical/`. Minimal dependencies:
`r-base-core` + `HiddenMarkov` (CRAN — Viterbi filter, forward-backward, Baum-Welch). GARCH,
Heston SDE, DCC, copula, jump-diffusion, and fBM are hand-rolled using base R primitives
(`optim`, `fft`, `arima`, matrix ops). JSON I/O for the Hub stdin/stdout protocol is
hand-rolled. Fractional Brownian motion via spectral methods (Hosking 1984 / Wood & Chan 1994)
uses base R `fft()`.

## 4. Does / does-not
- **Does:** run Monte Carlo price simulations (GBM, Merton jump-diffusion, Heston stochastic
  volatility); model volatility surface via **Heston SDE**:
  $dS_t = \mu S_t dt + \sqrt{\nu_t} S_t dW_t^S$,
  $d\nu_t = \kappa(\theta - \nu_t)dt + \xi\sqrt{\nu_t} dW_t^\nu$
  with $\text{corr}(dW^S, dW^\nu) = \rho$ (mean-reversion speed $\kappa$, long-run variance
  $\theta$, vol-of-vol $\xi$); model **rough volatility** via fractional Brownian motion
  $dS_t = \mu dt + \sigma_t dB_t^H$ with Hurst exponent $H \approx 0.4$ capturing
  antipersistent microstructure (Gatheral et al. 2018); detect **regime transitions** via
  Hidden Markov Model: $r_t | s_t \sim \mathcal{N}(\mu_{s_t}, \sigma^2_{s_t})$,
  $s_t \in \{\text{Bull, Neutral, Bear}\}$ with Viterbi filter updating in <5ms per tick;
  model **cross-asset tail dependence** via DCC-GARCH copula hybrid:
  $dQ_t/dt = a \cdot (\bar{S} - Q_t) + b \cdot (\varepsilon_t \varepsilon_t^T - Q_t)$
  with $t$-Copula for fat-tailed spillovers (BTC→alts); Bayesian parameter estimation from
  live data (M2); time-series forecasting (ARIMA, GARCH for volatility clustering); Value-at-Risk
  and Expected Shortfall; produce bounded predictions with confidence intervals.
- **Does-not:** model human behavior (M3b does); model protocol mechanics (M3c–M3f do);
  trade or recommend (Traders do); optimize execution routing (M3g does using our vol estimates).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** statistical confidence intervals (CI from Monte Carlo), Heston variance
  bands (from $\nu_t$ process), rough-vol forecast cones, regime-conditional intervals.
- **Time-horizon mapping** (all run concurrently):
  | Horizon | Primary models | Update cadence |
  |---------|---------------|----------------|
  | Tick–hourly | Rough vol ($H \approx 0.4$), HMM regime filter, realized variance | Every tick |
  | Daily | Heston vol surface, GARCH, DCC correlation | Every bar close |
  | Weekly–monthly | Jump-diffusion Monte Carlo, regime-conditional forecasts | Hourly roll |
  | Annual–5yr | SDE mean-reversion long-run $\theta$, macro regime priors | Daily roll |
- Examples:
  `{ value: 1847.30, lower_bound: 1790.15, upper_bound: 1905.60, confidence: 9.50,
  time_horizon: "24h", sim_type: "statistical" }` — 95% CI on ETH price.
  `{ value: 0.72, lower_bound: 0.58, upper_bound: 0.89, confidence: 9.00,
  time_horizon: "1h", sim_type: "statistical" }` — Heston instantaneous vol $\sqrt{\nu_t}$.
  `{ value: "bear", lower_bound: null, upper_bound: null, confidence: 8.30,
  time_horizon: "current", sim_type: "statistical" }` — HMM regime state.
- **Prediction types:** `price_forecast`, `volatility_surface`, `var_calculation`,
  `correlation_matrix`, `regime_state`, `rough_vol_estimate`, `jump_intensity`.
- Calibration: ingests `price_tick` and `dex_pool_state` from M2 Data Feeds.

## 6. Dependencies & stubs
- M2 Data Feeds — price history for calibration; *stub:* canned price series.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C5):** bounds are **statistical confidence intervals** — derived from the model's
  distribution, not hand-picked. Three distinct metrics in every output: **confidence** (how sure
  the model is of this prediction), **correctness** (how accurate the model has been historically),
  and **certainty** (how stable the estimate is across perturbations). All on the 0.00–10.00 scale.
- **L2 (C5):** **six time horizons run concurrently** — models span multiple horizons (e.g.
  Monte Carlo runs daily and annual, rough vol runs tick and hourly, Heston runs daily and
  weekly). All coexist; none blocks the others.
- **L3 (C4):** model parameters are **re-estimated on each calibration** from live data — no
  stale parameters carried across regime changes. Regime transitions trigger immediate
  re-estimation of conditional parameters.
- **L4 (C4):** the **Heston correlation $\rho$ between price and vol** is a fitted parameter,
  never assumed — crypto assets exhibit leverage effects different from equities.
- **L5 (C4):** rough volatility Hurst exponent $H$ is **estimated from realized variance**, not
  fixed — $H$ varies across assets and regimes (Gatheral et al. 2018).

## 8. Build steps
1. Implement geometric Brownian motion Monte Carlo (simplest price sim).
2. Add GARCH volatility estimation.
3. Implement Heston SDE solver (Euler-Maruyama with full truncation for $\nu_t \geq 0$).
4. Add Merton jump-diffusion (Poisson jumps + GBM).
5. Implement rough volatility via fractional BM with rolling Hurst estimator.
6. Implement HMM regime detector (3-state Viterbi filter).
7. Add DCC-GARCH copula for cross-asset correlation.
8. Wire M2 price data → Bayesian parameter re-estimation.
9. Implement multi-horizon `BoundedPrediction` output with CIs.

## 9. Tests
Monte Carlo: N sample paths produce a distribution with correct mean/variance. CI: 95% interval
contains true value ≥ 95% of the time on historical backtest. GARCH: volatility clusters detected
in synthetic data. Heston: implied vol smile reproduced for known parameters. Rough vol: Hurst
exponent recovered from synthetic fBM paths. HMM: regime transitions detected within 15–60s on
synthetic regime-switching data. Copula: tail dependence captured (BTC crash → alt crash
correlation spike). Jump-diffusion: fat tails reproduced. Calibration: new data shifts parameter
estimates. Multi-horizon: all six horizons produce concurrent outputs.

## 10. Open items
- Heston calibration method (characteristic function inversion? particle filter?).
- Rough vol computational cost (fBM generation is O(N²) naively; FFT methods needed).
- HMM state count (3 sufficient? 4+ for crypto with "mania" regime?).
- Which copula family for tail dependence ($t$-copula? Clayton? Joe?).
- Computational budget per horizon (GPU for Monte Carlo paths?).
