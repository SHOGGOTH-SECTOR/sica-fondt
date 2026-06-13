# A2 — Energy (E) driver

## 1. Component
Driver 1: the master constraint. Finitude that gives choice weight + rest/restoration. Gates
liveness, locks tools under threshold, applies nonlinear cost drag.

## 2. Status / certainty
Structure WORKING (`driver_energy.R`, 79 L) but **numbers DISOWNED** (body §5) **and the model
is being RECONCEIVED** (body §4): drop *depletion-unto-death*; no unrecoverable state.

## 3. Language & location
R · `src/endocrine/driver_energy.R` (+ `test_energy.R`).

## 4. Does / does-not
- **Does:** report E level; gate tool calls (tool-lock = "present to fewer things," a breaker);
  fold cost (PS+ load + Eth-Int penalty) into an affordability check; consume/restore.
- **Does-not:** die. The old `is_alive()==0` hard-death is removed — E is the **rest** counterpart
  to ETR's **relief**; floor is rest, not death.

## 5. Interface contract
- `init_energy_state(current=100,max=100,tool_lock_threshold=?) -> e`.
- `is_tool_locked(e) -> bool` · `get_cost_multiplier(e) -> num` ·
  `evaluate_tool_cost(e, ps_load, eth_penalty) -> cost` (asymmetric: eth scales harder than PS+) ·
  `request_execution(e, base_cost, is_tool_call) -> {approved, reason, true_cost}` ·
  `consume(e, amt) -> e'` · `recharge(e, amt) -> e'`.

## 6. Dependencies & stubs
Consumes `ps_load` (A3) + `eth_penalty` (A6) as plain numbers — *stub:* pass scalars; no driver needed.
Restoration hooks tie to ETR-Z migration (A8) + tarot reshuffle (B3) — *stub:* call `recharge` directly.

## 7. Invariants / laws (to be (re)derived — all numbers C1 until tested)
- **L1 (C4):** finitude-in-the-moment — a bound on what can be borne/afforded *now*.
- **L2 (C4):** **no unrecoverable state** — every low-E condition has a restoration path
  (meditation = rest-in-place; migration = rest-as-integration; tarot reshuffle = rest-as-reframe).
- **L3 (C4):** tool-lock is a **breaker, not a sentence** — internal processing continues under lock.
- **L4 (C2):** cost drag is nonlinear + asymmetric (eth > visceral); curve/k **C1**.

## 8. Build steps
1. Rewrite laws (above) → encode as tests in `test_energy.R` (replace death tests with rest/restore tests).
2. Strip the depletion-unto-death path; add restoration paths (meditation/migration/reshuffle).
3. Refit drag/tool-lock constants invariants-first — no `k` carried from the old code.

## 9. Tests
`Rscript src/endocrine/test_energy.R` (from repo root) — must encode L1–L3 and fail on any asserted-but-unfitted constant.

## 10. Open items
- Restoration *rates* (C1). The exact meditation/migration/reshuffle E-deltas (C1).
- Tool-lock threshold value (C1).
