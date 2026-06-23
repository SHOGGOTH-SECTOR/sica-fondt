# D3 — Mini-rag / toolschema (procedural memory)

## 1. Component
Just-in-time **tool-schema lookup** at the output boundary: fires right before the LLM emits a tool
call, retrieving the correct schema so the call is shaped correctly rather than hallucinated.
Muscle memory — the grip arrives pre-loaded at the moment of use.

## 2. Status / certainty
STUB (cycle step 19 is a placeholder in `ada_medium`). C3.

## 3. Language & location
GNU Guile · new location e.g. `src/mini_rag/`. (Schema-expression notation was "J-expression"; J is cut —
notation now Guile **s-expressions** or R, see Open.)

## 4. Does / does-not
- **Does:** at step 19, retrieve the schema for the tool the cognition intends to call, and pack it for routing.
- **Does-not:** route (Ada D1) or hold declarative memory (that's Ada-RAG / E3). Ada-RAG = what-you-know;
  mini-rag = what-your-hands-know.

## 5. Interface contract
- `pack_schema(intent) -> tool_schema` (procedural; fires at step 19, output boundary).
- Output is handed to Ada (D1) `route` at step 21.
- Schema store format: **s-expression** tool schemas (Guile-native), keyed by tool id.

## 6. Dependencies & stubs
Tool registry (what tools exist) — *stub:* a small fixed schema map. C3 calls it at step 19 — *stub:* identity passthrough.

## 7. Invariants / laws
- **L1 (C4):** fires at the **moment of use** (step 19), pre-routing — not during deliberation.
- **L2 (C4):** procedural only (schemas), distinct from declarative Ada-RAG.

## 8. Build steps
1. Choose schema notation (s-expr vs R) — see Open. 2. Build the schema store + `pack_schema`.
3. Wire into cycle step 19 (C3) and hand to D1 routing.

## 9. Tests
Schema retrieval for a known intent; unknown-intent fallback; "fires only at step 19" sequencing test.

## 10. Open items
- **Schema-expression notation** (Guile s-expr vs R) — the leftover from the J cut (C1).
- Tool registry source / how schemas are authored (C1).
