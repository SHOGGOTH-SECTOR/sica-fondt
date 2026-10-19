# M0 — Economy organ hub (the stomach)

## 1. Component
The economy organ — the organism's **stomach**. An **independent, self-governing system**: a
multi-agentic market prediction oracle and cryptocurrency trading engine. Houses the Marketplace
(M1), Data Feeds (M2), Sims (M3), Wallets (M4), Traders (M5), Conductor (M6), and SAE monitor
(M7). Communicates with the rest of the organism **via Ichor only** — reward signals back to the
organism are TBD and out of scope.

"A stomach rarely consults a brain for permission to digest." The economy organ operates with
**scoped autonomy** and **multiple layers of failsafe braking** — it does not ask the organism's
Brain for permission to trade.

## 2. Status / certainty
SCAFFOLD · EXECUTABLE. The existing Ichor `Stomach` primitive now has a dedicated
M0–M7 simulation scaffold under `core/src/economy/`. M0 composes the component facades and
emits Ada-bound secretion metadata; external execution and the Pony↔Tcl runtime bridge remain
separate integration work. Role C4; scaffold implementation C2.

## 3. Language & location
**Tcl 8.6 scaffold** · `core/src/economy/`. M0 orchestration is Tcl and preserves the
existing polyglot plan for later component engines. Pony remains the Ichor-facing transport layer;
the runtime bridge between Ichor and this scaffold is still open.

## 4. Does / does-not
- **Does:** host crypto/NFT trading via the Marketplace (M1); run always-on market prediction
  Sims (M3) fed by live Data Feeds (M2); manage sovereign-custody Wallets (M4); supervise
  Traders (M5) via a Conductor (M6); guard against anomalies via SAE monitor (M7); collect taxes
  on trader income and stub transfer to Verschwörern Veregeister wallets; maintain a **ledger of
  economy-related memories and patterns** (trade history, learned market patterns, calibration
  state).
- **Does-not:** consult the organism's Brain for trade decisions (scoped autonomy); route around
  Ada for organism-bound messages (S1); store **organism** memories (E*) — economy-specific
  memories stay local; act as the organism's conscience (that's Eth-Int / A6).

## 5. Interface contract
- **Ichor interface (outbound):** `Envelope(Stomach, AdaBorder, OrganSecretion, payload)` — market
  state summaries, prediction digests, and tax receipts cross Ada to reach the inner brain.
- **Ichor interface (inbound):** organism directives arrive via Ichor (e.g. risk posture changes,
  budget adjustments from A2 energy).
- **Internal wiring:** Marketplace (M1) ↔ Data Feeds (M2) ↔ Sims (M3). Wallets (M4) bind to
  Traders (M5). Conductor (M6) supervises Traders (M5). SAE (M7) acts as an independent
  antivirus / guarddog / alarm bell — monitors via Ichor-routed messages and alerts M6.
  All trader actions route through Marketplace.
- **Tax stub:** `transfer_tax(amount, source_wallet, dest_wallet) -> receipt` — automation hook
  for Verschwörern Veregeister internal wallet-to-wallet transfer. **Out of scope** — stub only.

## 6. Dependencies & stubs
- Ichor bus (D2) — existing `Broker` + `Envelope`.
- Ada border (D1) — outbound economy envelopes cross here (S1); *stub:* Ichor `Barrier`.
- A2 energy — potential consumer of economic signals; *stub:* no integration initially.
- Verschwörern Veregeister wallets — tax destination; *stub:* log transfer, no real wallet.

## 7. Invariants / laws
- **L1 (C5):** the stomach is an **OUTER** organ — it rides Ichor, never the inner bus.
- **L2 (C5):** **scoped autonomy** — the organ trades without Brain permission, but within
  deterministic law constraints (M1) and Conductor oversight (M6).
- **L3 (C4):** **all market actions route through the Marketplace** (M1) — no trader may
  execute directly on-chain without the Marketplace harness.
- **L4 (C4):** **sovereign custody only** — all wallets are local-hosted, our keys, never
  delegated to exchanges or third parties (M4).
- **L5 (C4):** **multi-layered braking** — deterministic law script (M1), Conductor veto (M6),
  SAE surveillance (M7), and wallet-level limits (M4) each independently constrain risk.

## 8. Build steps
1. Build sub-components (M1–M7) individually — each with defined success criteria and ablative tests.
2. Extend the existing `Stomach` primitive in Ichor to carry the hub facade.
3. Define internal wiring topology and connect tested sub-components.
4. Implement tax stub and Verschwörern Veregeister transfer last.

## 9. Tests
Executable contract suite: `tclsh core/src/economy/tests/stomach.test`. The current 17
tests cover admission ordering, 1:1 binding, simulation-only execution, monitor logging,
supervisor pause/resume, bounded predictions, feed backpressure, exposure limits, tax staging,
Ada-bound secretion, all seven M3 engine registrations, source presence, the six horizon clocks,
and the running scheduler. Native simulator tests are driven by
`tclsh core/src/economy/sims/run_tests.tcl`. Ichor runtime bridging remains a separate
integration test.

## 10. Open items
- Reward signal protocol from economy organ to organism (TBD, out of scope).
- Internal communication bus (reuse Ichor internally? separate actor topology?).
- Language choices per sub-component.
