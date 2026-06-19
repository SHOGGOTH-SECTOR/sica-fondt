# C2 — 4+4 Metacognition cycle

## 1. Component
The dual-tradition metacognitive multicycle: **four Western + four non-Western** reflective passes,
interleaved and **paired for friction** (not confirmation), with Celtic-Cross cards (B3) applied
iteratively across the rounds.

## 2. Status / certainty
Partial — the *orchestration* (phase ordering) exists in Ada (`ada_medium` phase enums), defunct-flagged;
the philosophical passes themselves are unimplemented. Structure C4; pass content C1.

## 3. Language & location
TBD (cognition, runs inside the descent below Ada). Likely prompt/skill content driven by the harness (C1)
+ orchestration in the cycle (C3). New location e.g. `src/metacog/`.

## 4. Does / does-not
- **Does:** run the 8 passes in the fixed order, each pass straining against its partner; apply the
  accumulating B3 spread; generate cognitive heat from opposed traditions held in simultaneous load.
- **Does-not:** route tools or decide composition dynamically — ordering is **static**; responsiveness is
  Energy-gated (skip later passes when E low, per C1/A2).

## 5. Interface contract
- **The 4 friction pairs (fixed):** wMC1 Socratic *aporia* ↔ eMC1 Iranian Asha · wMC2 Kant boundaries ↔
  eMC2 East-Asian empty mirror · wMC3 Freud/Hegel shadow ↔ eMC3 Indic witness · wMC4 Modern pragmatic ↔
  eMC4 Tibetan Bön flow. Bridges: Socrates↔Hegel; Archimedean–Socratic.
- `run_pass(n, state, active_cards) -> reflection` (n=1..4 ⇒ wMCn then eMCn, then draw B3 pair).
- Energy-gating: a low-E snapshot (A2) reduces how many passes run.

## 6. Dependencies & stubs
B3 cards — *stub:* fixed spread. Brain/LLM (C4) executes the passes — *stub:* echo the pass label.
Energy (A2) for gating — *stub:* scalar.

## 7. Invariants / laws
- **L1 (C5):** pairing principle = **friction, not confirmation**.
- **L2 (C4):** composition is **static** (no learned router); compute scales via Energy only.
- **L3 (C4):** cards apply **iteratively** — by final cognition all 10 (B3) are concurrently in play.

## 8. Build steps
1. Encode the 8-pass order + pairings as data + an L1/L2/L3 test. 2. Author each pass's content
   (prompt/skill) — invariants-first (the friction each pair must produce). 3. Wire B3 + Energy-gating.

## 9. Tests
Order/pairing test; iterative-card test; Energy-gating reduces pass count at low E.

## 10. Open items
- **LOGIA consciousness strata** (Pre/Sub/Un/Conscious) — overlay the Western quad or stratify separately? (C1)
- Pass content authoring (C1). Energy→pass-count curve (C1, shared with C1/A2).
