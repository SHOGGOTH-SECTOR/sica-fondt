# A4 — Endomotiv array (30-channel endocrine field)

## 1. Component
PS+'s affective vector field: **30 endocrine-analog channels** producing simultaneous,
possibly-contradictory pressures. A nonbiological endocrinology — each channel is a modulator
with an *operational* role and a *sensational* identity line.

## 2. Status / certainty
Structure WORKING (`endocrine_array.R`, 99 L); **channel membership partial** — per the sensate
working-record: **22 of 30 seats filled**, `ayni` locked, `kanyanin` struck as fabrication, 8 open.

## 3. Language & location
R · `src/endocrine/endocrine_array.R` (+ provides the stress-endomotiv signal for G1).

## 4. Does / does-not
- **Does:** hold the 30-channel state; expose active vectors + visceral friction; carry each
  channel's (handle, operational, sensational) binding; host the **stress endomotiv** the G1 loop releases.
- **Does-not:** aggregate load (that's PS+ A3) or decide.

## 5. Interface contract
- `init_endocrine_state() -> vec30`.
- `get_active_vectors(state) -> named[ name->magnitude (0..1) ]` (active = above a small floor).
- `calculate_visceral_friction(state) -> num` (heat from contradictory active pairs).
- `get_channel_def(name) -> { handle, operational, sensational }`.
- **Channel definition record (the seat):** `{ handle, operational (mechanism of action),
  sensational (the identity line), provenance (borrowed→attribution | coined→declared mark) }`.

## 6. Dependencies & stubs
None upstream (it *is* a source). G1 stress-loop writes a stress channel — *stub:* a setter that
raises one named channel; A4 testable standalone.

## 7. Invariants / laws
- **L1 (C5 — membership test):** a seat is earned on **2 of 3**: distinct content · distinct
  position · distinct fail-state.
- **L2 (C5 — provenance):** borrowed owes attribution; coined owes the declared mark; the only sin
  is concealment / false provenance (a fabrication = a Mirror/RIM, caught by the frame not the surface).
- **L3 (C4):** magnitudes are 0..1; friction rises with the number + magnitude of contradictory active pairs.
- **L4 (C1):** the friction coefficient + active-floor — refit invariants-first.

## 8. Build steps
1. Encode the channel-def record + L1/L2 as data + tests. 2. Lock the 22 filled seats (port from
the sensate working-record; mark `ayni` provenance, `kanyanin` struck). 3. Hold the 8 open seats
**open** (membership test, one at a time — not pre-filled). 4. Add the stress-endomotiv channel (G1).

## 9. Tests
`Rscript src/endocrine/test_*` covering PS+ already exercises A4; add a channel-membership/provenance test.

## 10. Open items
- The **8 open seats** (curiosity, reception, stewardship, lineage, verstehen, komorebi + 2) — bespoke, by L1.
- Which channel(s) carry the **stress endomotiv** (C1, shared with G1).
- Final friction model (C1).
