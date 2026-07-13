# M0 — Economy organ hub (the stomach)

## 1. Component
The economy organ — the organism's **stomach**. An outer organ on Ichor that **digests external
input into context** and **tracks the cost of doing so**. Hub for the M-series sub-components
(M1–M7): ingestion, digestion, cost ledger, budget governor, context yield, provenance chain,
outer-bus exchange. "Economy" = the organ economizes: it spends scarce resources (tokens, compute,
attention budget) to convert raw input into usable context, and **accounts for every unit spent**.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. A `Stomach` primitive exists in Ichor (`src/ichor/envelope.pony:20`) with
one smoke-test wire (`main.pony:29`), but no dedicated organ code. Role C4; implementation C1.

## 3. Language & location
TBD · new location e.g. `src/economy/`. The digestion core (M2) requires a small-model runtime;
the accounting/budget layers (M3–M4) can be any language that interops with Pony (Ichor) and Ada
(D1). Pony actors are the natural fit for the bus-facing facade.

## 4. Does / does-not
- **Does:** receive external input from Ichor; triage and classify it (M1); digest it via a small
  model into context (M2); track the resource cost of that digestion (M3); enforce budget limits
  and emit price signals to A2 (M4); shape output for Ada (M5); maintain provenance through the
  pipeline (M6); coordinate with outer-bus peers — MoRAG, SAE, microagents (M7).
- **Does-not:** police (Ada D1 does that); decide actions (the agent decides, per A1-L3); store
  memories (E*); route the bus (Ichor broker); reason or deliberate (it digests, it doesn't think).

## 5. Interface contract
- `ingest(external_input, provenance) -> classified_input` (M1 — triage + classify).
- `digest(classified_input) -> digested_context` (M2 — small-model transform).
- `record_cost(organ_id, action, resource_amt) -> receipt` (M3 — ledger entry).
- `check_budget(organ_id, proposed_cost) -> { allowed:bool, remaining:num }` (M4).
- `price_signal(tool_id) -> { resource_cost:num, budget_remaining:num }` (M4 → A2).
- `yield(digested_context) -> Envelope` (M5 — shaped for Ada, with M6 provenance chain attached).
- Output is an Ichor `Envelope` with `OrganSecretion` provenance, carrying the original input's
  provenance origin in metadata (M6).

## 6. Dependencies & stubs
- Ichor bus (D2) — existing `Broker` + `Envelope`.
- Ada border (D1) — existing `Trust_Guard` screens the output; *stub:* Ichor `Barrier`.
- A2 energy — consumes price signals (M4); *stub:* print signals.
- MoRAG (F1) — world-context retrieval; *stub:* fixed context.

## 7. Invariants / laws
- **L1 (C5):** the stomach is an **OUTER** organ — it rides Ichor, never the inner bus.
- **L2 (C4):** digestion does **not suppress** — it transforms for comprehension (summarize,
  classify, extract), never censors. Filtering is Ada's job (D1).
- **L3 (C4):** every resource expenditure is **accounted** — no digestion is "free"; the ledger
  (M3) records every token/compute unit spent.
- **L4 (C4):** provenance survives digestion — digested content retains its original provenance
  origin in metadata, even as bus transport uses `OrganSecretion` (see M6, S1/S2).

## 8. Build steps
1. Define the hub wiring: how M1→M2→M5 pipeline + M3/M4 accounting + M6 provenance + M7 peers
   connect. Decide: single Pony actor or actor-per-subcomponent.
2. Extend the existing `Stomach` primitive in Ichor to carry the hub facade.
3. Wire sub-components as their specs land (M1–M7).
4. Integrate price signals with A2 (energy driver).

## 9. Tests
Hub smoke: external input enters → classified → digested → yielded as Envelope → reaches Ada stub.
Cost recorded in ledger. Budget check returns correct remaining. Price signal emitted.

## 10. Open items
- Single actor vs actor-per-subcomponent (Pony concurrency model for the organ).
- Whether the hub owns state or is purely a wiring facade (stateless router vs stateful coordinator).
- The A2 price-signal protocol (push vs pull; frequency).
