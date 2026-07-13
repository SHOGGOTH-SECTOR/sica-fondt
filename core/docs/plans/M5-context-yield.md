# M5 — Context yield (absorption)

## 1. Component
The stomach's output shaper: takes `DigestedContext` from M2 and **packages it into the form Ada
(D1) expects** — an Ichor `Envelope` with the right shape, provenance metadata (M6), and
degradation annotations. This is the absorption step: what the organism actually absorbs from
what was digested.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. The smoke test (`main.pony:29`) hard-codes a string payload
`"digested context: <pre-chewed user turn>"`; no real output shaping exists. Role C3;
implementation C1.

## 3. Language & location
TBD · part of `src/economy/`. Likely Pony (produces `Envelope` directly for bus transport) or a
thin adapter between M2's output and the Ichor envelope shape.

## 4. Does / does-not
- **Does:** take `DigestedContext` (M2) + provenance chain (M6) + degradation tier (M4); package
  into an Ichor `Envelope` with `OrganSecretion` provenance; attach metadata: original provenance
  origin, digestion tier, summary length, extraction count; emit the envelope to the Ichor broker
  for delivery to Ada.
- **Does-not:** digest (M2 does); decide whether Ada admits it (D1 does); transform the content
  further — it packages, it doesn't re-process.

## 5. Interface contract
- `yield(context: DigestedContext, chain: ProvenanceChain, tier: DegradationTier) -> Envelope`.
- The `Envelope` payload is structured (not a raw string):
  ```
  { summary: str,
    extractions: [{ key, value }],
    meta: { original_provenance: Provenance,
            digestion_tier: DegradationTier,
            source_ref: str,
            actual_cost: num } }
  ```
- The envelope's bus-level `provenance` field is `OrganSecretion` (the stomach is an organ); the
  **original** input provenance is carried inside `meta.original_provenance` so Ada can inspect
  it (M6 compliance).
- `dest` is always `AdaBorder`.

## 6. Dependencies & stubs
- M2 `DigestedContext` — upstream; *stub:* canned digested context.
- M6 `ProvenanceChain` — provenance metadata; *stub:* pass-through original provenance.
- M4 `DegradationTier` — annotation; *stub:* always `full`.
- Ichor `Envelope` (existing) — output shape.
- Ichor `Broker` (existing) — delivery.

## 7. Invariants / laws
- **L1 (C4):** every yielded envelope carries the **original provenance** in metadata — Ada can
  always determine what the digested content was *before* the stomach touched it (S1/S2 compliance
  via M6).
- **L2 (C4):** the degradation tier is **visible** in the envelope — Ada and the Brain know whether
  they're getting a full digest or a shallow/deferred one. No silent quality degradation.
- **L3 (C3):** yield is **stateless** — it packages what it receives; it holds no buffer, no queue,
  no memory of previous yields.

## 8. Build steps
1. Define the structured payload shape (extend beyond raw string).
2. Build the `yield` function (DigestedContext + ProvenanceChain + tier → Envelope).
3. Wire M2 → M5 → Ichor Broker → Ada.
4. Update the smoke test (`main.pony`) to use structured payloads instead of hard-coded strings.

## 9. Tests
Shape: yielded envelope has all required metadata fields. Provenance: original provenance survives
in `meta.original_provenance`. Tier annotation: each degradation tier correctly tagged. Stateless:
two consecutive yields with different inputs produce independent envelopes.

## 10. Open items
- The structured payload encoding (JSON? Pony-native? Ada-compatible binary?) — must be parseable
  by Ada's `Trust_Guard` on the other side of the seam.
- Whether Ada needs to understand degradation tiers or just passes them through to the Brain.
- Batch yields (multiple digested contexts in one envelope vs one-per-envelope).
