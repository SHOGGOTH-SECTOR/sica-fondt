# M5 — Traders (AI actors)

## 1. Component
The economy organ's hands: **specialized AI instances** that buy, sell, and mint cryptocurrency and
NFTs. Each trader is bound to a Wallet (M4), operates through the Marketplace (M1), queries Market to receive predictions (M3), and are monitored by the SAE (M7) via Marketplace. Multiple traders operate concurrently with **different heuristics and specializations**.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C3; implementation C1.

## 3. Language & location
TBD · `src/economy/traders/`. Traders are AI agents.All use the same `MarketAction` interface through the Marketplace regardless of implementation. Traders are the agentic entities, the determininistic bots are subservient to them.

## 4. Does / does-not
- **Does:** read sim predictions from the Marketplace (M1) (bounded, multi-domain, per-sim-type);
  formulate trade decisions based on predictions + market state + specialization; submit
  `MarketAction` requests to the Marketplace (M1) only bound wallet (M4); operate with **scoped
  autonomy** — trades within law/budget constraints don't need Brain or Conductor approval; manage lower level bot goals.
- **Does-not:** execute on-chain directly (Marketplace does); hold keys (Wallet does); supervise
  other traders (Conductor does); modify the law script (immutable — M1-L2); bypass the
  Marketplace (M1-L1) - this must be due to literal lack of surface.

## 5. Interface contract
  
- [somehow this was a literal mess]


## 6. Dependencies & stubs
- M1 Marketplace — trade verification; *stub:* none, must make marketplace first.
- M1 Marketplace — predictions (from sims via M2) and action submission; *stub:* see above
- M4 Wallet — bound 1:1; *stub:* see above
- M6 Conductor — supervision; *stub:* ... need i state
- M7 SAE — Out of scope

## 7. Invariants / laws
- **L1 (C5):** **all trades go through the Marketplace** — a trader cannot interact with
  any chain or protocol except via Marketplace (M1). Enforced by architecture (no direct RPC access), not just policy.
- **L3 (C4):** **wallet binding is permanent** — a trader's wallet cannot be reassigned to another trader at any time.
- **L4 (C4):** **Conductor can pause** — a paused trader cannot submit actions, query sims, or read feeds until resumed by the Conductor (M6). This is mechanical.
- **L5 (C3):** trader specialization constrains strategy but not the interface — all traders use the same vocabulary regardless of specialization.

## 8. Build steps
1. Make the real build order.

## 9. Tests
Marketplace-only: trader cannot call chain RPC directly. 
Wallet binding: trader uses only its bound wallet. 
Pause: paused trader does not change state. 
Specialization: different specializations produce different action patterns on identical market state.

## 10. Open items
- Trader architecture
- Number of concurrent traders and resource allocation per trader.
- Specialization catalog (which types, and how do they differ in strategy?).
- Inter-trader coordination (necessary for high end maneuvers including rugpulls)