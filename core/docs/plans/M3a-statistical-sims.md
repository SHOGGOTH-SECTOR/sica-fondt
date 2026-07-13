# M3a — Statistical & quantitative sims

## 1. Component
Pure statistical simulation: **Monte Carlo methods, Bayesian inference, time-series forecasting,
and volatility modeling**. The mathematical backbone — no game theory, no sociology, just the
numbers. Operates across multiple time scales (tick to weekly). Pops in this sim represent
**stochastic sample paths**, not behavioral agents.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Mathematical foundations C4 (standard quant methods); parameterization C1.

## 3. Language & location
TBD · `src/economy/sims/statistical/`. Python (NumPy/SciPy), Julia, or R for numerical
computing. Needs efficient matrix operations and distribution sampling.

## 4. Does / does-not
- **Does:** run Monte Carlo price simulations (geometric Brownian motion, jump-diffusion);
  Bayesian parameter estimation from live data (M2); time-series forecasting (ARIMA, GARCH for
  volatility clustering); Value-at-Risk and Expected Shortfall calculations; produce bounded
  predictions with confidence intervals as upper/lower bounds.
- **Does-not:** model human behavior (M3b does); model protocol mechanics (M3c–M3f do);
  trade or recommend (Traders do).

## 5. Interface contract
- Implements `query(PredictionQuery) -> BoundedPrediction` per M3 hub.
- **Output bounds:** statistical confidence intervals.
  Example: `{ value: 1847.30, lower_bound: 1790.15, upper_bound: 1905.60, confidence: 0.95,
  time_horizon: "24h", sim_type: "statistical" }` — 95% CI on ETH price.
- **Prediction types:** `price_forecast`, `volatility_estimate`, `var_calculation`,
  `correlation_matrix`, `regime_detection`.
- Calibration: ingests `price_tick` and `dex_pool_state` from M2 Data Feeds.

## 6. Dependencies & stubs
- M2 Data Feeds — price history for calibration; *stub:* canned price series.
- M3 Sims hub — lifecycle management; *stub:* manual init.

## 7. Invariants / laws
- **L1 (C4):** bounds are **statistical confidence intervals** — derived from the model's
  distribution, not hand-picked. The confidence level (e.g. 0.95) is explicit in the output.
- **L2 (C4):** **multiple time scales run concurrently** — a tick-level volatility estimate and a
  weekly price forecast coexist; neither blocks the other.
- **L3 (C3):** model parameters are **re-estimated on each calibration** from live data — no
  stale parameters carried across regime changes.

## 8. Build steps
1. Implement geometric Brownian motion Monte Carlo (simplest price sim).
2. Add GARCH volatility estimation.
3. Wire M2 price data → Bayesian parameter re-estimation.
4. Implement the `BoundedPrediction` output with CIs.

## 9. Tests
Monte Carlo: N sample paths produce a distribution with correct mean/variance. CI: 95% interval
contains true value ≥ 95% of the time on historical backtest. GARCH: volatility clusters detected
in synthetic data. Calibration: new data shifts parameter estimates.

## 10. Open items
- Which distributions beyond GBM (heavy-tailed? Lévy?).
- Regime-switching model complexity (hidden Markov? threshold?).
- Computational budget (how many Monte Carlo paths per tick?).
