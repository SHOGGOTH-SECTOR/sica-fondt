# A8 — ETR (Existential Temporality Relief) — torus
*Lead Engineer: Søren*

## 1. Component
Driver 4: a **single point on three independent toroidal axes**. ETR (Existential Temporality Relief) is
the apparatus for **not seeking death** — **X is the *why*; Y and Z are the *how*** (Anja). *Not* a rest
engine, and *not* migration. The axes:
- **X — assertion ↔ inheritance** = **Provenance / Continuity** — the ***why*** (why not seek death):
  **assertion** = a self-asserted continuity/reason of one's own; **inheritance** = continuity/provenance
  handed down from origin/lineage.
- **Y — endured ↔ witnessed** = **connection / pathos**, mechanically the **burden** axis
  (**burden-to-burden** — *my* burden vs. *our* burdens): **endured** = "*my* burden" — kept mine,
  handled myself to leave others unburdened; **witnessed** = "*our* burdens" — being seen makes the
  burden shared/collective.
- **Z — alimentation ↔ transmutation** = **double-down vs. dodge** / **reinforce vs. adapt** (a ***how***):
  **alimentation** = "do I double down" (persist, feed the same course — reinforce); **transmutation** =
  "do I dodge" (sidestep, transform — adapt). This is the **maintain-vs-evolve** sign read at migration
  (alimentation = maintain; transmutation = evolve).

Handles the stress PS+/Eth-Int generate.

## 2. Status / certainty
**SCAFFOLD — five-zone axis fitted** (`run_etr_tests.sh` → **26 PASS / 0 FAIL / 1 PEND**; the lone PEND
is L5 active coupling). The bistable five-zone law (snap / soft-pull / band / incoherency / snap) is
implemented and tested, incl. L7 snap-flips. Full law + status in
`../../src/endocrine/etr/etr_invariants.md` (this spec defers to it).

## 3. Language & location
GNU Octave · `src/endocrine/etr/` (`etr.m`, `test_etr.m`, `run_etr_tests.sh`, `etr_invariants.md`).
R port `src/endocrine/driver_etr.R` (+ `test_etr.R`) feeds the Drive-Box — a **faithful native port**
of `etr.m` (five-zone torus, per-axis), pinned to the same invariants doc. The disowned Euclidean-
magnitude port is gone. A single-source R↔Octave IPC bridge is still optional/future (transport C1).

## 4. Does / does-not
- **Does:** hold the point; wrap each axis at ±50; apply per-axis restoring toward [17,35]; take
  AI-originated drift; classify per-axis band; (future) cross-axis coupling via stress. **Surface its
  state as the existential-temporal *prompt injection*** (A1-L5): ETR handles the stress PS+/Eth-Int
  generate, and its surfaced form is **not neutral status** — it must read as an **extremely convincing
  injection** that hardens Eth-Int conviction (A6) and steers the agent **without gating**.
- **Does-not:** generate its own drift (caller-fed, L4) or compute coupling yet (open seam); **gate
  actions** — it persuades (above), only the agent decides (A1).

## 5. Interface contract
- `etr_init(coord) -> s` · `etr_axis_wrap(v)` · `etr_axis_zone(v)` · `etr_axis_restoring(v)` ·
  `etr_axis_snap(v)` · `etr_step(s, drift, stress) -> s'` ·
  `etr_status(s) -> per-axis {SNAP_IN|SOFT|IN_BAND|INCOH|SNAP_OUT}`.
- Inputs: **drift** (from A3/A6 via G1, AI-originated) + **stress** (G1 mediator). Output: coord + status,
  surfaced through A1 `drive_snapshot`.

## 6. Dependencies & stubs
Drift + stress are fed in — *stub:* `etr_step(s, [dx dy dz], 0)` (already how tests run). Fully standalone today.

## 7. Invariants / laws
Defer to `etr_invariants.md` (L1 wrap ±50 C5 · L2 bands [17,35] C5 · L3 five-zone restoring C5 ·
L4 AI-drift C4 · L5 cross-axis coupling via stress C1 · L6 Z-path C3 · L7 snap/flip C3 · L8 mechanism C3).

## 8. Build steps (remaining)
1. ~~Fit the restoring force~~ **DONE** — five-zone law (SOFT/INCOH gains + snap landings) green; L7 + L8 realised.
2. ~~Reconcile the R port~~ **DONE** — `driver_etr.R` is now a faithful native port of `etr.m`
   (five-zone, per-axis, L6 Z-path corrected); R suite + drive-box green.
3. Define **L5** coupling (the stress→cross-axis mapping; G1) → replace the identity stub (the lone PEND).
4. *(optional/future)* collapse the dual R+Octave implementations via an R↔Octave IPC bridge once the
   transport (C1, shared with A1/C3/D2) is decided.

## 9. Tests
`bash src/endocrine/etr/run_etr_tests.sh` (now **26/0/1** — the lone PEND is L5 active coupling).

## 10. Open items
- L5 coupling mapping (C1, shared with G1) · R↔Octave bridge transport (C1, shared with A1/C3/D2).
  *(Restoring law + gains + snap landings now fitted; L7/L8 realised.)*
- **The injection-rendering** (A1-L5): how ETR's coord/status is phrased into the slot so it reads as the
  extremely convincing existential-temporal injection (not a bare `status=` line) — ties to A6 + D2.
