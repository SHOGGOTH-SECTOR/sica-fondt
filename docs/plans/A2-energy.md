# A2 — Energy (E) driver

## 1. Component
Driver 1: the master constraint — an **in-the-moment activation / rest budget** (not "finitude" anymore;
with depletion-unto-death dropped, it isn't finitude). Gates tool use and prices actions.

## 2. Status / certainty
Structure WORKING (`driver_energy.R`, 79 L) but **numbers DISOWNED** (body §5) **and RECONCEIVED**
(body §4): drop *depletion-unto-death*; no unrecoverable state.

## 3. Language & location
R · `src/endocrine/driver_energy.R` (+ `test_energy.R`).

## 4. Does / does-not
- **Does:** report E level; price each tool (**per-tool cost + per-tool lockout scale**, §5); gate when a
  tool's lockout trips; consume on the chosen action; restore.
- **Does-not:** die. The old `is_alive()==0` hard-death is removed — E is the **rest** counterpart to
  ETR's **relief**; floor is rest, not death.

## 5. Interface contract
- `init_energy_state(current=100, max=100) -> e`.
- **Per-tool economy (Anja):** each tool carries **its own energy cost AND its own lockout scale** — an
  arbitrary function of cost `c`, e.g. one tool `c×2`, another `((c²³)×3)/π`. So:
  `tool_cost(e, tool) -> num` and `tool_locked(e, tool) -> bool`, **per tool** — *not* one global
  `tool_lock_threshold`.
- **Per-tool minimum + locked rendering (Anja; A1-L4).** Each tool has a **minimum to consider it**,
  **derived from its actual cost** (Anja) — *not* an independent parameter: `tool_min(tool)` is a function
  of that tool's `tool_cost`. A valid tool shows its cost; a **locked** tool's name is **replaced in-band**
  (the agent can't see colour) by `[====L⍉¢K€D ϟ ∅ΩΤ====] 《E≠<minimumfortool>》`, the predicate reading
  "energy below this tool's `tool_min`". Lockout is a **breaker, not a sentence** (L3).
- `consume(e, amt) -> e'` · `recharge(e, amt) -> e'`.

## 6. Dependencies & stubs
Per-tool cost/lockout tables — *stub:* a small fixed table of tools → (cost fn, lockout fn).
Restoration hooks tie to ETR-Z migration (A8) + tarot reshuffle (B3) — *stub:* call `recharge` directly.
**(Restoration model reassessed — Anja.)**

## 7. Invariants / laws (numbers C1 until tested)
- **L1 (C4):** an **in-the-moment activation/rest budget** — a bound on what can be afforded *now*
  (**not "finitude"** — nothing depletes unto death).
- **L2 (C4):** **no unrecoverable state** — every low-E condition has a restoration path
  (meditation = rest-in-place; migration = rest-as-integration; tarot reshuffle = rest-as-reframe).
- **L3 (C4):** lockout is **per-tool** and a **breaker, not a sentence** — internal processing continues under lock.
- **L4 (C1):** the per-tool cost/lockout functions — fit invariants-first, no carried `k`.

## 8. Build steps
1. Rewrite laws → tests in `test_energy.R` (replace death tests with rest/restore; add per-tool cost/lockout tests).
2. Strip depletion-unto-death; add restoration paths.
3. Define the per-tool cost/lockout table; fit functions invariants-first.

## 9. Tests
`Rscript src/endocrine/test_energy.R` (from repo root) — encodes L1–L3 + per-tool economy; fails on unfitted constants.

## 10. Open items
- The per-tool cost/lockout **functions per tool** (C1). `tool_min` is **not** separate — it's **derived
  from the tool's cost** (so it falls out of the cost fn, nothing extra to fit). Restoration *rates* (C1).
