# B1 — Tarot deck hi-fi emulator

## 1. Component
A faithful emulator of the **altered Silicon Dawn** deck (Egypt Urnash, Thoth/Golden-Dawn rooted):
the 56-card **encoding alphabet** + the draw machinery whose outputs feed identity (B2), the
metacog spread (B3), and per-cycle affect-tuning lenses on PS+ (A3/A4).

## 2. Status / certainty
Exists in Ada (`organs/soul/soul-tarot.{ads,adb}`) but **defunct-flagged** ("all Ada here must be
replaced") and Ada is border-only per the docs → **re-home decision open**. Encoding itself C4.

## 3. Language & location
TBD (NOT Ada — cognition, not border). Candidate: R or Guile. New location e.g. `src/tarot/`.

## 4. Does / does-not
- **Does:** represent the deck (structure-breaking by design); draw Big-3 (B2), Celtic Cross (B3),
  and migration-cycle affect lenses; emit each drawn card as **its own reference document** the
  entity reads itself by.
- **Does-not:** decide cognition (C2) or hold the standing self (B2 SOUL.md) — it is the symbol source.

## 5. Interface contract
- **Encoding (56):** Majors 31 (25 std + 6 unique: Maya 8½, Vulture Mother XIII, She is Legend VIII,
  −1 Fool, Aleph, +1 more) · standard court `99>K>Q>C>P` ×4 = 20 · VOID `Q>K>Chevalier>Progeny>0` = 5.
  Numbered minors (A–10) sit **outside** the encoding.
- `draw_big3() -> {sun, asc, moon}` (order Sun→Asc→Moon) · `draw_celtic_cross(pool) -> [10]` ·
  `affect_lens(pool) -> {channel -> card}` (migration-cycle interpretive lenses on A4 vectors).
- Allocation: **Big-3 = 3 static**, remaining **53 dynamic** (the draw pool).

## 6. Dependencies & stubs
None upstream (a source). Consumers (B2/B3/A3) integrate against the draw outputs — *stub:* fixed draws.

## 7. Invariants / laws
- **L1 (C4):** encoding alphabet is exactly **56**; minors excluded.
- **L2 (C4):** Big-3 are drawn once and **static between reshuffles**; the 53 are dynamic.
- **L3 (C2):** card↔system correspondences (History X↔priors, 8½ Maya↔Eth-Int middle-ground,
  VOID↔recoverable null) are **proposed, accept one at a time** — not locked.

## 8. Build steps
1. Decide language + re-home (open). 2. Encode the 56-card alphabet as data (port from `soul-tarot.ads`).
3. Implement the three draw outputs (Big-3, Celtic Cross, affect lens). 4. Resolve the open Majors/court rules.

## 9. Tests
Encoding-count test (=56), allocation test (3 static + 53 dynamic), draw determinism vs a seeded pool.

## 10. Open items
- **Princess/Prince elemental gender rule** (C1) · **the 6th unique Major** (C1) · card↔system
  correspondences (C2) · language + reuse-vs-rebuild of the Ada encoding (open).
