# M2 — Digestion core (small-model)

## 1. Component
The stomach's engine: a **small language model** that transforms classified input (M1) into
**digested context** — structured, compressed, ready for Ada and ultimately the Brain. This is
what "digests external input → context" means concretely: summarization, extraction, reformatting,
and compression, performed by a model small enough to run cheaply and fast.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. bus-topology.md names it "small-model operated" but leaves the model
unspecified (listed as open). Role C3; implementation C1.

## 3. Language & location
TBD · `src/economy/digest/` or similar. Requires an inference runtime for the small model
(e.g. llama.cpp, ONNX, or an API call to a hosted small model). The wrapper is likely Pony
(bus-native) or Python (ML ecosystem), with a Pony actor facade on Ichor.

## 4. Does / does-not
- **Does:** take `ClassifiedInput` (M1); run the small model to produce `DigestedContext` —
  **summarize** (compress verbose input), **extract** (pull structured data from unstructured),
  **reformat** (normalize into the context shape Ada/Brain expect); report actual cost to M3.
- **Does-not:** classify (M1 already did); filter/censor (M0-L2 — digest for comprehension, not
  approval); reason or deliberate (the Brain does that); call tools or take actions.

## 5. Interface contract
- `digest(input: ClassifiedInput) -> DigestedContext { summary, extractions[], source_ref, actual_cost }`.
- `summary`: compressed natural-language context (the "chewed food").
- `extractions`: structured key-value pairs pulled from the input (entities, quantities, intents).
- `source_ref`: pointer back to the original input (for M6 provenance chain).
- `actual_cost`: real token count consumed (input + output), reported to M3 ledger.
- The model is invoked with a **system prompt specific to digestion** — not the agent's system
  prompt. The digestion prompt instructs: summarize, extract, reformat; do not opine, decide, or
  filter.

## 6. Dependencies & stubs
- M1 `ClassifiedInput` — upstream; *stub:* canned classified input.
- M3 cost ledger — receives `actual_cost`; *stub:* print cost.
- Small model runtime — *stub:* a deterministic mock that returns fixed summaries for known inputs
  (no model needed for unit tests).

## 7. Invariants / laws
- **L1 (C4):** digestion is **lossy compression, not judgment** — the model summarizes and
  extracts but never evaluates, approves, or filters the content. It chews; it doesn't taste.
- **L2 (C4):** the digestion prompt is **fixed and auditable** — not dynamically generated, not
  influenced by the input being digested (no prompt injection path from input to digestion
  instructions).
- **L3 (C3):** **actual cost is always reported** — every invocation records real token usage to
  M3; no "free" digestions.
- **L4 (C3):** the model is **small by design** — cost and latency must stay below the threshold
  where digestion becomes more expensive than passing raw input. If the model is too expensive,
  the organ is failing its economic purpose.

## 8. Build steps
1. Select the small model (candidates: Haiku-class, phi-3-mini, or similar; evaluate on
   summarization quality vs cost vs latency).
2. Write the fixed digestion system prompt.
3. Build the inference wrapper (model invocation + output parsing).
4. Wire M1 → M2 → M3 (cost reporting) → M5 (output shaping).

## 9. Tests
Mock model: known input → expected summary + extractions. Cost reporting: actual_cost recorded for
every invocation. Prompt integrity: digestion prompt is the fixed string (no injection). Latency:
invocation completes within budget (TBD threshold).

## 10. Open items
- **Model selection** (C1) — which small model, self-hosted vs API, quantization level.
- **Digestion prompt** (C1) — exact wording; needs empirical tuning against real inputs.
- Latency budget (C1) — max acceptable ms per digestion; ties to how it's invoked (batch vs streaming).
- Whether different input types (M1 classification) get different digestion strategies or one
  model handles all.
