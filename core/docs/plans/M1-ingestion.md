# M1 — Ingestion gateway

## 1. Component
The mouth of the stomach: **receives, classifies, and triages** external input before it enters the
digestion pipeline (M2). The first thing raw input touches inside the economy organ. Decides *how*
to digest — not *whether* (that's Ada's job after digestion).

## 2. Status / certainty
DESIGN-FIRST · ABSENT. The smoke test (`main.pony:29`) hard-codes a single string payload; no
classification or triage logic exists. Role C3; implementation C1.

## 3. Language & location
TBD · likely part of `src/economy/` or a Pony actor within the stomach. Classification could be
rule-based (fast, no model) or a lightweight classifier (BERT-tiny, shared with F1/MoRAG's BERT).

## 4. Does / does-not
- **Does:** accept raw `Envelope` payloads from Ichor; classify input by type (user utterance,
  tool output, system event, bulk data); assign a **digestion priority** (urgent / normal / bulk);
  estimate the **digestion cost** (token count of input × expected expansion factor) and check
  budget (M4) before forwarding to M2.
- **Does-not:** filter or censor (M0-L2); digest (M2 does); decide actions (agent decides);
  screen provenance (Ada D1).

## 5. Interface contract
- `ingest(envelope: Envelope) -> ClassifiedInput { type, priority, est_cost, original_provenance, payload }`
- `type` ∈ { `user_utterance`, `tool_output`, `system_event`, `bulk_data`, `unknown` }.
- `priority` ∈ { `urgent`, `normal`, `bulk` } — urgent skips any queue; bulk may be deferred or
  chunked under budget pressure (M4).
- `est_cost` = estimated token cost of digesting this input (input tokens + expected output tokens).
  M4 checks this against remaining budget before M2 proceeds.
- `original_provenance` = the `Provenance` from the inbound Envelope, carried through for M6.

## 6. Dependencies & stubs
- Ichor `Envelope` (existing) — input shape.
- M4 budget governor — budget check before forwarding; *stub:* always-allow.
- M2 digestion core — downstream consumer; *stub:* identity (pass-through).

## 7. Invariants / laws
- **L1 (C4):** classification is **descriptive, not prescriptive** — it labels the input for the
  pipeline's benefit, never decides what to do with it.
- **L2 (C4):** no input is **dropped** at ingestion — everything classified reaches M2 (possibly
  deferred under budget pressure, but never discarded). Only Ada may reject.
- **L3 (C3):** cost estimation is **conservative** — overestimate rather than underestimate, so
  budget checks err on the side of caution.

## 8. Build steps
1. Define the `ClassifiedInput` shape and the classification rules (start rule-based, no model).
2. Implement cost estimation (token counting + expansion factor).
3. Wire to M4 budget check (gate: proceed / defer / chunk).
4. Wire to M2 downstream.

## 9. Tests
Classification: each input type correctly tagged. Priority: urgent input not queued. Cost estimate:
known inputs produce expected token counts. Budget gate: over-budget input deferred, not dropped.

## 10. Open items
- Whether classification needs a model or rules suffice (start with rules; promote if accuracy
  demands it).
- The expansion factor (input tokens → output tokens) per input type — needs empirical data (C1).
- Queue/deferral mechanics for bulk input under budget pressure.
