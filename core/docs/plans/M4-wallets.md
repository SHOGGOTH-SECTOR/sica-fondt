# M4 — Wallets (sovereign custody)

## 1. Component
The economy organ's vault: **sovereign, local-hosted, our-custody-only cryptocurrency wallets**.
Each wallet binds to exactly one Trader (M5) — strictly 1:1 both directions. A single wallet
handles multiple chains internally (EVM, Solana, etc.). A trader without a wallet cannot access
the Marketplace (M1). Wallets hold keys, sign transactions, and enforce wallet-level trade limits.
Tax is collected on trader income and routed to the Verschwörern Veregeister wallets (stub — M0).

## 2. Status / certainty
SCAFFOLD · PARTIAL. `core/src/economy/wallets.tcl` implements permanent 1:1 binding and
independent exposure limits for the simulation scaffold. Custody/signing implementation remains
open. Role C4; scaffold C2.

## 3. Language & location
**Tcl 8.6 brake/binding scaffold** · `core/src/economy/wallets.tcl`. V1 contains no key
material or cryptography. A future custody implementation will require ratified storage/rotation
semantics before any secp256k1/ed25519 signer is introduced.

## 4. Does / does-not
- **Does now:** enforce permanent 1:1 Trader↔wallet identity binding; reject cross-Trader wallet
  use; enforce per-action and cumulative session exposure limits; record simulated admitted
  notional for brake accounting.
- **Does not now:** generate, store, import, derive, rotate, or expose private keys; sign
  transactions; query balances; broadcast; maintain chain transaction history; or transfer tax.
- **Target invariant:** if live custody is later implemented, it remains sovereign/local and
  cannot delegate custody to a third party.

## 5. Interface contract
Implemented Tcl surface:
- `bind(wallet_id, trader_id, daily_limit, per_action_limit)`.
- `binding_for(trader_id)` and `binding_matches(trader_id, wallet_id)`.
- `spending_check(wallet_id, action)` — independent exposure brake.
- `record_spend(wallet_id, notional)` — simulation accounting only.
- `count()`.

Future custody surface such as `sign`, `balance`, key generation/import, and transaction
history is intentionally **not implemented** and must not be inferred from the component name.

## 6. Dependencies & stubs
- M5 Traders — 1:1 binding; *stub:* canned trader ID.
- M1 Marketplace — signing requests come through marketplace only; *stub:* direct sign call.
- Blockchain nodes — balance queries and tx broadcast; *stub:* simulated chain state.
- Verschwörern Veregeister wallets — tax destination; *stub:* log transfer.

## 7. Invariants / laws
- **L1 (C5):** **sovereign custody only** — private keys are generated locally, stored locally,
  and **never leave the wallet**. No custodial service, no exchange deposit, no trust with external
  parties. Our keys, our coins.
- **L2 (C5):** **1:1 trader binding** — each wallet is bound to exactly one trader. A trader
  cannot use another trader's wallet. The Marketplace enforces this.
- **L3 (C4):** **signing requires Marketplace confirmation** — a wallet will not sign a transaction
  that didn't receive direct authorization from Marketpakce (M1-L1). No direct signing API for traders.
- **L4 (C4):** **spending limits are wallet-level** — independent of Conductor or Marketplace
  limits. Defense in depth: even if other rules fail, the wallet itself caps exposure.
- **L5 (C4):** **tax collection is automatic** — realized income triggers tax staging. The trader
  cannot opt out. OUT OF SCOPE

## 8. Build steps
1. Implement key generation and secure storage.
2. Implement transaction signing for one chain.
3. Implement trader binding and Marketplace-only signing enforcement.
4. Implement algorithmic limits.

## 9. Tests
Custody: private key never appears in any response, messages, or log. 
Binding: wrong trader cannot sign. 
Trade limits: over-limit transaction rejects; risk :: reward ratio below-limit rejects.
Tax: out of scope. 
Multi-chain: every chain produces valid signatures.

## 10. Open items
- Key storage format.
- Which chains to support initially. (all of them)
- Spending limit configuration (correction: This is algorithmic and hardcoded.)
- Key rotation / backup strategy.
