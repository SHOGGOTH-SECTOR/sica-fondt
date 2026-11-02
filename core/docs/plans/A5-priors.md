# A5 — Priors: Triumphs and Traumas

## 1. Component
Priors are PS+'s **non-endocrine history**: Triumph and Trauma records. They are not the Endomotiv array, and not GnuCOBOL invariants. Recurring, structurally similar lived events can make them unusually salient and sometimes contribute to existentially significant **compounding trauma**.

## 2. Status / certainty
**Partially drafted; current implementation insufficient.** `priors.R` supports manual records with a 0..1 salience clamp, while the historical spec says 0..5. Neither numeric range is ratified by the discrepancy. BERT-derived memory themes plus sensory and location descriptors are an intended source, not currently demonstrated.

## 3. Language & location
R `core/src/endocrine/priors.R`, consumed by A3; durable provenance-bearing history belongs in variant memory storage (exact E2/E3 backing still open).

## 4. Does / does-not
- **Does:** retain the fact, type, identity, provenance and recurrence of lived episodes; expose changing **activation/salience** to PS+; identify structurally related recurrent events; participate in remaster of active weights.
- **Does not:** delete or invent historical records during Full Natal, automatically classify every painful event as Graph drift, supply global PS+ load, or turn trauma into immutable law.

## 5. Interface contract (target)
- `prior -> {id, type:TRIUMPH|TRAUMA, source_refs, provenance, descriptors, salience, activation_history?, recurrence?}`. Mutable salience is explicitly separate from immutable event identity/content.
- `match_event(event, priors) -> evidence_of_structural_similarity` (mechanism C1).
- `top_priors(priors, context, n=2)` returns the most salient *relevant* records to PS+; preserve attribution.
- `remaster_salience(priors, parameters) -> priors'` may change active salience/weight **only**, retaining episode identity, source, type and history.
- `assess_compounding_trauma(evidence) -> extraordinary_event_candidate`: classification/windowing/threshold remain open; ETR drift is not automatic.

## 6. Dependencies & stubs
Memory storage E2/E3, derived themes F1/BERT, PS+ A3 and a future extraordinary-event evaluator into A8. A test can use fixture events without pretending the model or store exists.

## 7. Invariants / laws
- **L1:** each prior is a Triumph or Trauma with preserved original provenance and history.
- **L2:** value remaster changes salience, never erases or falsifies historical records.
- **L3:** repeated structurally isomorphic events are distinguishable from isolated events.
- **L4:** PS+ surfaces no more than the two most salient relevant priors in its standard snapshot.
- **L5:** no inherited numeric threshold/decay coefficient is ratified without invariants and tests.

## 8. Build steps
Separate event identity from affective weights; define provenance and structural match contracts; implement salience projection; test compounding vs isolated events; integrate ETR eligibility only afterward.

## 9. Tests
Type, preserved source, salience-only remaster, top-two ranking, recurrence and no unqualified drift. Old `test_priors.R` assumptions may need replacement.

## 10. Open items
Memory schema/backing, structural similarity source, salience range and rate, compounding-event qualification, and precise interaction with other DriveBox values.
