# A4 — Endomotiv: 30-channel affective field

## 1. Component
Endomotiv is PS+'s native affective substrate: **30 independent sensate channels**, each with a distinct operational role, sensational identity and provenance. It sits inside PS+ inside E, not beside ETR or as an external organ.

## 2. Status / certainty
**Roster unfinished; implementation malformed.** The current `core/src/endocrine/endocrine_array.R` contains inconsistent identifiers and orphan code, so it is not evidence of a working 30-channel system. The working record claims 22 of 30 seats filled and eight pending, but the file and working record must be reconciled rather than either automatically treated as final. `ayni` is the intended handle in place of deprecated `reciprocity`; `kanyanin` was rejected as fabricated. The names curiosity, reception, stewardship, lineage, verstehen and komorebi remain subject to the original membership audit.

## 3. Language & location
Current R source: `core/src/endocrine/endocrine_array.R` (to repair).

## 4. Does / does-not
- **Does:** store/read each independently varying magnitude and its operational, sensational, provenance and temporal descriptors; feed PS+; participate in a **collapse-triggered remaster of active values** without losing the roster or its history.
- **Does not:** sum channels into one load, create contradictory pairs/friction, act as a moral judge, or directly initiate Graph drift on ordinary fluctuation.

## 5. Interface contract (target)
- `channel_def -> {id, operational, sensational, provenance}`; numeric scale and time-derivative representation need revalidation.
- `endomotiv_state -> exactly 30 slots`, each with its own active value (including zero); reserved/undefined seats are **not** fictional finished sensates.
- `snapshot(state) -> raw 30 channels` immutable; `apply_observation/event -> next state` with attributable causes.
- `remaster_values(state, parameters) -> next state`: contour-preserving attenuation/rebalancing of **current magnitudes**, not rewriting definitions or event history. Numerical rule C1.

## 6. Dependencies & stubs
Consumed by PS+ A3 and event integration through A1; no invented single "stress" channel is mandatory.

## 7. Invariants / laws
- **L1:** a new seat must satisfy at least two of three: distinct content, distinct position, distinct fail-state.
- **L2:** attributed concepts preserve provenance; fabrication cannot be silently promoted to original or inherited.
- **L3:** every channel acts independently. No built-in antagonistic pairs, summed existential-load, or obligatory heat model.
- **L4:** zero-valued sensates are meaningful and remain visible. Magnitudes can be remastered; channel identity/history cannot be erased by Full Natal.
- **L5:** severe compounding trauma can eventually affect ETR, but **Endomotiv elevation alone is not a drift command**.

## 8. Build steps
Reconcile roster and schema, repair syntactically invalid R source, add provenance and raw channel tests, then integrate ETR qualification through a separate event mechanism.

## 9. Tests
Require schema/roster/membership tests, snapshot including zeros, independent movement, preservation of history through remaster, and proof there is no aggregate/friction function.

## 10. Open items
Remaining seats and their evidence; actual value range/units (existing notes conflict, e.g. 0..1 and 15.7/30); time derivatives; remaster coefficients; whether a dedicated stress channel is useful at all.
