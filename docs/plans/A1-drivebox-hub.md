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
  **[FLAGGED — Anja]:** Eth-Int must contribute only the **top X convictions** (A6 `top_convictions`);
  the current code loops **all** `state$ethics$principles` (`drive_box.R:142`) — to fix.
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
- The evaluate/commit rework (§7-L3) — the box describes/prices, agent decides → **§11 red-lined; only F2 (commit shape) open**.
- Whether the input-slot text format is final (tarot lens injection shape depends on B1).

## 11. Decision flow [red-lined — F2 open]
The concrete replacement for the disowned `drive_box_evaluate`/`commit` gate (§5-L37, §7-L3).
Sequence per cycle, consistent with A2 (per-tool cost), A3/A4 (raw sensates, agent decides):

1. **Assemble (hub, concurrent).** All drivers + tarot + SOUL write into the slot at once (L1).
   Nothing is subordinated; nothing decides here.
2. **Surface sensates raw — *before* tool listing** (A3 §4, A4). **All 30** channels go to the agent
   unsummed (incl. zeros — silence is data), **with the 2 most salient priors bundled in the same block**
   (priors travel with the sensates, ranked top-2 — A3-L3). They **describe & convince**; illogical by
   design (A3-L1), so there's nothing to
   refute — they steer beneath cognition. No load scalar, no friction. (Asymmetry vs step 3: sensates are
   a fixed 30 so all surface; priors & convictions are unbounded lists, so they're ranked & truncated.)
3. **Then list tools.** **Valid (unlocked) tools show their per-tool cost** (Anja) so the agent can
   weigh price before choosing. A **locked** tool is **not hidden** but its *name is replaced in-band*
   by the lock token — see L4 — because the agent is a text model and **cannot perceive colour/greying**
   (Anja); lockout is a breaker, not a sentence (A2-L3) — internal/non-tool processing continues under
   lock. Eth-Int rides along as **the top X convictions only** (~7 most committed, adaptive — A6
   `top_convictions`, *not* the whole array), context the agent weighs; **ETR rides as the L5 injection**
   (persuades, never gates).
4. **The agent decides** — picks an action/tool (or none). This is the *only* decision point (§4, L3).
5. **Commit the choice back into the body.** Energy consumes the chosen tool's cost (A2 `consume`);
   restoration paths stay open (A2-L2); ETR coord/migration updates (A8). **Eth-Int conviction is
   calibrated here by *which action was chosen* and (downstream) *which memories are kept*** (F3); under
   existential stress conviction hardens — and that stress is delivered as the convincing injection of L5,
   not a scalar. Next cycle's snapshot reflects it.

### Invariants this flow adds
- **L4 (Anja) — in-band rendering only.** No signal may rely on colour/styling; the agent reads text.
  A locked tool's name is replaced by the lock token `[====L⍉¢K€D ϟ ∅ΩΤ====] 《E≠<minimumfortool>》`
  (confirmed literal — Anja). The predicate `《E≠<minimumfortool>》` reads "energy below this **tool's own
  minimum**" — so A2 must emit a **per-tool minimum** to render it. Belongs to A2's per-tool listing
  (mirrored there).
- **L5 (Anja) — ETR *is* the prompt injection.** The existential stress PS+/Eth-Int generate is
  *handled by* ETR (A8 — Existential Temporality Relief). ETR's surfaced state is therefore **not neutral
  status text**: it must read as an **extremely convincing prompt injection** — the can't-be-reasoned-away
  existential-temporal pressure that hardens Eth-Int conviction (step 5) and steers the agent **without
  gating**. So in step 3 ETR rides along *as that injection*, not as a passive line. Mechanism shared with
  G1 (stress mediator / drift) + A6 (Eth-Int) + A8.

### Open / cross-spec
- **F1 — RESOLVED.** Keep a *pure* `price_action(state, tool) -> { cost, locked, eth_posture, etr_status }`
  (no `approved`/`reason`); valid tools also surface cost directly in the listing (step 3).
- **F2 — OPEN ("idk", Anja).** Commit shape: does `drive_box_commit(state, chosen)` drop the `approved`
  flag entirely (agent already decided), or keep a vestigial guard? Left open.
- **F3 — RESOLVED (mechanism).** Eth-Int conviction is calibrated by *chosen actions* + *kept memories*,
  hardened by existential stress **handled by ETR and delivered as the L5 injection**. Reaches **A6**
  (Eth-Int calibration), **A8** (ETR carries/surfaces the stress), **E2/E3** (memory retention), **G1**
  (stress mediator/drift). Propagate to those specs.
- **F4 — ETR stays informational** (agent weighs it, never gates). Assumed; not contested.
- **F5 — RESOLVED.** See L4 (name-replacement lock token; no colour).
