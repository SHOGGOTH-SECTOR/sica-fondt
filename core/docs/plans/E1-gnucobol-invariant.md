# E1 — The 3 GnuCOBOL invariant stores  *(DESIGN-FIRST)*

## 1. Component
The foundational non-shifting memory layer: **three GnuCOBOL stores** — sparse, fixed-format,
**write-only-at-downtime**, built to outlive the model. The bedrock the rest of memory sits on.

## 2. Status / certainty
DESIGN-FIRST · store-format **C5** (GnuCOBOL chosen), **but the 3 roles + contents are C1** (skeletal —
arch §10 said "contents more complex than modeled"). **What the three stores ARE needs confirmation.**

## 3. Language & location
GnuCOBOL · new location e.g. `src/invariant/` (three programs/copybooks).

## 4. Does / does-not
- **Does:** hold the invariant core(s) in fixed-format records; admit writes **only at downtime**; serve reads.
- **Does-not:** hold shifting state (that's VARIANT E2 / RAG E3) or compute (it's storage).

## 5. Interface contract (proposed)
- Three fixed-format record sets (copybooks), one per store. `read(store, key) -> record` ;
  `write(store, record)` **gated to downtime only** (per arch §10).
- Sits behind Ada (D1); writes carry provenance.

## 6. Dependencies & stubs
None upstream. Consumers (Eth-Int memory-derivative A7, priors A5, VARIANT E2) read it — *stub:* an
in-memory fixed-format map until the COBOL programs exist.

## 7. Invariants / laws
- **L1 (C5):** **write-only-at-downtime** — no mid-run mutation of the invariant core.
- **L2 (C5):** sparse, fixed-format, model-outliving (survives a Brain swap).
- **L3 (C4):** all writes carry provenance (D1).

## 8. Build steps
1. **Confirm the 3 stores' roles** (the blocking question — see Open). 2. Define the three copybooks.
3. Implement read + downtime-gated write. 4. Wire consumers (A5/A7/E2) via stubs first.

## 9. Tests
Downtime-write gate (rejects mid-run write); fixed-format round-trip per store; read-after-downtime-write.

## 10. Open items
- **What are the 3 GnuCOBOL stores?** (roles/division of the invariant core) — **needs Anja's call** (C1).
- Exact record schemas (C1). Downtime definition / trigger (C1).
