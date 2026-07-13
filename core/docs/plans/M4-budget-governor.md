# M4 — Budget governor

## 1. Component
The stomach's CFO: **sets, allocates, and enforces** resource budgets. Decides whether a proposed
expenditure (digestion, retrieval, exchange) is affordable given what's already been spent (M3)
and what's been allocated. Emits **price signals** to A2 (energy driver) so the per-tool economy
reflects real resource scarcity.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. A2 has a per-tool cost/lockout system but it tracks internal energy, not
external resource budgets. The two are complementary: A2 = activation/rest; M4 = tokens/compute
spend. Role C2; implementation C1.

## 3. Language & location
TBD · `src/economy/budget/` or similar. Must interop with M3 (ledger reads) and A2 (price signal
emission). Likely same language as M3 for tight integration.

## 4. Does / does-not
- **Does:** hold a session budget (total resources available); check proposed costs against
  remaining budget (`check_budget`); emit price signals to A2 so tool costs reflect real scarcity;
  implement **degradation tiers** — when budget is ample, digest fully; when tight, digest
  shallowly or defer bulk input (M1 priority system).
- **Does-not:** record costs (M3 does); perform digestion (M2 does); lock tools (A2 does that
  based on energy, though M4's price signals influence A2's cost landscape); police traffic (D1).

## 5. Interface contract
- `init_budget(session_budget: num, resource_type: ResourceType) -> BudgetState`.
- `check_budget(proposed_cost: num, resource_type: ResourceType) -> { allowed:bool, remaining:num, tier:DegradationTier }`.
  `DegradationTier` ∈ { `full`, `shallow`, `deferred` } — signals to M2 how deeply to digest.
- `price_signal(tool_id) -> { resource_cost:num, scarcity_factor:num }` — emitted to A2; the
  scarcity factor scales with budget depletion (1.0 = ample, >1.0 = scarce, costs feel heavier).
- `remaining() -> { budget:num, spent:num, pct_remaining:num }` — reads M3 totals.

## 6. Dependencies & stubs
- M3 cost ledger — reads totals for remaining budget calculation; *stub:* returns zero spent.
- A2 energy driver — consumes price signals; *stub:* print signals.
- M1 ingestion — M1 checks budget before forwarding to M2; *stub:* always-allow.
- M2 digestion core — receives `DegradationTier` to adjust digestion depth.

## 7. Invariants / laws
- **L1 (C4):** budget enforcement is a **soft gate, not a hard wall** — when budget is exhausted,
  digestion degrades (shallower summaries, deferred bulk) rather than halting. The organ never
  stops entirely; it economizes harder. Mirrors A2-L2 (no unrecoverable state) and A2-L3
  (lockout is a breaker, not a sentence).
- **L2 (C3):** price signals are **monotonically scarcer** as budget depletes — the scarcity
  factor never decreases within a session (costs only feel heavier as resources dwindle). Resets
  only on budget replenishment.
- **L3 (C3):** degradation tiers are **transparent** — the tier is carried in the contract so
  downstream (M2, M5) knows the digestion was shallow and can annotate accordingly.

## 8. Build steps
1. Define `BudgetState` and the degradation tiers.
2. Implement `check_budget` against M3 totals.
3. Implement `price_signal` emission to A2 (define the scarcity factor curve — invariants-first).
4. Wire M1 → M4 → M2 (budget check before digestion, tier passed to digestion).

## 9. Tests
Budget arithmetic: spent + remaining = total. Degradation tiers: each tier triggers at the correct
budget percentage. Price signals: scarcity factor increases as budget depletes. Soft gate: zero
budget produces `deferred` tier, not an error.

## 10. Open items
- Session budget source — who sets it? Hardcoded? Config? Dynamically adjusted? (C1).
- Degradation tier thresholds (C1) — at what % remaining does `full` → `shallow` → `deferred`?
- The scarcity factor curve shape (C1) — linear? exponential? Needs invariants-first fitting.
- Whether budget replenishment is possible mid-session (ties to A2 restoration model / A8 ETR).
