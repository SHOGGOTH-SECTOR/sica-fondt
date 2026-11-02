# A3 — PS+: Primal Sensates+

## 1. Component
PS+ belongs **inside E**. It receives the Endomotiv field (A4) and memory-derived Triumph/Trauma Priors (A5), projects bodily signals directly to cognition, and modulates the **cost** of E tool calls.

## 2. Status / certainty
**Design reconciled; R runtime nonconforming.** The old `driver_ps_plus.R` has unresolved references and aggregate-load assumptions. Do not call that implementation ready.

## 3. Language & location
R `core/src/endocrine/driver_ps_plus.R`, referencing A4 and A5; exact long-term language/transport not finalized.

## 4. Does / does-not
- **Does:** surface **all 30** independent Endomotiv channels raw (zeros included); add the **two most salient relevant** Triumph/Trauma priors; exert physiological cost pressure on E; signal the homunculus directly through Ada.
- **Does not:** reduce sensation to a sum, invent contradictory-pair friction, adjudicate reality, gate actions, or induce ordinary ETR drift.

## 5. Interface contract (target)
- `evaluate_reality(PS+) -> {sensates[30], prior_signals[<=2], is_logical:false}` (read-only).
- `price_influence(PS+,tool,context) -> modifier` is a distinct output from sensation; combination and representation not yet specified.
- Sensational text must carry channel identity, magnitude and trajectory when available; preserve source attribution. Sensates are bodily claims, **not** truth assertions that override Ada provenance.

## 6. Dependencies & stubs
A4 Endomotiv and A5 Priors; E A2 for pricing; A1 for delivery. Current BERT-derived prior activation is a planned source, not implemented fact.

## 7. Invariants / laws
- **L1:** sensation is not a logical proof; its persuasive power must not be replaced with a single abstract scalar.
- **L2:** all 30 channels surface separately with zeros; priors are a separately ranked top two.
- **L3:** PS+ communicates to cognition **and** affects tool economics in parallel.
- **L4:** ordinary affective fluctuation does not automatically count as major compounding trauma sufficient to move ETR. Qualification belongs to an extraordinary-event contract.

## 8. Build steps
Repair A4 and the PS+ R adapter; remove aggregation; define provenance-preserving prior activation and cost interface; add tests before wiring the Ada boundary.

## 9. Tests
R tests must cover channel count and zero visibility, top-two prior selection, raw/snapshot purity, dual outputs, and no unconditional Graph drift.

## 10. Open items
Language of sensational output, price-modifier function, salience ranking, derived prior matching, and complete Endomotiv roster.
