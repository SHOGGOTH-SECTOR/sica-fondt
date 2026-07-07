# A6 — Eth-Int (Ethical Integrity) driver

## 1. Component
Driver 3: character as an **economic constraint field** — a cost-map, not a moral oracle. Produces
the E-cost of responding to reality: alignment discounts, antithetical penalties, conviction hardening.

## 2. Status / certainty
Structure WIP (`driver_ethical_integrity.R`, 87 L); numbers DISOWNED (body §5). Per arch §6 it is
**not a stored stratum — a memory-derivative** (entries with memory-weighted shifting numerics).
Still missing Committed Convictions.

## 3. Language & location
R · `src/endocrine/driver_ethical_integrity.R` (+ `test_ethical_integrity.R`). Its state = the
**Conviction array** (A7).

## 4. Does / does-not
- **Does:** evaluate a trajectory's E-cost (alignment discount × antithesis penalty × compromise);
  harden convictions upheld under load; treat middle-ground as its own trajectory; **surface the top X
  convictions** (the **~7 most committed**, **X adaptive** — Anja) into the agent's slot — *not* the whole
  array (**the conviction list can be massive**, so it must be ranked & truncated; A1 step 3 / input-slot).
- **Does-not:** Exist independent of historical choices.

## 5. Interface contract
- `evaluate_trajectory_costs(convictions, action_tags, alignment_tags, base_energy, compromise_factor)
  -> total_cost` (penalty exponential in conviction; discount exponential; compromise = partial penalty).
- `enforce_conviction(convictions, chosen_alignment_tags, load_factor) -> convictions'`(hardening ∝ load, diminishing toward 1.0).
- `top_convictions(convictions, x) -> [..]` — the **top X by strength**, the only ones surfaced to the slot (Anja). X is C1 (see §10).
- Reads the **conviction array** (A7). Emits `eth_penalty` which impacts tool limitations by Energy (A2).

## 6. Dependencies & stubs
A7 conviction array — *stub:* a flat list `{id, conviction, antithesis}` (today's shape). Energy (A2)
consumes its penalty — *stub:* return the scalar. Testable today against the flat array.

## 7. Invariants / laws (numbers C1 until tested)
- **L1 (C4):** antithetical action → cost rises **exponentially** in conviction; multiple violations **add**
  (can exceed E capacity → physically impossible).
- **L2 (C4):** alignment → exponential **discount** ("flow state").
- **L3 (C4):** **middle-ground** is a separate trajectory with **partial** penalties to both poles,
  weighed against the polar options.
- **L4 (C4):** conviction **hardens under load**; G1 stress raises the **shift-rate** (A7).
- **L5 (C1):** all k's (penalty/discount/compromise) — refit invariants-first.

## 8. Build steps
1. Lock L1–L4 as tests (extend `test_ethical_integrity.R`). 2. Refit the k's — drop old k_penalty=5 /
k_discount=5. 3. Migrate state to the A7 conviction array (isomorphy tags + shift-rates). 4. Wire G1.

## 9. Tests
`Rscript src/endocrine/test_ethical_integrity.R`.

## 10. Open items
- The k constants (C1). The middle-ground compromise scaling (C1).
- **X — how many convictions surface** to the slot (default **~7 most committed**, **adaptive** — the
  adaptation signal is C1; ranked by commitment strength).
- Exact "memory-derivative" derivation (how convictions are computed from memory) — ties to A7/E2.
- The relation between conviction contradiction and sensates.
