# M6 — Provenance chain

## 1. Component
The chain of custody through the stomach: tracks **where input came from** and **what the stomach
did to it**, so that digested content is never mistaken for original content and Ada (D1) can
enforce S1/S2 with full information. Solves the provenance question from the economy organ review:
the stomach transforms external input into organ-secretion output, but the *origin* must not be
lost.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. The current smoke test sets `OrganSecretion` provenance on stomach output
(`main.pony:29`) with no record of the original input's provenance. This is the gap that risks
S1/S2 violation. Role C4 (the need is clear); implementation C1.

## 3. Language & location
TBD · part of `src/economy/`. Likely a data structure carried alongside digested context, not a
separate service. Must be representable in both Pony (bus side) and Ada (border side).

## 4. Does / does-not
- **Does:** create a `ProvenanceChain` for each input entering the stomach; record each
  transformation step (ingestion, classification, digestion, yield); attach the chain to the
  yielded envelope (M5) so Ada sees the full history; enable Ada to distinguish "organ-processed
  external input" from "organ-generated internal content".
- **Does-not:** decide trust (Ada does); authenticate sources (the bus provenance system does);
  filter or reject based on provenance (M0-L2 — digestion doesn't suppress).

## 5. Interface contract
- `chain_start(original_provenance: Provenance, source: OrganId, input_hash: str) -> ProvenanceChain`.
- `chain_step(chain: ProvenanceChain, step: TransformStep) -> ProvenanceChain`.
  `TransformStep { stage, transformer, timestamp }`.
  `stage` ∈ { `ingested`, `classified`, `digested`, `yielded` }.
- The final `ProvenanceChain` is:
  ```
  { original_provenance: Provenance,   -- what the input was before the stomach
    original_source: OrganId,           -- who sent it (World, MoRAG, etc.)
    input_hash: str,                    -- hash of raw input for audit
    steps: [TransformStep],             -- what the stomach did, in order
    is_external_origin: bool }          -- convenience flag for Ada: TRUE if
                                        --   original_provenance ∈ {External, UserInput}
  ```
- `is_external_origin` lets Ada apply S1 screening to digested-but-originally-external content
  without parsing the full chain.

## 6. Dependencies & stubs
- Ichor `Provenance` / `OrganId` (existing) — input types.
- M1 ingestion — creates the chain at `ingested` step.
- M2 digestion — adds the `digested` step.
- M5 context yield — attaches the chain to the envelope; *stub:* pass-through.
- Ada D1 `Trust_Guard` — consumer of the chain; *stub:* print chain on receipt.

## 7. Invariants / laws
- **L1 (C5):** the chain is **immutable once created** — steps are appended, never modified or
  removed. Like the COBOL invariant vault (S3), the provenance record doesn't get rewritten.
- **L2 (C5):** **S2 compliance** — the original provenance is **never reclassified**. The bus
  transport field may say `OrganSecretion` (because the stomach is an organ emitting output), but
  `original_provenance` in the chain preserves the true origin. This is not reclassification;
  it's layered provenance.
- **L3 (C4):** **S1 compliance** — content with `is_external_origin = TRUE` tells Ada that this
  traffic **originated externally** even though it arrives as organ output. Ada applies its full
  external-traffic screening (rate, blocklist, trust) to such content.
- **L4 (C3):** the `input_hash` allows **audit verification** — given the original input and the
  hash, you can confirm the chain refers to the right content.

## 8. Build steps
1. Define `ProvenanceChain` and `TransformStep` shapes.
2. Wire chain creation in M1 (ingestion) and step-append in M2 (digestion).
3. Wire chain attachment in M5 (yield → envelope metadata).
4. Extend Ada's `Trust_Guard` (or its stub) to read `is_external_origin` and apply S1 screening.

## 9. Tests
Chain integrity: steps accumulate in order; no mutation. S2: original provenance survives all
transforms. S1: `is_external_origin = TRUE` for external/user input; `FALSE` for organ-to-organ.
Hash: chain's `input_hash` matches hash of the raw input.

## 10. Open items
- Hash algorithm (SHA-256? lightweight alternative for performance?).
- Whether Ada needs the full chain or just `is_external_origin` + `original_provenance` (start
  with the full chain; Ada can ignore what it doesn't need).
- Cross-seam representation (Pony chain → C/Fortran seam → Ada record).
