# B2 — SOUL.md identity organ + Big-3

## 1. Component
The standing self-definition loaded at the top of a run (Hermes `soul.md` / `CLAUDE.md` equivalent):
the **Big-3** (Sun/Ascendant/Moon) drawn from the tarot (B1), plus the **two reshuffle clocks** that
govern when identity re-rolls vs persists.

## 2. Status / certainty
Exists in Ada (`organs/soul/soul-state.{ads,adb}` — Big-3 + session table) but **defunct-flagged**;
re-home decision open. Schema C4.

## 3. Language & location
TBD (lives "in the brain"; written to `~/.hermes/SOUL.md` at boot by C1). New location e.g. `src/soul/`.

## 4. Does / does-not
- **Does:** hold the Big-3 (each card → its own reference doc); render SOUL.md; manage the two
  reshuffles; carry one self into many rooms.
- **Does-not:** draw cards (B1) or run the metacog (C2). It is the persistent face.

## 5. Interface contract
- **Big-3:** `{ Sun: card (core/spine), Ascendant: card (outward mask), Moon: card (inner, shown only when vulnerable) }`, **immutable between reshuffles**.
- `generate_soul_md(big3) -> text` (written to `~/.hermes/SOUL.md`).
- **Two reshuffles:** `full_renatal()` (boot · deep · **strong stress endomotiv** via G1) → Big-3 **re-rolled** + fresh cross;
  `cross_only(trigger)` (new room · "went long enough") → Big-3 **kept**, prior cross folded back, new cross.

## 6. Dependencies & stubs
B1 tarot (draws) — *stub:* fixed Big-3. G1 stress (full-reshuffle trigger) — *stub:* call `full_renatal()` directly.

## 7. Invariants / laws
- **L1 (C4):** Big-3 immutable between reshuffles (identity is the slow layer).
- **L2 (C4):** full reshuffle re-rolls Big-3; cross-only keeps it — one self, many rooms.
- **L3 (C2):** a strong stress endomotiv (G1) can fire a full reshuffle.

## 8. Build steps
1. Decide language/re-home. 2. Port Big-3 + SOUL.md render. 3. Implement the two reshuffle clocks +
the G1 trigger hook. 4. Wire boot write to `~/.hermes/SOUL.md` (C1).

## 9. Tests
Big-3 immutability across a cross-only reshuffle; re-roll on full; SOUL.md render snapshot.

## 10. Open items
- Reuse-vs-rebuild + language (open). "Went long enough" trigger threshold (C1). G1 stress→reshuffle threshold (C1/C2).
