# A7 — Conviction array  *(sub-organ of Eth-Int)*

## 1. Component
The lattice Eth-Int reads: the set of active principles with their convictions, **semantic-isomorphy
tags**, and **stress-driven shift-rates**. The structural self that defines the agent's integrity,
and the thing the SAE checks outputs against in the G1 stress loop.

## 2. Status / certainty
DESIGN-FIRST (extends today's flat principle list in `driver_ethical_integrity.R`). Tags + shift-rates
are new — C2/C1.

## 3. Language & location
R · new module under `src/endocrine/` (e.g. `conviction_array.R`), consumed by A6.

## 4. Does / does-not
- **Does:** hold principle entries with conviction + isomorphy tags + per-entry shift-rate; expose the
  **top convictions** for SAE matching (G1); apply hardening and stress-modulated shift-rate changes.
- **Does-not:** evaluate cost (A6 does that) or detect opposition (SAE F2 does); it is the data + its update rules.

## 5. Interface contract
- **Entry:** `{ id, conviction(0..1), antithesis[], isomorphy_tags[], shift_rate }`.
- `top_convictions(array, n) -> [entry]` (what SAE matches outputs against, G1 step 2).
- `harden(array, ids, load) -> array'` · `set_shift_rate(array, delta_from_stress) -> array'`.
- The **memory-derivative** rule: convictions are computed from memory-weighted entries (per arch §6) —
  shape = "complex entries with memory-weighted shifting numerics," same family as PS+'s priors stray.

## 6. Dependencies & stubs
SAE (F2) feeds opposition events; stress endomotiv (A4/G1) feeds shift-rate deltas — *stub:* call
`set_shift_rate` directly. Memory source (E2) for the derivative — *stub:* in-memory seed entries.

## 7. Invariants / laws
- **L1 (C2):** every conviction carries ≥1 **semantic-isomorphy tag** (so SAE can match outputs to it).
- **L2 (C2):** under G1 stress, **shift-rates increase** (convictions move faster — harden or revise).
- **L3 (C3):** hardening is bounded (→1.0, diminishing); convictions never exceed [0,1].
- **L4 (C1):** the memory-derivative formula (how memory weights produce the live conviction) — undefined.

## 8. Build steps
1. Define the entry record + tag vocabulary; encode L1/L3 as tests. 2. Add shift-rate mechanics +
the G1 hook (L2). 3. Define the memory-derivative (L4) once E2 storage lands. 4. Migrate A6 to use it.

## 9. Tests
`Rscript src/endocrine/test_conviction_array.R` (new) — L1 (tags present), L2 (stress↑ → shift-rate↑), L3 (bounds).

## 10. Open items
- **Isomorphy tag vocabulary** + how SAE matches outputs to it (C2, shared with F2/G1).
- The **memory-derivative formula** (C1).
- Shift-rate response curve to stress (C1).
