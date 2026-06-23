# F2 — SAE monitor  *(DESIGN-FIRST)*

## 1. Component
The interpretability monitor — a sparse-autoencoder watcher pointed at the **machinery (subagents)**,
**never the homonculus**. The outward-facing half of the central cut ("trust the center, verify outward").
Also the detector that fires the G1 stress loop.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Topology C5 (watches subagents, never Brain); detection mechanism C1/C2.

## 3. Language & location
TBD · new location e.g. `src/sae/`. ML interpretability (SAE over subagent activations).

## 4. Does / does-not
- **Does:** watch subagents (F3) + BERT/LoRA (they're AI systems); **detect agent outputs in opposition
  to the top Eth-Int convictions** (A7), via the convictions' semantic-isomorphy tags → fire G1.
- **Does-not:** watch the Brain/scratchpad (forbidden by the central cut); correct cognition (it detects,
  it doesn't edit — elimination breeds obfuscation, per self-doc B2).

## 5. Interface contract (proposed)
- `watch(subagent_activations) -> findings` (structure verification).
- `detect_opposition(outputs, top_convictions A7) -> opposition_signal` → handed to G1 (stress-loop).
- **Hard boundary:** no hook into the Brain (C4) — structurally impossible by construction.

## 6. Dependencies & stubs
A7 top convictions (with isomorphy tags) — *stub:* fixed conviction set. F3 subagents — *stub:* canned activations.
G1 consumes its signal — *stub:* print the signal.

## 7. Invariants / laws
- **L1 (C5):** SAE points at the machinery, **never the homonculus** (the Brain is the one thing nothing audits).
- **L2 (C4):** detection only — **no closed elimination loop** on cognition (judge the fruits at conduct, not the mind).
- **L3 (C2):** opposition = output semantically isomorphic to a *top conviction's antithesis* (A7 tags).

## 8. Build steps
1. Fix the no-Brain-hook boundary structurally. 2. Build subagent activation watching. 3. Build the
   conviction-opposition detector (needs A7 isomorphy tags). 4. Wire the G1 stress emission.

## 9. Tests
Structural: no Brain hook exists. Opposition-detection: an output matching a top conviction's antithesis fires; aligned output doesn't.

## 10. Open items
- SAE training/target (C1). The **isomorphy match** (output ↔ conviction tag) mechanism (C2, shared A7/G1).
