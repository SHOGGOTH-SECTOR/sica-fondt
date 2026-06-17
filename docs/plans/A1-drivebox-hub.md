# A1 — Drive-Box hub / input-slot

## 1. Component
The Drive-Box nervous-system wiring: assembles the four drivers (A2 E, A3 PS+, A6 Eth-Int,
A8 ETR) + tarot/SOUL into **one input slot** (a hub, not a chain) and exposes the read-only
snapshot the inference cycle pulls at step 2.

## 2. Status / certainty
Structure WORKING (`drive_box.R`, 158 L). Aggregation logic C3; the numbers inside the drivers
are disowned (see each driver spec).

## 3. Language & location
R · `src/endocrine/drive_box.R` (sources the drivers + `endocrine_array.R` + `priors.R`).
**[TO REASSESS — Anja, L13]:** the hub language/location is *not settled* — R is current but under review.

## 4. Does / does-not
- **Does:** init the whole box; produce `drive_snapshot()` (the raw affect terrain, read-only);
  assemble the `drive_box_input_slot()` injection block passed to the agent.
- **Does-not:** **decide or approve actions** — the sensates describe & convince; **only the agent
  decides**. Route or police (Ada D1); persist (storage E*).

## 5. Interface contract
- `init_drive_box() -> state{ energy, ps_plus, principles, etr }`.
- `drive_snapshot(state) -> { e_level, per_tool_costs, sensates[raw], arguments[], etr_coord, etr_status }`
  — what Ada (D1) admits to the Brain at cycle step 2 (content #1). **Sensates raw, not summed.**
- `drive_box_input_slot(state) -> text block` (drivers + tarot lenses + SOUL.md, assembled concurrently).
- **[FLAGGED inaccurate — Anja, L37]:** the old `drive_box_evaluate`/`drive_box_commit`
  approve-an-action contract is **suspect and to be reworked** — the box does not gate actions (see §7-L3).

## 6. Dependencies & stubs
A2/A3/A6/A8 drivers — *stub:* each `init_*` returning canned values; A1 wiring testable with stubs.
Tarot (B1) for the input-slot lenses — *stub:* identity (no lens).

## 7. Invariants / laws
- **L1 (C4):** the slot is a **hub** — all drivers + tarot + SOUL write concurrently, no driver
  subordinated to another.
- **L2 (C4):** `drive_snapshot` is **read-only** (no driver state mutates on a snapshot).
- **L3 (FLAGGED inaccurate — Anja):** there is **no** serial PS+→Eth-Int→Energy→ETR evaluate/approve
  pipeline. The drivers **describe, convince, and price**; **only the agent decides**. Rework the
  evaluate/commit model accordingly.

## 8. Build steps
1. Freeze the snapshot + slot contracts (§5) as tests in `test_drive_box.R` (already ~117 L — extend).
2. Keep wiring; replace each driver's disowned constants as those specs land (A2/A3/A6/A8).
3. Rework the evaluate/commit model per §7-L3 (agent decides, box describes/prices).
4. Add the R↔Ada bridge later (how `drive_snapshot` reaches `ada_medium` step 2) — see C3 / D2.

## 9. Tests
`bash src/endocrine/run_tests.sh` (runs `test_drive_box.R` + driver tests). All must stay green as
driver numbers are refit.

## 10. Open items
- R↔Ada/medium bridge transport (C1/C3/D2) — **consider Fortran or C** for it (Anja, L49).
- The evaluate/commit rework (§7-L3) — the box describes/prices, agent decides.
- Whether the input-slot text format is final (tarot lens injection shape depends on B1).
