# Gen.03 — Component Build Plans

One spec per **sub-organ**, each self-contained so it can be built and tested **independently**
(against stubs) with no other organ present. These are the *build* layer beneath the canonical
design docs (`../gen03_state_of_architecture.md`, `../gen03_body.md`, `../gen03_self.md`) and
`../../src/endocrine/etr/etr_invariants.md`.

## How to read a spec
Every `NN-<organ>.md` has the same 10 sections:
1. **Component** · 2. **Status/certainty** · 3. **Language & location** · 4. **Does / does-not** ·
5. **Interface contract** (language-agnostic data shapes — integrate against *this*) ·
6. **Dependencies & stubs** · 7. **Invariants/laws** (certainty-tagged) · 8. **Build steps**
(invariants-first: laws → tests → fit) · 9. **Tests** (standalone command) · 10. **Open items**.

## Conventions
- **Certainty tags** (from arch doc): C5 ratified · C4 drafted · C3 partial · C2 explored · C1 stub.
- **Invariants-first / restart discipline:** no curve/bound/threshold/sign carried forward
  unverified. Any unfitted constant is marked **C1**, never asserted ahead of a test.
- **Independence:** a spec depends only on the *contracts* (§5) of other organs, never their code,
  and never the still-unnamed medium (D2). §6 ships a canned stub for each upstream input.

## Index
| # | Component | System | Status | Lang | Spec |
|---|-----------|--------|--------|------|------|
| C1 | **OpenHermes ↔ metacog** | Cognition | DESIGN-FIRST (priority) | OpenHermes/Ada | [C1](C1-openhermes-metacog.md) |
| A1 | Drive-Box hub / input-slot | Drive-Box | WORKING | R | [A1](A1-drivebox-hub.md) |
| A2 | Energy (E) driver | Drive-Box | structure WORKING · numbers DISOWNED | R | [A2](A2-energy.md) |
| A3 | PS+ driver | Drive-Box | structure WORKING · numbers DISOWNED | R | [A3](A3-psplus.md) |
| A4 | Endomotiv array (30-ch) | Drive-Box | WORKING · channels partial | R | [A4](A4-endomotiv-array.md) |
| A5 | Priors database | Drive-Box | structure WORKING | R | [A5](A5-priors.md) |
| A6 | Eth-Int driver | Drive-Box | structure WORKING · numbers DISOWNED | R | [A6](A6-ethint.md) |
| A7 | Conviction array | Drive-Box / Eth-Int | DESIGN-FIRST | R | [A7](A7-conviction-array.md) |
| A8 | ETR (torus) | Drive-Box | five-zone law fitted · 26/0/1 (+ R port) | Octave · R | [A8](A8-etr.md) |
| B1 | Tarot deck hi-fi emulator | Identity | exists (defunct-flagged) | TBD | _wave 1_ |
| B2 | SOUL.md identity + Big-3 | Identity | exists (defunct-flagged) | TBD | _wave 1_ |
| B3 | Celtic Cross spread | Identity | exists (defunct-flagged) | TBD | _wave 1_ |
| C2 | 4+4 Metacognition cycle | Cognition | partial (orchestration) | — | _wave 1_ |
| C3 | Inference cycle orchestration | Cognition | exists (defunct-flagged) | Ada | _wave 1_ |
| C4 | Brain (swappable LLM) | Cognition | STUB/external | — | _wave 1_ |
| D1 | Ada border (immune+BBB) | Border | WORKING | Ada/SPARK | _wave 1_ |
| D2 | The medium / "the blood" | Border | DESIGN-FIRST | — | _wave 2_ |
| D3 | Mini-rag / toolschema | Border | STUB | GNU Guile | _wave 1_ |
| E1 | 3 GnuCOBOL invariant stores | Storage | DESIGN-FIRST | GnuCOBOL | _wave 2_ |
| E2 | VARIANT stores | Storage | DESIGN-FIRST | TBD | _wave 2_ |
| E3 | RAG family + cross-store | Storage | DESIGN-FIRST | TBD | _wave 2_ |
| F1 | MoRAG (BERT+LoRA) | Periphery | DESIGN-FIRST | TBD | _wave 2_ |
| F2 | SAE monitor | Periphery | DESIGN-FIRST | TBD | _wave 2_ |
| F3 | Subagents framework | Periphery | DESIGN-FIRST | TBD | _wave 2_ |
| G1 | Stress-loop contract | Cross-cut | C1/C2 | — | _wave 2_ |
| G2 | Governance | Cross-cut | DESIGN-FIRST (C2) | TBD | _wave 2_ |
| G3 | Defense model | Cross-cut | emergent | — | _wave 2_ |
| M0 | Economy organ hub (stomach) | Economy | DESIGN-FIRST | TBD | [M0](M0-economy-organ-hub.md) |
| M1 | Marketplace (multi-trader harness) | Economy | DESIGN-FIRST | TBD | [M1](M1-marketplace.md) |
| M2 | Data feeds (market data pipeline) | Economy | DESIGN-FIRST | TBD | [M2](M2-data-feeds.md) |
| M3 | Sims hub (market prediction) | Economy | DESIGN-FIRST | TBD | [M3](M3-sims-hub.md) |
| M3a | Statistical & quantitative sims | Economy/Sims | DESIGN-FIRST | TBD | [M3a](M3a-statistical-sims.md) |
| M3b | Sociological & population sims | Economy/Sims | DESIGN-FIRST | TBD | [M3b](M3b-sociological-sims.md) |
| M3c | AMM & liquidity pool sims | Economy/Sims | DESIGN-FIRST | TBD | [M3c](M3c-amm-liquidity-sims.md) |
| M3d | MEV & adversarial extraction sims | Economy/Sims | DESIGN-FIRST | TBD | [M3d](M3d-mev-adversarial-sims.md) |
| M3e | Tokenomics & macro-state sims | Economy/Sims | DESIGN-FIRST | TBD | [M3e](M3e-tokenomics-macro-sims.md) |
| M3f | Consensus & staking game sims | Economy/Sims | DESIGN-FIRST | TBD | [M3f](M3f-consensus-staking-sims.md) |
| M3g | Market microstructure sims | Economy/Sims | DESIGN-FIRST | TBD | [M3g](M3g-market-microstructure-sims.md) |
| M4 | Wallets (sovereign custody) | Economy | DESIGN-FIRST | TBD | [M4](M4-wallets.md) |
| M5 | Traders (AI actors) | Economy | DESIGN-FIRST | TBD | [M5](M5-traders.md) |
| M6 | Conductor (supervisory AI) | Economy | DESIGN-FIRST | TBD | [M6](M6-conductor.md) |
| M7 | SAE monitor (trader surveillance) | Economy | DESIGN-FIRST | TBD | [M7](M7-sae-monitor.md) |

## Integration DAG (who feeds whom)
```
Hermes ──> [C1] ──> Inference cycle [C3] ──┬─ pulls Drive-Box snapshot [A1]
                                            │      A1 ← A2,A3,A6,A8 ; A3 ← A4,A5 ; A6 ← A7
                                            ├─ draws Tarot [B1] → Big-3/SOUL [B2], Celtic Cross [B3]
                                            ├─ runs 4+4 metacog [C2] (iterative B3 cards)
                                            ├─ MoRAG injects [F1] ─┐
                                            │  Drive-Box secretes [A1] ─┤→ Ada border [D1] polices → Brain [C4]
                                            ├─ mini-rag packs schema [D3]
                                            └─ Ada routes tools [D1]
SAE [F2] watches Subagents [F3];  stress-loop [G1]: F2 → A7 (EthInt) → stress endomotiv (A4) → A8 drift + full reshuffle (B2)
Storage: INVARIANT [E1] / VARIANT [E2] / RAG+cross-store [E3] sit behind D1.  Medium [D2] = the perfusion bus (unnamed).
Economy (stomach — independent, scoped autonomy):
  Marketplace [M1] ← Traders [M5] (bound to Wallets [M4]) submit actions; law script + Conductor [M6] veto gate execution.
  Data Feeds [M2] ↔ Sims [M3: M3a stat, M3b socio, M3c AMM, M3d MEV, M3e tokenomics, M3f consensus, M3g microstructure].
  SAE [M7] monitors all Trader tool calls → alerts Conductor [M6].  Tax → Verschwörern Veregeister wallets (stub).
  Stomach [M0] ↔ organism via Ichor; reward signals TBD.
```

## Build waves
- **Wave 0** — this README + **C1** (priority).
- **Wave 1 (buildable-now)** — A1–A8, B1–B3, C2–C4, D1, D3.
- **Wave 2 (design-first)** — D2, E1–E3, F1–F3, G1–G3, M0–M7 (+ M3a–M3g sim sub-specs).
Each spec is independent; review as they land.
