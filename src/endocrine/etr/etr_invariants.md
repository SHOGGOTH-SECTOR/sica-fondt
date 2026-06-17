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

## Laws (certainty per arch-doc legend)
| ID | Tag | Law |
|----|-----|-----|
| L1 wrap | **C5** | Each axis is toroidal, wrapping at **±50** (period 100); +50 and −50 are identified. |
| L2 bands | **C5** | An axis is stable when `17 ≤ |v| ≤ 35`, i.e. `v ∈ [−35,−17] ∪ [+17,+35]`. |
| L3 oppose | **C5** | `|v| < 17` → opposition pushes **outward** (off 0); `|v| > 35` → pushes **inward** (off the ±50 edge); in-band is slack. |
| L4 drift | **C4** | Per-step motion is **AI-originated** — supplied by the agent's own cognition/affect. ETR never generates it (no RNG). |
| L5 couple | **C1** | The three axes **couple via a stress metric** (hypothesis: PS+/Eth-Int existential load). Exact mapping **undefined** — open seam, not to be invented. |
| L6 z-path | **C3** | `z < 0` → alimentation / lattice-reinforcement; `z ≥ 0` → transmutation / prior-evolution. (Structure kept; sign to re-verify.) |
| L7 no-zero-cross | **C2** | Bands wall off 0; a pole/sign flip happens **only** by riding over the ±50 wrap, never through neutrality. *(emergent — unconfirmed)* |
| L8 mechanism | **C2** | "Opposition" = a restoring force on the drift, **not** an out-of-band cost. *(unconfirmed)* |

## Constants
`BAND_LO = 17`, `BAND_HI = 35`, `WRAP = 50` are **law** (L1–L3), not fitted.
`RESTORE_GAIN = 0.5` is **FITTED** — the spring stiffness of the out-of-band restoring force: active
only out of band (in band is slack, L3), pulling toward the band **centre (26)** so a step crosses
*into* `[17,35]` and stops there (an edge target would asymptote onto 17 from below and fail L2).
Below-band pushes away from 0, so the force alone never crosses zero (L7). Lands e.g. `[5 5 5] → 20.75`
in 2 steps; `[45 −45 40] → [30.75 −30.75 33]`. Valid range `0 < GAIN < ~2` (above ~2 a cross-in step can
overshoot the far edge).
`COUPLING` (L5 strength/mapping) remains **TBD** — open seam, not to be invented.

## Testable predicates (see `test_etr.m`)
- **L1**: `wrap(50) = −50`; `wrap(60) = −40`; `wrap(v)=v` for `v∈(−50,50)`; `wrap(49.9) = wrap(−50.1)`.
- **L2/L3**: direction is `+sign(v)` for `|v|<17`, `−sign(v)` for `|v|>35`, `0` in band; a zero-drift point started out-of-band **settles into** `[17,35]∪[−35,−17]`.
- **L4**: `etr_step` with no `drift` argument **errors** (it refuses to invent motion).
- **L5**: `coupling(coord, 0)` is identity; `coupling(coord, stress>0)` alters coord — *pending until defined*.
- **L7**: pending until confirmed.

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

## Status (RESTORE_GAIN fitted — 14 PASS / 0 FAIL / 2 PEND)
Green: L1 wrap, L3 direction + **restoring magnitude (fitted)**, **L2 band-convergence**,
L4 drift-must-be-fed, L5 coupling-off identity. L8 (opposition = a restoring force on the drift, not an
out-of-band cost) is now **realised by construction** — the force is added alongside drift, never charged
as a cost — though still tagged C2 until a dedicated test pins it.
Pending: L5 active coupling (C1, open seam), L7 no-zero-crossing (C2).
