# E3 — RAG family (declarative memory + per-room cross-store)  *(DESIGN-FIRST)*

## 1. Component
Two memories with different machinery: **declarative/relational room context** (vector-RAG, namespaced
per thread) and the **per-room Celtic-Cross store** (deterministic keyed — `room_id → current cross`).

## 2. Status / certainty
DESIGN-FIRST · cross-store + room-RAG split **C4** (mechanism decided); backing **C1**.

## 3. Language & location
TBD · new location e.g. `src/rag/`. Sits behind Ada (D1). This is **Ada-RAG = what-you-know**
(declarative), distinct from mini-rag D3 (procedural).

## 4. Does / does-not
- **Does:** store/retrieve per-thread relational context (vector-RAG); store/restore each room's live
  Celtic Cross by exact key (**not** vector search).
- **Does-not:** hold procedural tool schemas (D3) or the invariant core (E1).

## 5. Interface contract (proposed)
- **Cross-store:** `get_cross(room_id) -> spread` / `put_cross(room_id, spread)` — **deterministic keyed**,
  never similarity search (similarity could return the *nearest* room's spread → wrong lens).
- **Room-RAG:** `retrieve(thread_ns, query) -> context[]` — namespaced per thread so room A can't bleed into B.
- Both behind Ada (D1); writes carry provenance tags.

## 6. Dependencies & stubs
B3 cross (what's stored) — *stub:* canned spread. D1 provenance — *stub:* allow-all. B2 reshuffle reads/writes the cross.

## 7. Invariants / laws
- **L1 (C4):** live cross per room → **deterministic keyed** store, never vector-RAG.
- **L2 (C4):** room relational context → vector-RAG, **namespaced per thread** (no cross-room bleed).
- **L3 (C4):** all writes carry provenance (D1).

## 8. Build steps
1. Choose backings (keyed KV for cross-store; vector store for room-RAG). 2. Implement both contracts.
3. Wire B2/B3 (cross lifecycle) + the cycle's step-2 enrich (C3).

## 9. Tests
Cross-store exact-key round-trip (and a test that it does NOT do nearest-match); room-RAG namespace isolation.

## 10. Open items
- Backings (C1). Vector store choice (copyleft-first). Provenance tag format (shared with D1/E1/E2).
