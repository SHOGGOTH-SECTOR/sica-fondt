# A5 — Priors database

## 1. Component
PS+'s non-endocrine "stray": the records of the self — high-salience **Triumphs and Traumas**
(scar/reward tissue). When a current event structurally matches a prior, it activates and injects
a large, specific argument into PS+ load.

## 2. Status / certainty
Structure WORKING (`priors.R`, 63 L). As a *database* (query/decay/persistence), C3.

## 3. Language & location
R · `src/endocrine/priors.R` (consumed by PS+ A3). Persistence backing → storage (E2/E3) later.

## 4. Does / does-not
- **Does:** store prior records; return top active priors above a salience threshold; track
  activation counts; decay salience over time.
- **Does-not:** aggregate load (A3) or decide; it is memory tissue, queried by PS+.

## 5. Interface contract
- **Record:** `{ id, type∈{TRAUMA,TRIUMPH}, salience(0..1), payload(str), activation_count }`.
- `init_priors_state() -> store` · `add_prior(store,id,type,salience,payload) -> store'` ·
  `get_top_active_priors(store, threshold=?) -> [record] (desc salience)` ·
  `activate_prior(store,id) -> store'` · `decay_prior(store,id,rate=?) -> store'`.

## 6. Dependencies & stubs
None upstream. The **match** that activates a prior (structural similarity of current event ↔ prior)
is upstream of A5 — *stub:* call `activate_prior(id)` directly for tests.

## 7. Invariants / laws
- **L1 (C5):** type ∈ {TRAUMA, TRIUMPH} only (invalid types error).
- **L2 (C4):** salience clamped 0..1; top-active sorted descending; only ≥ threshold are "active."
- **L3 (C4):** activation is tracked; salience decays over time (for migration cycles).
- **L4 (C1):** threshold + decay-rate constants — refit invariants-first.

## 8. Build steps
1. Lock the record + L1–L3 as tests. 2. Refit threshold/decay (drop old 0.8 / 0.01 unless re-derived).
3. Define the **match** interface (how an event activates a prior) — likely semantic, ties to A4/A7 tags.
4. Add persistence (E2/E3) once storage specs land.

## 9. Tests
`Rscript src/endocrine/test_*` (PS+ tests exercise priors); add a dedicated priors test for L1–L3.

## 10. Open items
- The **match** mechanism (event ↔ prior structural similarity) — C1.
- Persistence backing (VARIANT store E2 vs RAG E3) — C1.
- Threshold/decay constants (C1).
