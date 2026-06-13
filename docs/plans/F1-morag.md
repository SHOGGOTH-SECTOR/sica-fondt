# F1 — MoRAG (mixture-of-RAG)  *(DESIGN-FIRST)*

## 1. Component
The context assembler in the periphery: **BERT** classifies/routes the incoming situation, **LoRAs**
specialise, and it **injects** the assembled context on its way to the inference loop (crossing Ada).

## 2. Status / certainty
DESIGN-FIRST · ABSENT (no code). Role C4; implementation C1.

## 3. Language & location
TBD · new location e.g. `src/morag/`. ML toolchain (BERT classifier + LoRA adapters).

## 4. Does / does-not
- **Does:** classify/route (BERT), specialise (LoRA), assemble + inject context at cycle step 2.
- **Does-not:** police (D1 — and note **modulators like LoRA cross Ada too**, so a poisoned adapter meets
  Ada first); decide (C2/C4); hold the memory it draws from (E3).

## 5. Interface contract (proposed)
- `assemble(input, room_ns) -> injected_context` (BERT route → select LoRA(s) → pull E3 RAG → pack).
- Output crosses **Ada (D1)** before reaching the Brain; modulators (LoRA deltas) also pass D1's BBB.

## 6. Dependencies & stubs
E3 RAG (declarative source) — *stub:* fixed context. D1 (crossing) — *stub:* allow-all. Brain C4 consumes injection.

## 7. Invariants / laws
- **L1 (C5):** MoRAG **injects**, Ada **polices** — assembly is the organ's job, admission is Ada's.
- **L2 (C5):** modulators (steering vectors / LoRA) reach the Brain only by clearing Ada's BBB.
- **L3 (C4):** it is a **mixture** — BERT routes among specialised LoRAs.

## 8. Build steps
1. Define the assemble contract. 2. Stand up a BERT router (classify situation → LoRA selection).
3. Wire LoRA adapters + E3 retrieval. 4. Route output through D1 into step-2 enrich (C3).

## 9. Tests
Routing test (situation → expected LoRA); injection crosses a D1 stub; modulator blocked when provenance bad.

## 10. Open items
- Model/adapter choices + hosting (C1). LoRA adapter set (C1). Copyleft posture for ML deps.
