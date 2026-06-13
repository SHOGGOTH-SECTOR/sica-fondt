# A3 — PS+ (Primal Sensates+) driver

## 1. Component
Driver 2: the body. The engine of biopsychological pressure. Reads the endomotiv array (A4) +
priors (A5), aggregates into **Existential Load**, and emits **arguments, never logic**.

## 2. Status / certainty
Structure WORKING (`driver_ps_plus.R`, 63 L); aggregation numbers DISOWNED (body §5).

## 3. Language & location
R · `src/endocrine/driver_ps_plus.R` (sources `endocrine_array.R` + `priors.R`; + `test_ps_plus.R`).

## 4. Does / does-not
- **Does:** read active endomotiv vectors + visceral friction (A4); read top active priors (A5);
  emit existential load + a list of imperative present-tense **arguments**.
- **Does-not:** reason, gate, or decide (`is_logical = FALSE` is a hard contract); it asserts
  "X is happening," never "if X then Y."

## 5. Interface contract
- `init_ps_plus_state() -> { endocrines:A4, priors:A5 }`.
- `evaluate_reality(state) -> { existential_load:num, arguments:[str], is_logical:FALSE }`.
- Load = f(active vectors A4) + visceral_friction(A4) + Σ(active prior salience, A5). Weights **C1**.

## 6. Dependencies & stubs
A4 endomotiv array — *stub:* `init_endocrine_state()` with canned channel magnitudes.
A5 priors — *stub:* `init_priors_state()` + a couple `add_prior(...)`. Both already exist, so PS+
is testable today against real A4/A5.

## 7. Invariants / laws
- **L1 (C5):** output carries `is_logical = FALSE` — PS+ has no conditional gating.
- **L2 (C4):** contradictory active vectors generate **friction** ("systemic heat") that adds to load.
- **L3 (C4):** a structurally-matching prior injects a large, specific argument.
- **L4 (C1):** the load weighting (vector sum, friction coeff, prior×salience) — refit invariants-first.

## 8. Build steps
1. Lock L1–L3 as tests (extend `test_ps_plus.R`). 2. Refit L4 weights against the tests — drop the
old `salience*10` / friction constants. 3. Confirm the A4/A5 contracts it consumes (their specs).

## 9. Tests
`Rscript src/endocrine/test_ps_plus.R`.

## 10. Open items
- Argument register/format (how arguments are phrased for the input slot) — ties to A4 sensational lines.
- Load weighting constants (C1).
