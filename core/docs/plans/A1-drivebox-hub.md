# A1 — DriveBox: organ contract and secretion boundary

## 1. Component
DriveBox is an autonomous physiological organ system outside the homunculus. Its **two top-level parts** are E (literal tool energy economics) and ETR (existential-temporality relief). Within E: PS+ (Endomotiv and Triumph/Trauma Priors) and EthInt (Convictions). Within ETR: the three-axis Graph. See [canonical DriveBox contract](../drivebox-canon.md).

## 2. Status / certainty
**Design reconciled, runtime stale.** The existing R `drive_box.R` still implements a disowned four-peer-driver serial approval pipeline. No claim of working conformance is made here. No version increment follows from this edit.

## 3. Language & location
Current R facade: `core/src/endocrine/drive_box.R`; ETR geometry in Octave with an R port. Final transport/ownership of injection assembly remains under review.

## 4. Does / does-not
- **Does:** maintain bodily state, expose a read-only snapshot, publish distinct E, PS+, EthInt, and ETR signals, and apply consequences of chosen tool use; can continue regulating without a homunculus turn.
- **Does not:** choose the homunculus's actions, validate morality, claim SOUL/Tarot as DriveBox children, or bypass Ada/SPARK. Cost lockouts are physical availability constraints, **not** a DriveBox decision about what to believe or desire.

## 5. Interface contract (target; transport open)
- `init_drive_box() -> { E:{ reserve, PS+:{Endomotiv,Priors}, EthInt:{Convictions} }, ETR:{ Graph:{x,y,z} } }` (logical shape; not a promised R record schema).
- `drive_snapshot(state) -> immutable { energy_available, tools:[{identifier_or_lock_token, cost?, minimum}], sensates[30], top_priors[<=2], top_convictions[<=X], etr_graph, etr_zones, etr_orientation }`.
- `price_tool(state, tool) -> {cost, minimum, locked}` **pure/read-only**; PS+ and EthInt affect cost while also secreting their own cognitive signals.
- `commit_choice(state, chosen_action, outcome) -> updated_state`: apply expenditure and observable consequences **without an approved flag**. Exact action/outcome contract is still open.
- `physiology_event(state, event) -> updated_state + secretions`: extraordinary Graph influences and other autonomous events; not an invitation for every action to modify the Graph.
- Each secretion crosses Ada before cognition. SOUL and Tarot enter the cognitive assembly through their own contracts; DriveBox does **not** own the entire input slot.

## 6. Dependencies & stubs
A2 E; A3/A4/A5 PS+; A6/A7 EthInt; A8 ETR. Ada D1 checks boundary crossings; Ichor D2 is the **outer** bus and Jorvik is the inner Ada-routed bus. Tarot B1-B3 is active identity work, not defunct.

## 7. Invariants / laws
- **L1:** the containment hierarchy above is authoritative; no four-peer-driver ontology or serial approval order.
- **L2:** snapshots and price queries do not mutate physiology.
- **L3:** all 30 sensates are raw (including zeros), no additive PS+ existential load; top two relevant priors and a ranked adaptive top-X of convictions are presented separately.
- **L4:** the homunculus chooses; E may make **specific tool calls** unaffordable or unavailable. Rest and internal processing are not equivalent to death.
- **L5:** the Graph has extraordinary triggers and warm-middle homeostasis; it is **not** updated by ordinary E/PS+/EthInt fluctuations.
- **L6:** Full Natal and invariant-store boundaries follow [the canonical contract](../drivebox-canon.md), including historical record preservation and the unresolved pre-snap zero trigger.

## 8. Build steps
1. Write tests for the new containment and non-approval interfaces.
2. Replace old aggregated load, four-driver evaluate/commit gate, and alive/death semantics.
3. Wire PS+/EthInt dual signal-and-cost paths without serializing them.
4. Integrate ETR events separately from ordinary tool expenditure; resolve pre-snap origin detection.
5. Wire Ada crossing without assigning enrichment to Ada or exposing inner organs to Ichor.

## 9. Tests
`core/src/endocrine/run_tests.sh` exists but its historic passing result does **not** demonstrate this target. New interface, snapshot-purity, tool-pricing, and Full Natal integration tests are required.

## 10. Open items
Cost curves and tool minima; top-X adaptation; event/commit contracts; Ichor/Ada/R/Octave transport; the zero-event detector and remaster operation; status of autonomous idle rhythms.
