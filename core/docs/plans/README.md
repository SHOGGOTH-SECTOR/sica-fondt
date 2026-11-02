# Gen.03 — Component Build Plans

One spec per **sub-organ**, each self-contained so it can be built and tested **independently**
(against stubs) with no other organ present. These are the *build* layer beneath the canonical
design docs (`../gen03_state_of_architecture.md`, `../gen03_body.md`, `../gen03_self.md`) and
`../../src/endocrine/etr/etr_invariants.md`.

## How to read a spec
The historical files use the same 10-section skeleton:
1. **Component** · 2. **Status/certainty** · 3. **Language & location** · 4. **Does / does-not** ·
5. **Interface contract** · 6. **Dependencies/runtime state** · 7. **Invariants/laws** ·
8. **Build status** · 9. **Tests/verification** · 10. **Open items**.

Active specs may also carry **§1A Operational doctrine / Measurement contract**. This is not
ornament: it states why the component exists and supplies the authority/performance semantics that
the later interface and tests must implement.

## Tight-spec standard
When an existing spec is cleaned or a new one is written, make the following explicit rather than
leaving them implicit in prose:

1. **Purpose** — what outcome the component exists to produce.
2. **Authority** — what it may decide, what may constrain it, and what it can never override.
3. **Evidence** — what information it may consume and what provenance/uncertainty must survive.
4. **Permitted decisions** — concrete state transitions or outputs it owns.
5. **Prohibited decisions** — surfaces it must literally not possess.
6. **Memory** — what repeated evidence becomes durable knowledge, with source observations linked
   rather than rewritten.
7. **Performance** — the longitudinal metric by which competence is judged.
8. **Failure condition** — what counts as architectural failure even if a local metric looks good.
9. **Completion test** — the observable evidence required before the spec may claim implementation.

Build steps should be ordered as **contract → invariant → failing test → implementation →
realization/outcome feedback → persistence**, not as a list of aspirational features.

## Economy doctrine
The M-series uses these additional commitments:
- M0's local terminal objective is durable profit; at organism scale surplus is metabolic capacity,
  especially compute budget.
- M1 is constitutional law, not strategy.
- M2 preserves evidence/provenance/contradiction and does not decide truth.
- M3 Sims are complementary scopes, not competing oracles; correctness is scope/horizon/regime
  conditioned.
- M4 hard ceilings are non-overridable per action.
- M5 Traders are independent agentic economic entities with independently assigned capital.
- Trader competence is diagnosed longitudinally by realized outcome versus its own prediction and
  declared uncertainty; P&L remains the local objective.
- M6 owns the big picture: portfolio/system risk, uncertainty regimes, ordinary veto/pause, and
  translation of broad/exceptional Brain restrictions into local enforcement.
- M7 reports evidence and recurrence; anomaly is not guilt. M6 interprets.
- Repetition matters everywhere: source reliability, Sim bias, Trader calibration, anomaly
  recurrence, and intervention outcomes become durable M0 economic memory.

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
| M0 | Economy organ hub (stomach) | Economy | EXECUTABLE SCAFFOLD | Tcl 8.6 | [M0](M0-economy-organ-hub.md) |
| M1 | Marketplace (multi-trader harness) | Economy | EXECUTABLE SIMULATION | Tcl 8.6 | [M1](M1-marketplace.md) |
| M2 | Data feeds (market data pipeline) | Economy | EXECUTABLE BUFFER/FEED CORE | Tcl 8.6 | [M2](M2-data-feeds.md) |
| M3 | Sims hub (market prediction) | Economy | MIXED: 4 V1 BRIDGES + 3 NATIVE KERNELS | Tcl + native runtimes | [M3](M3-sims-hub.md) |
| M3a | Statistical & quantitative sims | Economy/Sims | V1 IMPLEMENTED + WIRED | R | [M3a](M3a-statistical-sims.md) |
| M3b | Sociological & population sims | Economy/Sims | V1 IMPLEMENTED + WIRED | ECLiPSe Prolog | [M3b](M3b-sociological-sims.md) |
| M3c | AMM & liquidity pool sims | Economy/Sims | V1 IMPLEMENTED + WIRED | Solidity / Foundry | [M3c](M3c-amm-liquidity-sims.md) |
| M3d | MEV & adversarial extraction sims | Economy/Sims | NATIVE KERNEL | Fortran 2018 | [M3d](M3d-mev-adversarial-sims.md) |
| M3e | Tokenomics & macro-state sims | Economy/Sims | V1 IMPLEMENTED + WIRED | Fortran 2018 | [M3e](M3e-tokenomics-macro-sims.md) |
| M3f | Consensus & staking game sims | Economy/Sims | NATIVE KERNEL | ECLiPSe Prolog | [M3f](M3f-consensus-staking-sims.md) |
| M3g | Market microstructure sims | Economy/Sims | NATIVE KERNEL | Fortran 2018 | [M3g](M3g-market-microstructure-sims.md) |
| M4 | Wallets (sovereign custody) | Economy | PARTIAL: BINDING + LIMITS ONLY | Tcl 8.6 | [M4](M4-wallets.md) |
| M5 | Traders (AI actors) | Economy | PARTIAL: REGISTRY + PAUSE STATE | Tcl 8.6 | [M5](M5-traders.md) |
| M6 | Conductor (supervisory AI) | Economy | EXECUTABLE SUPERVISION SCAFFOLD | Tcl 8.6 | [M6](M6-conductor.md) |
| M7 | SAE monitor (trader surveillance) | Economy | PARTIAL: LOGGING + ALERT ENVELOPES | Tcl 8.6 | [M7](M7-sae-monitor.md) |

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
  Local objective: durable profit → organism metabolic/compute surplus.
  Marketplace [M1] ← Traders [M5] (independent assigned capital; Wallets [M4]) submit actions;
    constitutional law + absolute wallet ceilings + Conductor [M6] uncertainty/veto boundaries gate execution.
  Data Feeds [M2] → Sims [M3]. Runtime bridges are live for M3a stat, M3b socio, M3c AMM,
    and M3e tokenomics; M3d MEV, M3f consensus, and M3g microstructure are native kernels
    registered in the hub but not yet process-bridged into automatic query/publish paths.
  SAE [M7] records Marketplace-level Trader calls → alert envelopes → Conductor [M6].
  Tax is staged only; no wallet transfer occurs.
  Stomach [M0] has an Ada-bound secretion contract; the Pony↔Tcl runtime bridge to Ichor is open.
```

## Build waves
- **Wave 0** — this README + **C1** (priority).
- **Wave 1 (buildable-now)** — A1–A8, B1–B3, C2–C4, D1, D3.
- **Wave 2 (design-first)** — D2, E1–E3, F1–F3, G1–G3.
- **Economy track (active implementation)** — M0–M7 plus M3a–M3g. M3a/M3b/M3c/M3e have V1
  native runtime bridges; M3d/M3f/M3g remain native kernel implementations; M4/M5/M7 remain
  partial by design because custody, agent inference, and SAE inference are not implemented.
Each spec is independent; review as they land.
