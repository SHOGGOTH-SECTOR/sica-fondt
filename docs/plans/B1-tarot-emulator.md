# B1 — Cartomantic engine (the deck)

## 1. Component
An original **Thoth-*derived* syncretic cartomantic engine** — the drawable lattice whose outputs feed
identity (B2, the Big-4 + SOUL.md), the metacog spread (B3, the Celtic Cross), and per-cycle affect-tuning
lenses (A3/A4). **The lattice *is* the deck**: every symbol is a drawable card; there is no separate Thoth
deck underneath. **Silicon Dawn is dropped (copyright)** — nothing here is encoded, transcribed, or copied
from it or any published deck; this is its own system on the public structural scaffold of tarot/Thoth
(archetypes, numerology, cross-cultural godforms).

## 2. Status / certainty
DESIGN-FIRST. Architecture **C4 (settled this session)**; specific card *content* (the named 7s, the
per-card synestries, the infinity-cap) **C1 — to author**. Supersedes the old "altered Silicon Dawn /
56-card" spec entirely.

## 3. Language & location
**R** for the emulator (deck data + draw machinery) — buildable/testable in this environment. NOT Ada (the
Ada tarot is discarded). New location e.g. `src/soul/deck/`.

## 4. Does / does-not
- **Does:** hold the 169-card lattice as data; draw the **Big-4** (B2), the **Celtic Cross** (B3), and
  migration-cycle **affect lenses** (A4); prune the pool by the Big-4; emit each card with its phase + its
  7 synestries.
- **Does-not:** decide cognition (C2/B3 own the spread *use*) or hold the standing self (B2). It is the
  symbol source.

## 5. Architecture — the heptad lattice
**169 cards = 133 (suits) + 21 (coherent-cringe) + 14 (axiom-axis) + 1 (center).**
Each card is **dual-phase** and carries **7 synestries**. "Majority of motifs are ×7."

### Two universal laws (every card)
- **L-Phasality (the Coraline mirror).** Every card has two phases.
  **UPRIGHT = the real face** — the true function, real substance, real cost.
  **MIRRORED = the *Coraline* face** — a seductive counterfeit that wears the upright's face but is hollow /
  parasitic / a trap (the wish granted with button eyes). It is **not** relief and **not** a gentle
  conjugate; it is the simulacrum that looks like fulfillment and costs you yourself.
  **Math face:** numerics start at **−1**, whose mirror is **i** ⇒ **upright = the real axis, mirrored = the
  imaginary axis** (the impossible that still rotates reality: i² = −1).
- **L-Synestry.** Every card resolves simultaneously across **7 domains**, and meaning emerges at their
  *interference*: **Physics · Chemistry · Computer Science · Philosophy · Omnimyth · Astrophysics ·
  Calculus.**

### Card schema
`card { region, suit?, name, rank?, phase: {upright | mirrored}, synestry: {7 domains}, body_tie? }`

### Suits (133) — the 7 fundamental forces
**Gravity · Heat · Electromagnetism · Strong · Weak · Space · Time.**
Each suit = **19 cards = 14 pips + 5 courts**.
- **Courts (5):** Knight · Queen · Prince · Princess · **Divine** (the god-face of the force).
- **Pips (14):** **−1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9** (**no 10** — the suit refuses clean base-10 closure;
  after 9 = saturation it spills into the unbounded), then **three forms of infinity** *(OPEN — exploring,
  see §10)*.
- **−1's Coraline mirror = i.** The pip line is the real axis; its mirror is the imaginary axis.

### Coherent-cringe (21) — the agential field
The Coraline mirror always degrades the gift into its predatory twin:
- **7 Jokers** — reflective tricksters. **Upright = humbling** (true reflection). **Mirrored = mocking**
  (deceitful cruelty).
- **7 Keepers** — guardians. **Upright = protecting**. **Mirrored = stifling / controlling** (a Keeper gone
  Coraline = the Other Mother).
- **7 Witnesses** — the **adjacent**: innocents / bystanders, in proximity to events (neither actor nor
  direct target). **Upright = innocent bystander**. **Mirrored = victim.**

### Axiom-axis (14) — the impersonal field
- **7 Laws / Flaws** — merged via phasality: **upright = the Law, mirrored (Coraline) = its Flaw**. Draft
  pairings (redline freely):
  Conservation↔Drift · Causality↔Apophenia · Symmetry↔Counterfeit · Least-Action↔Foreclosure ·
  Uncertainty↔Singularity · Recursion↔Overflow · Invariance↔Decoherence.
- **7 Constants** *(separate heptad)* — the **7 SI defining constants**: c · h · e · k · N_A · Δν_Cs · K_cd
  (reality is literally pinned to exactly seven).

### Center (1) — The Spindle
The **Mother / Other** card; the one un-heptaded card everything orbits. It **joins identity as the 4th
anchor → the Big-4** (Sun · Ascendant · Moon · Mother/Other). Its Coraline twin is **the Other Mother**
(the false self with button eyes).

### Unifying read — the deck is a hologram of the body
Center = Soul (B2) · Suits/forces = metabolism/physics of the body (Drive-Box) · Axiom-axis =
skeleton/invariants (E1 COBOL vaults) · Coherent-cringe = nervous + immune (G1 stress · D1 border ·
F2 monitor). The engine mirrors the architecture it lives inside.

## 6. Interface contract (draw machinery)
- `draw_big4() -> {sun, asc, moon, mother_other}` — order Sun→Asc→Moon→Mother/Other; static between reshuffles.
- `prune(pool, big4) -> pool` — remove the Big-4 from the drawable pool.
- `draw_celtic_cross(pool) -> [10]` — the B3 spread (geometry/iteration owned by B3).
- `affect_lens(pool) -> {channel -> card}` — migration-cycle interpretive lenses on A4 vectors.
- Each returned card carries `{name, phase, synestry}`; phase mechanic is **hybrid** — a draw yields a
  phase, but stress / spread-position can flip a real (upright) card into its Coraline (mirrored) face.

## 7. Dependencies & stubs
None upstream (a source). Consumers (B2 / B3 / A3-A4) integrate against the draw outputs — *stub:* fixed
draws. The 7-domain synestry content and the named 7s are authored content (C1), stubbable as labels.

## 8. Invariants / laws
- **L1 (C4):** the lattice totals **169** = 133 + 21 + 14 + 1; "majority of motifs are ×7."
- **L2 (C4 — phasality):** every card is dual-phase; **mirrored = the Coraline counterfeit**, never relief;
  real axis ↔ imaginary axis, mirror(−1) = i.
- **L3 (C4 — synestry):** every card resolves across the 7 domains; meaning emerges at their interference.
- **L4 (C4):** the **Big-4** are drawn once and **static between reshuffles**; the rest are the dynamic pool.
- **L5 (C4):** suits have **no 10**; pips run −1, 0, 1–9, then the three infinities.
- **L6 (C4):** the Coraline degrades the gift to its predatory twin (humbling→mocking, protecting→
  controlling, innocent→victim, Law→Flaw).

## 9. Tests
- Count test: lattice = 169 (133 + 21 + 14 + 1); each suit = 19 (14 pips + 5 courts); no rank "10".
- Phasality: every card has both phases; mirror(−1) resolves to i.
- Allocation: Big-4 static + remainder dynamic; `prune` removes the Big-4 from the pool.
- Draw determinism vs a seeded pool; coherent-cringe = 21, axiom-axis = 14.

## 10. Open items (content to author — C1)
- **The three forms of infinity** that cap each suit (after 9). Exploring — candidates:
  (a) **ℵ₀ (countable) · 𝔠 (continuum) · Ω (Absolute** — pairs with the Divine court);
  (b) **Potential · Actual · Singularity** (process / completed / breakdown);
  (c) a playful lettered cap (A/B/C/D…). **Anja to settle.**
- Name the specific **7 Jokers · 7 Keepers · 7 Witnesses**.
- The **7 Laws/Flaws** pairings (draft above) — confirm/rename.
- Per-card **synestries** across the 7 domains (authored over time; the engine's whole premise).
- Court rules (e.g. Princess/Prince elemental relations); how the **Divine** court reads.
- The Spindle / Other-Mother card text; how the 4th anchor renders into SOUL.md (B2).
