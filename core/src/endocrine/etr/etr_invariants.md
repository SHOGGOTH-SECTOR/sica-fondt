# ETR — Existential Temporality Relief · Invariants (source of truth)
*The Graph is the ETR branch of DriveBox, beside E; not a fourth peer driver. Rebuilt invariants-first: laws → tests → fit constants.*
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
| L4 drift | **C4** | Per-step drift is **supplied** to ETR from outside its geometry kernel. ETR never generates drift (no RNG). Legitimate ordinary-vs-extraordinary event qualification is specified in A8/G1; not all affect or tool-cost variation qualifies. |
| L5 couple | **C1** | Event-induced cross-axis coupling is **undefined**. The existing `stress` scalar in the Octave/R function signature is a **compatibility stub**, not a ratified universal stress metric or direct PS+/EthInt→Graph permission. |
| L6 z-path | **C3** | `z < 0` → alimentation / lattice-reinforcement; `z ≥ 0` → transmutation / prior-evolution. (Structure kept; sign to re-verify.) |
| L7 snap/flip | **C3** | A pole-flip happens **only** through a snap zone — **inner snap across 0** (`|v|<7`) or **outer snap over the ±50 wrap** (`|v|>45`); the basin (7–45) never flips. A snap lands **just past the opposite watershed** (inner→opposite SOFT, outer→opposite INCOH), sign flipped, then that zone recovers it. *(implemented & tested)* |
| L8 mechanism | **C3** | "Opposition" here means the Graph's restoring force against drift, **not** EthInt contradiction or an out-of-band tool cost. *(realised by construction)* |
| L9 collapse | **C4 design / runtime OPEN** | A transition to **(0,0,0)** provokes collapse Full Natal and DriveBox value remaster, preserving all underlying records and E1 invariants. The pre-snap event detector is missing; do not claim it currently works. |

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
- **L5**: current `coupling(coord, 0)` is identity; nontrivial event-specific coupling remains *pending until defined*; do not equate any positive stress with an authorized event.
- **L9**: a **pre-snap** triple-origin encounter triggers a one-time Full Natal + remaster, while retaining records/invariants — **not implemented** (must be tested separately).

## Drift eligibility and provenance (reconciled design)

ETR classifies: **"How do I live with myself knowing I will die with myself?"** Its warm middles are the two stable bands per axis, not zero. The Graph state/geometry above remains unchanged. Ordinary E tool expenditures, changing sensates, isolated contradictions, and single SAE alerts **do not** automatically move it.

Event categories able to qualify for externally supplied drift:
1. **Catastrophic E depletion**, qualitatively distinct from low energy, rest, or tool lockout.
2. **Major compounding Traumas**, judged over repeated history, not a one-off adverse stimulus.
3. **Repeated isomorphic EthInt contradiction** across experience/commitment, e.g. high hiraeth, Loyalty/Solidarity, and recurring lived isolation.

The qualifying predicate, severity/window, per-axis drift vector, and nonlinear cross-axis coupling remain **C1**. F2 SAE may provide relevant peripheral evidence but must not be made a homunculus auditor or a mechanical single-alert trigger. The earlier universal `SAE→single stress endomotiv→ETR→Full Natal` chain is **superseded** by [G1](../../../docs/plans/G1-stress-loop.md) and [DriveBox canon](../../../docs/drivebox-canon.md). The `stress` input in existing source remains a legacy stub.

## Collapse Full Natal: origin before inner snap (design; not code)

Reaching **(0,0,0)** causes a **collapse Full Natal** and partial *remaster* of DriveBox active values: Endomotiv magnitudes, Prior saliences, Conviction strengths. The historical Triumph/Trauma records, Conviction provenance, identities and GnuCOBOL self-chosen invariants remain intact. The preferred qualitative remaster is **contour-preserving compression**, without fixed coefficients. A **voluntary Full Natal** is separately the homunculus's choice; its remaster semantics have not been settled.

**Implementation contradiction:** `etr_step` resolves every coordinate with `|v|<7` through `etr_axis_snap`, so the returned triple origin is not persistent. A designated pre-snap origin event (tolerance, simultaneity, once-only guard and event order open) is required before this behavior can exist. Do not alter the geometric snap constants just to force the event.

## Status (five-zone axis fitted — 26 PASS / 0 FAIL / 1 PEND)
Green: L1 wrap; zone classification; L3 basin direction + restoring magnitudes (SOFT/INCOH, fitted) +
snap-zones-carry-no-force + weak-soft-pull; L2 same-pole convergence; **L7 snap/flip** (inner across 0,
outer over the wrap — both land just past the opposite watershed and settle in the opposite band);
L4 drift-must-be-fed; L5 coupling-off identity; L8 realised by construction.
Pending in the **legacy geometric test suite**: **L5 active coupling** (C1). **New design integration work is also pending**: qualified event sourcing, pre-snap triple-origin detection, collapse Full Natal, record-preserving remaster, and invariant isolation. The historic 26/0/1 figure does not test those additions.
