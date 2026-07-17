# M4 — Wallets (sovereign custody)

## 1. Component
The economy organ's vault: **sovereign, local-hosted, our-custody-only cryptocurrency wallets**.
Each wallet binds to exactly one Trader (M5) — strictly 1:1 both directions. A single wallet
handles multiple chains internally (EVM, Solana, etc.). A trader without a wallet cannot access
the Marketplace (M1). Wallets hold keys, sign transactions, and enforce wallet-level spending
limits.
Tax is collected on trader income and routed to the Verschwörern Veregeister wallets (stub — M0).

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C4 (sovereign custody is a hard requirement); implementation C1.

## 3. Language & location
TBD · `src/economy/wallets/`. Needs cryptographic key management (secp256k1 for EVM, ed25519 for
Solana, etc.), HD derivation, and transaction signing. Rust or Go for crypto primitives; Python
with web3 libs for prototyping.

## 4. Does / does-not
- **Does:** generate and store private keys locally (never transmitted); sign transactions on
  behalf of the bound trader; enforce per-wallet spending limits (daily, per-transaction);
  track wallet balance and transaction history; collect tax on realized income and stage for
  transfer to Verschwörern Veregeister wallets; bind 1:1 to a Trader (M5).
- **Does-not:** decide what to trade (Trader decides); route to chain (Marketplace does);
  hold keys for the organism's other wallets (Verschwörern Veregeister are separate); delegate
  custody to any third party — ever.

## 5. Interface contract
- `create_wallet(chains: [Chain], trader_id) -> wallet_id` — generates keys for each chain,
  binds to trader. One multi-chain wallet per trader.
- `sign(wallet_id, tx: UnsignedTransaction) -> SignedTransaction` — signs with the wallet's key.
  Only the bound trader (via Marketplace) can request signing.
- `balance(wallet_id) -> { chain, assets: [{ token, amount }] }`.
- `spending_check(wallet_id, amount) -> { allowed:bool, remaining_daily:num }`.
- `tax_collect(wallet_id, income_amount) -> { tax_amount, receipt }` — computes and stages tax.
- `transfer_tax_stub(source_wallet, dest_wallet, amount) -> receipt` — **STUB** for future
  Verschwörern Veregeister internal transfer. Logs only; does not execute.
- `Chain` ∈ { `evm`, `solana`, `bitcoin`, … } — extensible.

## 6. Dependencies & stubs
- M5 Traders — 1:1 binding; *stub:* canned trader ID.
- M1 Marketplace — signing requests come through marketplace only; *stub:* direct sign call.
- Blockchain nodes — balance queries and tx broadcast; *stub:* simulated chain state.
- Verschwörern Veregeister wallets — tax destination; *stub:* log transfer.

## 7. Invariants / laws
- **L1 (C5):** **sovereign custody only** — private keys are generated locally, stored locally,
  and **never leave the wallet**. No custodial service, no exchange deposit, no MPC with external
  parties. Our keys, our coins.
- **L2 (C5):** **1:1 trader binding** — each wallet is bound to exactly one trader. A trader
  cannot use another trader's wallet. The Marketplace enforces this.
- **L3 (C4):** **signing requires Marketplace routing** — a wallet will not sign a transaction
  that didn't come through the Marketplace harness (M1-L1). No direct signing API for traders.
- **L4 (C4):** **spending limits are wallet-level** — independent of Conductor or Marketplace
  limits. Defense in depth: even if other controls fail, the wallet itself caps exposure.
- **L5 (C4):** **tax collection is automatic** — realized income triggers tax staging. The trader
  cannot opt out.

## 8. Build steps
1. Implement key generation and secure local storage (encrypted keystore).
2. Implement transaction signing for one chain (start with EVM/secp256k1).
3. Implement trader binding and Marketplace-only signing enforcement.
4. Implement spending limits (daily cap, per-tx cap).
5. Implement tax calculation and staging stub.

## 9. Tests
Custody: private key never appears in any API response or log. Binding: wrong trader cannot
sign. Marketplace-only: direct sign request (not via Marketplace) rejected. Spending limit:
over-limit transaction rejected. Tax: income event triggers correct tax amount. Multi-chain:
EVM and one other chain produce valid signatures.

## 10. Open items
- Key storage format (encrypted JSON keystore? OS keyring? HSM for production?).
- Which chains to support initially.
- Spending limit configuration (hardcoded? per-trader? adjustable by Conductor?).
- Tax rate and calculation method.
- Key rotation / backup strategy.
