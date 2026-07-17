# M5 — Traders (AI actors)

## 1. Component
The economy organ's hands: **specialized AI actors** that buy, sell, and mint cryptocurrency and
NFTs. Each trader is bound to a Wallet (M4), operates through the Marketplace (M1), queries Sims
(M3) for predictions, and has all tool calls monitored by the SAE (M7). Multiple traders may
operate concurrently with **different specializations** (DeFi yield, NFT minting, arbitrage,
long-term holding, etc.).

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C3; implementation C1.

## 3. Language & location
TBD · `src/economy/traders/`. Traders are a mixed roster: some are LLM-powered AI agents, some
are deterministic strategy bots. All use the same `MarketAction` interface through the
Marketplace regardless of implementation.

## 4. Does / does-not
- **Does:** read sim predictions from the Marketplace (M1) (bounded, multi-domain, per-sim-type);
  formulate trade decisions based on predictions + market state + specialization; submit
  `MarketAction` requests to the Marketplace (M1) via bound wallet (M4); operate with **scoped
  autonomy** — trades within law/budget constraints don't need Brain or Conductor approval.
- **Does-not:** execute on-chain directly (Marketplace does); hold keys (Wallet does); supervise
  other traders (Conductor does); modify the law script (immutable — M1-L2); bypass the
  Marketplace (M1-L1).

## 5. Interface contract
- `init_trader(specialization, wallet_id, config) -> trader_id`.
  `specialization` ∈ { `defi_yield`, `nft_minter`, `arbitrageur`, `trend_follower`,
  `market_maker`, … } — extensible.
- `decide(market_state, predictions: [BoundedPrediction]) -> MarketAction?` — the trader's core
  loop. May return no action (waiting is a valid decision). Predictions are read from the
  Marketplace, which receives them continuously from the sim hub via M2.
- `tool_call(tool_name, args) -> result` — every tool call is intercepted and logged by the SAE
  (M7) at the Marketplace level. The Marketplace is the only interface traders can act through.
- `pause() / resume()` — Conductor (M6) can pause a trader pending investigation.
- `status() -> { active | paused | investigating, wallet_id, specialization, position_summary }`.

## 6. Dependencies & stubs
- M1 Marketplace — action submission; *stub:* mock marketplace that logs actions.
- M1 Marketplace — predictions (from sims via M2) and action submission; *stub:* mock marketplace.
- M4 Wallet — bound 1:1; *stub:* mock wallet.
- M6 Conductor — supervision; *stub:* no supervision.
- M7 SAE — monitors all tool calls; *stub:* print calls.

## 7. Invariants / laws
- **L1 (C5):** **all market actions go through the Marketplace** — a trader cannot interact with
  any chain or protocol except via `MarketAction` → Marketplace (M1). Enforced by architecture
  (no direct RPC access), not just policy.
- **L2 (C5):** **all tool calls are monitored** — every tool invocation (Marketplace, Sims,
  Feeds, internal) is logged to SAE (M7). No unmonitored trader action.
- **L3 (C4):** **wallet binding is irrevocable within a session** — a trader's wallet cannot be
  reassigned to another trader at runtime.
- **L4 (C4):** **Conductor can pause** — a paused trader cannot submit actions, query sims, or
  read feeds until resumed by the Conductor (M6).
- **L5 (C3):** trader specialization constrains strategy but not the interface — all traders use
  the same `MarketAction` vocabulary regardless of specialization.

## 8. Build steps
1. Define the trader agent architecture (LLM-based? hybrid? rule-based for v1?).
2. Implement the `decide` loop (observe market state + predictions → action).
3. Wire tool-call interception → M7 SAE.
4. Wire Marketplace submission → M1.
5. Implement pause/resume for Conductor control.
6. Build at least two specializations to test multi-trader dynamics.

## 9. Tests
Marketplace-only: trader cannot call chain RPC directly. Monitoring: every tool call appears in
SAE log. Wallet binding: trader uses only its bound wallet. Pause: paused trader cannot submit
actions. Specialization: different specializations produce different action patterns on identical
market state.

## 10. Open items
- Trader agent architecture (which LLM? how much deterministic logic vs. model inference?).
- Number of concurrent traders and resource allocation per trader.
- Specialization catalog (which types, and how do they differ in strategy?).
- Inter-trader coordination (do traders see each other's positions? shared state? isolated?).
