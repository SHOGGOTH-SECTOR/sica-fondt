# M5 — Traders (AI actors)

## 1. Component
The economy organ's hands: **specialized AI instances** that buy, sell, and mint cryptocurrency and
NFTs. Each trader is bound to a Wallet (M4), operates through the Marketplace (M1), queries Market to receive predictions (M3), and are monitored by the SAE (M7) via Marketplace. Multiple traders operate concurrently with **different heuristics and specializations**.

## 1A. Operational doctrine
- **Purpose:** Traders are genuinely agentic economic entities with persistent identity, goals,
  learning, judgment under uncertainty, specialization, and responsibility for independently
  assigned capital. Their local objective is profitable deployment of that capital.
- **Independence:** Traders need not converge or agree. Their funding stores are independent;
  disagreement matters only through realized performance, capital allocation, shared market
  effects, or M6 systemic risk.
- **Uncertainty:** each Trader chooses how declared uncertainty affects an individual action,
  position size, evidence gathering, or abstention - but only inside the uncertainty regime and
  broader boundaries assigned by M6. Actions outside the allowed regime are unavailable.
- **Performance:** raw P&L is the local objective; **loss relative to prediction** is the primary
  diagnostic metric. A loss that was correctly anticipated is categorically different from a
  confident unanticipated loss.
- **Longitudinal metric:** each Trader accumulates regime-conditioned prediction/calibration loss
  over time rather than being judged by isolated wins or losses. Repetition changes capital trust.
- **Memory:** durable Trader memory should preserve its own forecasts, declared uncertainty,
  realized outcomes, recurring failure modes, regime-specific competence, and intervention history.
- **Completion criterion:** a Trader runtime is not complete until it can form a prediction,
  declare uncertainty, choose a lawful action, use only its assigned capital, record the decision
  basis, receive realization, update memory, and expose longitudinal calibration/P&L metrics.

## 2. Status / certainty
SCAFFOLD · PARTIAL. `core/src/economy/traders.tcl` implements trader identity,
specialization labels, and mechanical pause/resume state. Trader inference remains open.
Role C3; scaffold C2.

## 3. Language & location
**Tcl 8.6 identity/state scaffold** · `core/src/economy/traders.tcl`. The implemented object is
not an AI inference runtime: it registers Trader identity/specialization and maintains mechanical
pause state. Future Trader cognition may be implemented separately, but every implementation must
still use the same Marketplace-only `MarketAction` surface. Deterministic helper bots remain
subservient to Traders rather than becoming independent market actors.

## 4. Does / does-not
- **Does now:** register unique Trader IDs with specialization labels; expose existence/count;
  enter and leave mechanical pause state under M6 control.
- **Future Trader runtime:** read bounded predictions through Marketplace, formulate actions from
  specialization + market state, and submit `MarketAction` through M1 using its bound M4 wallet.
- **Does not:** execute on-chain directly; hold keys; supervise other Traders; modify Marketplace
  law; bypass Marketplace; or currently perform AI inference.

## 5. Interface contract
Implemented Tcl registry/state surface:
- `register(trader_id, specialization)`.
- `exists(trader_id)`.
- `pause(trader_id)`, `resume(trader_id)`, `is_paused(trader_id)`.
- `count()`, `paused_count()`.

The future AI Trader layer must produce Marketplace `MarketAction` requests and consume
Marketplace predictions; no native model/inference interface is implemented in V1.

Target decision/outcome records:
- `TraderDecision { decision_id, trader_id, regime, forecast_refs, declared_uncertainty,
  action, capital_at_risk, rationale_digest, created_at }`.
- `TraderOutcome { decision_id, realization_refs, realized_pnl, calibration_loss,
  realized_at }`.

`calibration_loss` is the longitudinal diagnostic: it measures realized outcome against the
Trader's own prediction and declared uncertainty within the active regime. P&L remains the local
objective; calibration loss explains whether wins/losses were expected or surprising.

## 6. Dependencies & stubs
- M1 Marketplace — implemented action/prediction boundary.
- M4 Wallets — implemented 1:1 binding + exposure brakes; custody/signing absent.
- M6 Conductor — implemented mechanical pause/veto supervision; specialist inference absent.
- M7 SAE — implemented Marketplace-level logging/alert envelopes; SAE inference absent.
- AI Trader inference runtime — open.

## 7. Invariants / laws
- **L1 (C5):** **all trades go through the Marketplace** — a trader cannot interact with
  any chain or protocol except via Marketplace (M1). Enforced by architecture (no direct RPC access), not just policy.
- **L3 (C4):** **wallet binding is permanent** — a trader's wallet cannot be reassigned to another trader at any time.
- **L4 (C4):** **Conductor can pause** — a paused Trader cannot submit Marketplace actions or
  query Marketplace predictions until resumed by M6. M2 does not currently expose a direct
  Trader feed-read facade.
- **L5 (C3):** trader specialization constrains strategy but not the interface — all traders use the same vocabulary regardless of specialization.

## 8. Build status
1. **Done:** unique Trader registry + specialization labels.
2. **Done:** mechanical pause/resume state owned by M6.
3. **Done:** M1 rejects paused Traders and M1 prediction reads reject paused Traders.
4. **Done:** M4 enforces permanent wallet binding independently.
5. **Next:** define/persist `TraderDecision` and `TraderOutcome` records.
6. **Next:** compute regime-conditioned calibration-loss rate and P&L rate over rolling windows.
7. **Next:** expose M6 uncertainty-regime admission to the Trader before M1 submission.
8. **Open:** AI inference/action-generation runtime and specialization-specific decision logic.
9. **Open:** any lower-level deterministic helper-bot framework subordinate to Traders.

## 9. Tests
Current tests verify identity existence, wallet binding through M1, pause blocking action
submission, resume restoring submission, and Marketplace-only prediction access. There is no test
for specialization-dependent action patterns because Trader inference is not implemented.

## 10. Open items
- Trader inference architecture and model/runtime choice.
- Number of concurrent Traders and resource allocation.
- Specialization catalog and training/conditioning semantics.
- Safe coordination semantics between Traders, if any; no direct execution bypass may emerge
  from coordination.
- Helper-bot interfaces that remain deterministic and subordinate to the owning Trader.