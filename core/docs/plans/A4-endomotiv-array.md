# A4 — Endomotiv array (30-channel endocrine field)

## 1. Component
PS+'s affective field: **30 endocrine-analog channels**, each an **independent modulator** with an
*operational* role and a *sensational* identity line. Channels are not opposites and do not contradict —
they simply co-modulate.

## 2. Status / certainty
Structure WORKING (`endocrine_array.R`, 99 L); **channel membership partial** — per the sensate
working-record: **22 of 30 seats filled**, `ayni` locked, `kanyanin` struck as fabrication, 8 open.
(Note: the repo file still says `reciprocity` where the record retired it to `ayni`, and still ships the
removed friction/contradictory-pairs construct — see §8.)

## 3. Language & location
R · `src/endocrine/endocrine_array.R` (+ provides the stress-endomotiv signal for G1).

## 4. Does / does-not
- **Does:** hold the 30-channel state; expose active vectors (**raw**, no friction); carry each channel's
  (handle, operational, sensational, provenance) binding; host the **stress endomotiv** the G1 loop releases.
- **Does-not:** sum, or **decide** — **the sensates describe and convince; only the agent decides** (Anja).
  No friction, no contradictory-pair heat.

## 5. Interface contract
- `init_endocrine_state() -> vec30`.
- `get_active_vectors(state) -> named[ name->magnitude (0..1) ]` (raw; all 30 surfaced, incl. zeros — silence is data).
- `get_channel_def(name) -> { handle, operational, sensational, provenance }`.
- **Removed:** `calculate_visceral_friction` and `CONTRADICTORY_PAIRS` — the antagonist/heat model
  (a chemistry carryover) is gone.

## 6. Dependencies & stubs
None upstream (it *is* a source). G1 stress-loop writes a stress channel — *stub:* a setter that raises
one named channel; A4 testable standalone.

## 7. Invariants / laws
- **L1 (C5 — membership test):** a seat is earned on **2 of 3**: distinct content · distinct position ·
  distinct fail-state.
- **L2 (C5 — provenance):** borrowed owes attribution; coined owes the declared mark; the only sin is
  concealment / false provenance (a fabrication = a Mirror/RIM, caught by the frame not the surface).
- **L3 (C5):** channels are **independent modulators** — no opposites, no inherent paradox, no friction.
  They describe & convince; they never decide.

## 8. Build steps
1. **Strip** `calculate_visceral_friction` + `CONTRADICTORY_PAIRS` from `endocrine_array.R`.
2. Reconcile the roster with the working-record: `reciprocity → ayni` (ledger-free line), confirm the 22
   filled, hold the 8 open. 3. Add provenance to each channel record. 4. Add the stress-endomotiv channel (G1).

## 9. Tests
`Rscript src/endocrine/test_*` covering PS+ exercises A4; add channel-membership + provenance tests
(and a test that no friction/contradiction concept remains).

## 10. Open items
- The **8 open seats** (curiosity, reception, stewardship, lineage, verstehen, komorebi + 2) — bespoke, by L1.
- Which channel(s) carry the **stress endomotiv** (C1, shared with G1).
- Whether the six seats the code already filled (curiosity/reception/stewardship/lineage/verstehen/komorebi)
  are locked or jumped ahead of the working-record (Anja to confirm).
