# E2 — VARIANT stores  *(DESIGN-FIRST)*

## 1. Component
The shifting self: several stores — **beliefs · relationships · memories · self-image** — and the
(unspecified) mechanism by which they combine into "who you are now."

## 2. Status / certainty
DESIGN-FIRST · set **C3** (the four stores are named), **combine-mechanism + backing C1**
("projected together" was the nearest label, not the mechanism).

## 3. Language & location
TBD · new location e.g. `src/variant/`. Backing undeclared (not GnuCOBOL — that's the invariant E1).

## 4. Does / does-not
- **Does:** hold the four shifting stores; supply the memory that Eth-Int's conviction array (A7) and
  PS+'s priors (A5) derive from; combine into the live self-state.
- **Does-not:** be the invariant core (E1) or the identity face (B2 SOUL.md is the *standing* self; this is the *shifting* substrate).

## 5. Interface contract (proposed)
- Four stores: `beliefs`, `relationships`, `memories`, `self_image`; each `read/write` behind Ada (D1).
- `combine(beliefs, relationships, memories, self_image) -> who_you_are_now` — **mechanism undefined (C1)**.
- No append-only logs anywhere (arch §10).

## 6. Dependencies & stubs
E1 invariant (bedrock) — *stub:* in-memory. Consumers A5/A7 — *stub:* seed entries.

## 7. Invariants / laws
- **L1 (C4):** all memory sits behind Ada; writes carry provenance.
- **L2 (C5):** **no append-only logs** anywhere.
- **L3 (C1):** the combine-mechanism (how four stores → one self-now) — undefined.

## 8. Build steps
1. Choose backing. 2. Define the four store schemas. 3. **Design the combine-mechanism** (the hard open part).
4. Wire A5/A7 to derive from it.

## 9. Tests
Per-store read/write behind a D1 stub; no-append-only assertion; combine() determinism once defined.

## 10. Open items
- **Combine-mechanism** (C1, the central unknown). **Backing** (C1). Relationship to E1 invariant (C1).
