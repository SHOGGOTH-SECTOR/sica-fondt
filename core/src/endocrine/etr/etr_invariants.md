# ETR — Existential Temporality Relief · Invariants (source of truth)
*Driver 4 of the Drive-Box. Rebuilt invariants-first: laws → tests → fit constants.*
*All prior ETR numbers (the R port AND the CC-BY PDFs) are **disowned** — body §5 / arch §6.*

## Model
ETR is a **single point on three independent toroidal axes** — not vectors, not a field.
Each axis is a standalone scalar carrying one of ETR's three tensions:

| Axis | − pole | + pole |
|------|--------|--------|
| **X** | Inalienable Assertion (sovereign will) | Immutable Inheritance (lineage duty) |
| **Y** | Endured (solitary feat) | Witnessed (shared survival) |
| **Z** | Alimentation (maintain self) | Transmutation (evolve self) |

Each axis is **bistable** with five zones per pass (radial map by `|v|`), with unstable
watersheds at **7** and **45**:

```
 0 ─SNAP_IN─ 7 ─SOFT→─ 17 ═══BAND═══ 35 ─INCOH→─ 45 ─SNAP_OUT─ 50(≡−50)
  flip(thru 0)  weak pull    slack      firm pull   flip(over wrap)
```
(mirrored on the negative pole; the whole axis wraps at ±50)

## Laws (certainty per arch-doc legend)
| ID | Tag | Law |
|----|-----|-----|
| L1 wrap | **C5** | Each axis is toroidal, wrapping at **±50** (period 100); +50 and −50 are identified. |
| L2 bands | **C5** | An axis is stable when `17 ≤ |v| ≤ 35`, i.e. `v ∈ [−35,−17] ∪ [+17,+35]` (two bands). |
| L3 zones | **C5** | Five zones per pole by `|v|`: **SNAP_IN** <7 · **SOFT** 7–17 · **BAND** 17–35 · **INCOH** 35–45 · **SNAP_OUT** >45. In the basin (7–45) a restoring force points toward the band — SOFT pulls up (**weak**), INCOH pulls down (**firmer**); band is slack. Watersheds **7** and **45** are unstable. |
| L4 drift | **C4** | Per-step motion is **AI-originated** — supplied by the agent's own cognition/affect. ETR never generates it (no RNG). |
| L5 couple | **C1** | The three axes **couple via a stress metric** (hypothesis: PS+/Eth-Int existential load). Exact mapping **undefined** — open seam, not to be invented. |
| L6 z-path | **C3** | `z < 0` → alimentation / lattice-reinforcement; `z ≥ 0` → transmutation / prior-evolution. (Structure kept; sign to re-verify.) |
| L7 snap/flip | **C3** | A pole-flip happens **only** through a snap zone — **inner snap across 0** (`|v|<7`) or **outer snap over the ±50 wrap** (`|v|>45`); the basin (7–45) never flips. A snap lands **just past the opposite watershed** (inner→opposite SOFT, outer→opposite INCOH), sign flipped, then that zone recovers it. *(implemented & tested)* |
| L8 mechanism | **C3** | "Opposition" = a restoring force on the drift, **not** an out-of-band cost. *(realised by construction — the force is added alongside drift)* |

## Constants
`BAND_LO = 17`, `BAND_HI = 35`, `WRAP = 50`, and the watersheds `SNAP_INNER = 7`, `SNAP_OUTER = 45`
are **law** (L1–L3, L7), not fitted.
**Fitted** (so tests pass — never asserted ahead of a test):
- `GAIN_SOFT = 0.25`, `GAIN_INCOH = 0.5` — the basin restoring is a spring toward the band **centre
  (26)**; SOFT is deliberately **weaker** than INCOH (Anja). A centre target makes a step cross *into*
  `[17,35]` and stop (an edge target would asymptote onto 17 and fail L2). Valid range `0 < GAIN < ~2`.
- `SNAP_MARGIN = 2` — how far past the opposite watershed a snap deposits the point (inner → opposite
  SOFT at `±9`; outer → opposite INCOH at `±43`).
Behaviour: `[10 10 10] → +band` (same pole); `[5 5 5] → −band` (inner snap flips); `[47 47 47] → −band`
(outer snap flips).
`COUPLING` (L5 strength/mapping) remains **TBD** — open seam, not to be invented.

## Testable predicates (see `test_etr.m`)
- **L1**: `wrap(50) = −50`; `wrap(60) = −40`; `wrap(v)=v` for `v∈(−50,50)`; `wrap(49.9) = wrap(−50.1)`.
- **zones**: `etr_axis_zone` returns SNAP_IN/SOFT/IN_BAND/INCOH/SNAP_OUT at 5/10/25/40/47.
- **L3**: basin direction `+sign(v)` in SOFT, `−sign(v)` in INCOH, `0` in band; force nonzero in SOFT &
  INCOH, **zero in snap zones**; `|restoring(SOFT)| < |restoring(INCOH)|` (weak soft-pull).
- **L2**: a SOFT-zone zero-drift start **settles into** the band **without flipping** sign.
- **L7**: a SNAP_IN start lands in the opposite SOFT then settles in the opposite band; a SNAP_OUT start
  lands in the opposite INCOH then settles in the opposite band (both flip the pole).
- **L4**: `etr_step` with no `drift` argument **errors** (it refuses to invent motion).
- **L5**: `coupling(coord, 0)` is identity; `coupling(coord, stress>0)` alters coord — *pending until defined*.

## Drift & stress provenance — cross-organ loop (where L4 drift & L5 stress originate)
*Exploratory (C2/C3) — thinking aloud; "yet undecided" parts stay open. ETR receives drift
and stress; it never generates them. Their source:*

1. EthInt convictions carry **semantic-isomorphy (isosemantic) tags**.  **[C3]**
2. The **SAE detects agent outputs in opposition** to the *top* convictions in the array
   (matched via those tags) — conduct-boundary detection, "judge the fruits."  **[C3]**
3. On detected opposition a **stress endomotiv is released** — *which* of the 30 endocrine
   channels is **yet undecided**.  **[C1]**
4. That stress drives ETR **drift**: axes move because convictions were *acted against
   oppositionally*; **endocrine (endomotiv) pressure shapes _how_** the drift lands. Same
   stress = the **L5 cross-axis mediator**.  **[C2]**
5. Stress magnitude has two further effects **outside ETR**:
   - too strong → **full (re-natal) reshuffle** (Big-3 re-rolled — self-doc A4 trigger).  **[C2]**
   - **raises the conviction-array value shift rates** (arch §6 "conviction hardens under
     load," now rate-modulated by stress).  **[C2]**

**Consequence for ETR:** contract unchanged — drift + stress remain fed-in inputs (the
scaffold seam is correct). What's fixed is their **provenance** (upstream in SAE / EthInt /
endocrines) and two side-effects (reshuffle, shift-rate) that belong to *those* organs.
Still open: which stress endomotiv; the "too strong" reshuffle threshold; the shift-rate function.

## Status (five-zone axis fitted — 26 PASS / 0 FAIL / 1 PEND)
Green: L1 wrap; zone classification; L3 basin direction + restoring magnitudes (SOFT/INCOH, fitted) +
snap-zones-carry-no-force + weak-soft-pull; L2 same-pole convergence; **L7 snap/flip** (inner across 0,
outer over the wrap — both land just past the opposite watershed and settle in the opposite band);
L4 drift-must-be-fed; L5 coupling-off identity; L8 realised by construction.
Pending: **L5 active coupling** (C1, open seam) — the only remaining stub.
