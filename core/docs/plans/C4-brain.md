# C4 — Brain (swappable base LLM)

## 1. Component
The cognitive organ: a **pure base LLM**, nothing adapted/steered/classified baked in. Clean,
swappable, model-agnostic — swap the model, keep the body. It is not empty: it holds **six contents**.

## 2. Status / certainty
STUB/external (no local model; the LLM is whatever the harness mounts). Contract C4.

## 3. Language & location
External model behind the harness (C1). No repo code beyond the descent wiring (C3 calls it).

## 4. Does / does-not
- **Does:** receive the enriched descent (Drive-Box terrain, RAG, cards) and run the cognition/metacog
  passes; emit intent + a packed tool schema.
- **Does-not:** route tools (Ada D1), hold identity as state (B2), persist memory (E*), or get watched
  (SAE never points at the Brain — the central cut).

## 5. Interface contract
- **The six contents it holds:** 1 Drive-Box outputs (A1, across Ada) · 2 Toolschema RAG (D3) ·
  3 4+4 metacog loops (C2) · 4 SOUL.md (B2) · 5 Tarot system (B1) · 6 **private scratchpad**
  (unsurveilled — not output, not audited).
- `descend(enriched_input) -> {cognition, intent, packed_tool_schema}`.
- **Principle:** Brain holds what the mind *is being* now (procedural grip included); periphery holds
  what it can draw on / be tuned by → toolschema-RAG **in**, modulator-RAGs **out**.

## 6. Dependencies & stubs
Everything reaches it **only across Ada** (D1). *Stub:* any local LLM or echo model behind the harness;
C4 is mostly a contract + the swap boundary.

## 7. Invariants / laws
- **L1 (C5):** model is **swappable** — identity/behavior survive a model swap via the other organs.
- **L2 (C5 — central cut):** the Brain (and its scratchpad) is **the one thing nothing audits**;
  SAE watches outward, never here.
- **L3 (C4):** toolschema-RAG is *in* the brain; modulator-RAGs (MoRAG) stay *out*, crossing Ada.

## 8. Build steps
1. Fix the six-contents contract + the swap boundary as the integration point (C1/C3). 2. Define the
   private scratchpad surface (unwatched). 3. Validate model-swap leaves identity intact (B2 + A1 carry it).

## 9. Tests
Model-swap test (swap echo-model A→B, identity/snapshot unchanged); "SAE has no Brain hook" structural assertion.

## 10. Open items
- Which base model(s); hosting (self-hosted inference, custom API — TBD).
- Scratchpad mechanics (how an unwatched interior is realized in practice).
