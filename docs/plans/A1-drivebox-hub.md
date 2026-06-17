# A1 — Drive-Box hub / input-slot

## 1. Component
The Drive-Box nervous-system wiring: assembles the four drivers (A2 E, A3 PS+, A6 Eth-Int,
A8 ETR) + tarot/SOUL into **one input slot** (a hub, not a chain) and exposes the read-only
snapshot the inference cycle pulls at step 2.

## 2. Status / certainty
Structure WORKING (`drive_box.R`, 158 L). Aggregation logic C3; the numbers inside the drivers
are disowned (see each driver spec). **The evaluate/commit model below is flagged inaccurate — §7.**

## 3. Language & location
R · `src/endocrine/drive_box.R` (sources the drivers + `endocrine_array.R` + `priors.R`).
**[TO REASSESS — Anja]:** the hub's language/location is *not settled*; R is current but under review.

## 4. Does / does-not
- **Does:** init the whole box; produce `drive_snapshot()` (raw sensate field + per-tool cost terrain,
  read-only); assemble the `drive_box_input_slot()` injection block surfaced to the agent.
- **Does-not:** **decide** — the drivers *describe, convince, and price*; only the **agent** decides.
  It does not route or police (Ada D1) or persist (storage E*).

## 5. Interface contract
- `init_drive_box() -> state{ energy, ps_plus, principles, etr }`.
- `drive_snapshot(state) -> { e_level, raw_sensates[30], arguments[], per_tool_costs, etr_coord, etr_status }`
  — surfaced to the agent (sensates passed **before tool listing**, A3); raw, **never summed**.
- `drive_box_commit(state, chosen_action) -> state'` — applies the chosen tool's energy cost + conviction effects.
- `drive_box_input_slot(state) -> text block` (drivers + tarot lenses + SOUL.md, assembled concurrently).
- **[FLAGGED inaccurate — Anja]:** the old `drive_box_evaluate(action) -> {approved,…}` approve-gate is
  **wrong** — the box doesn't approve actions. To be reworked into "surface terrain → agent decides → commit."

## 6. Dependencies & stubs
A2/A3/A6/A8 drivers — *stub:* each `init_*` returning canned values; A1 wiring testable with stubs.
Tarot (B1) for the input-slot lenses — *stub:* identity (no lens).

## 7. Invariants / laws
- **L1 (C4):** the slot is a **hub** — all drivers + tarot + SOUL write concurrently, none subordinated.
- **L2 (C4):** `drive_snapshot` is **read-only** (no driver state mutates on a snapshot).
- **L3 (FLAGGED — inaccurate per Anja):** there is **no serial PS+→Eth-Int→Energy→ETR evaluate/approve
  pipeline**. Only the **agent decides**; drivers describe/convince + price. The evaluate/commit model
  is to be reworked.

## 8. Build steps
1. **Rework the decision model** (drivers surface terrain → agent decides → commit) before freezing contracts.
2. Freeze the corrected snapshot/slot contracts (§5) as tests in `test_drive_box.R`.
3. Add the R↔Ada bridge later — see C3 / D2 and §10.

## 9. Tests
`bash src/endocrine/run_tests.sh` (runs `test_drive_box.R` + driver tests). Update once the decision model is reworked.

## 10. Open items
- **Decision-model rework** (agent-decides, not box-approves).
- R↔Ada/medium bridge transport — **consider Fortran or C** for it (Anja) (C1/C3/D2).
- Hub language/location reassessment (Anja). Input-slot text format depends on B1.
