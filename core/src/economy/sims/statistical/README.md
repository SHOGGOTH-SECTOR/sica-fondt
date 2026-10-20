# M3a — statistical simulator

M3a V1 is the R-native quantitative simulator behind the stomach's statistical prediction type.

Implemented models: GBM; Merton jump diffusion; Heston full-truncation SDE; Heston characteristic-function call pricing and option-surface calibration; GARCH(1,1) QMLE; three-state Gaussian HMM with Viterbi decoding; Davies–Harte fractional Gaussian noise; fitted rough-vol H and eta; fitted DCC correlation; Student-t copula tail dependence; conjugate Bayesian return calibration; ARIMA; historical VaR / Expected Shortfall; jump-intensity estimation; empirical walk-forward quality scoring.

The seven public prediction types are `price_forecast`, `volatility_surface`, `var_calculation`, `correlation_matrix`, `regime_state`, `rough_vol_estimate`, and `jump_intensity`. Every hub publication remains numerically bounded. Regime labels and matrix detail are metadata, not exceptions to the hub bound invariant.

Calibration consumes normalized M2 `price_tick` history and optional `dex_pool_state` observations. Pool price is liquidity weighted and cross-venue disagreement reduces certainty rather than replacing literal price-tick ground truth.

The live boundary is:

`M2 → StatisticalRunner (Tcl) → engine.R → SimsHub → Marketplace`

No function in M3a signs, broadcasts, routes, or submits transactions.

Verification:

```sh
Rscript core/src/economy/sims/statistical/tests.R
tclsh core/src/economy/sims/statistical/integration.test
```

GitHub Actions enforces both the native R suite and the Tcl summary (`5 passed / 0 failed`).
