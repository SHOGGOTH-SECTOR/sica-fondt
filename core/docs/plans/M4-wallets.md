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

## 6. Dependencies & runtime state
- M5 Traders — implemented identity registry for 1:1 binding.
- M1 Marketplace — implemented caller of binding/exposure checks.
- Blockchain nodes / signing libraries — absent.
- Tax destination wallets — no transfer surface; M0 only stages receipt metadata.

## 7. Invariants / laws
- **L1 (C5 target):** **sovereign custody only** if custody is implemented. V1 contains no keys at
  all, which is stronger than accidentally introducing an unratified custody path.
- **L2 (C5):** **1:1 trader binding** — each wallet is bound to exactly one trader. A trader
  cannot use another trader's wallet. The Marketplace enforces this.
- **L3 (C4 target):** future signing requires Marketplace confirmation. V1 has no signing API for
  Marketplace or Traders.
- **L4 (C4):** **spending limits are wallet-level** — independent of Conductor or Marketplace
  limits. Defense in depth: even if other rules fail, the wallet itself caps exposure.
- **L5 (C4 target/out of scope):** realized-income tax policy may trigger staging/transfer later.
  V1 only exposes an M0 receipt-staging hook; M4 performs no tax action.

## 8. Build status
1. **Done:** permanent 1:1 Trader↔wallet binding.
2. **Done:** per-action and cumulative session exposure brakes.
3. **Done:** Marketplace-only use of the implemented wallet scaffold.
4. **Open by design:** key generation/storage, signing, balances, chain adapters, rotation/backup.

## 9. Tests
Current tests verify walletless rejection, wrong-Trader binding rejection, independent per-action
and cumulative exposure limits, and simulated spend accounting. There are intentionally no
signature/multi-chain custody tests because no key/signing implementation exists.

## 10. Open items
- Ratified key storage, backup, recovery, and rotation design.
- Chain/signature support only after custody is ratified.
- Persistent time-window semantics for the currently session-cumulative exposure limit.
- Balance/transaction-history model if live custody is introduced.
