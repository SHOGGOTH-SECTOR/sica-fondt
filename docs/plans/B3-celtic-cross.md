# B3 — Celtic Cross spread (metacognitive draw)

## 1. Component
The 10-card spread drawn from the 53-card dynamic pool each cycle, dealt **2/2/2/4** across the four
metacog rounds and **applied iteratively** so the spread compounds — by final cognition all ten shape
the loop at once. Doubles as the **semantic diffusion-shield** (G3).

## 2. Status / certainty
Exists in Ada (`organs/soul/soul-celtic_cross.{ads,adb}`, 280 L) but **defunct-flagged**; re-home open. C4.

## 3. Language & location
TBD (with B1/B2). New location e.g. `src/tarot/celtic_cross`.

## 4. Does / does-not
- **Does:** draw 10 from the pool; deal in pairs across rounds (2/2/2/4); keep each drawn pair in play
  for subsequent rounds (iterative); supply the cards C2 applies as cognitive lenses.
- **Does-not:** run the metacog passes (C2) or decide layout semantics beyond the draw.

## 5. Interface contract
- `draw(pool53) -> spread[10]` · `deal_round(spread, round∈1..4) -> cards_active_so_far`
  (round 1→2 cards, 2→4, 3→6, 4→10). Cards apply **iteratively** (compounding).
- Pool excludes the 3 static Big-3; folds prior cross back on cross-only reshuffle (B2).

## 6. Dependencies & stubs
B1 pool — *stub:* fixed 53-card pool. C2 consumes the per-round active set — *stub:* print the cards.

## 7. Invariants / laws
- **L1 (C4):** exactly 10 cards, dealt 2/2/2/4, **iteratively compounding** (all 10 active by round 4).
- **L2 (C4):** drawn from the 53 dynamic only (never the Big-3).
- **L3 (C4):** the accumulating spread **is** the diffusion-shield (meaningful tokens, not noise).

## 8. Build steps
1. Decide language/re-home. 2. Port draw + 2/2/2/4 iterative dealing. 3. Wire into C2's round structure.
4. Evaluate custom vs traditional 10-position layout (non-blocking).

## 9. Tests
Draw size (=10), per-round counts (2/4/6/10), no-Big-3-in-pool, determinism vs seed.

## 10. Open items
- Celtic Cross **layout positions** — keep traditional 10 or design a custom cognitive spread (C1, non-blocking).
- Language/re-home (open).
