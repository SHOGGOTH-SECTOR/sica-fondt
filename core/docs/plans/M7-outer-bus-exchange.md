# M7 — Outer-bus exchange

## 1. Component
The stomach's economic relationships with its **outer-bus peers**: MoRAG (F1), SAE (F2),
microagents (F3). How the economy organ requests, receives, and pays for services from other
outer organs — and what it provides in return. The smoke test already shows
`Stomach → MoRAG` (`main.pony:37`); this spec defines the full exchange protocol.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. One hard-coded `Stomach → MoRAG` message exists in the smoke test.
No protocol, no cost tracking, no bidirectional exchange defined. Role C2; implementation C1.

## 3. Language & location
TBD · part of `src/economy/`. Exchange happens over Ichor (Pony actors + Envelope), so the
protocol is Envelope-based. The exchange logic lives in the economy organ; peers implement
their side independently.

## 4. Does / does-not
- **Does:** request world context from MoRAG before/during digestion (enrich the digest with
  retrieved knowledge); receive SAE monitoring signals (if SAE detects anomalies in the stomach's
  outputs); coordinate with microagents for delegated sub-tasks (e.g. "fetch and pre-chew this
  URL"); track the cost of all exchanges in M3.
- **Does-not:** route traffic (Ichor broker does); bypass Ada for any membrane-bound content
  (outer-to-outer is fine; anything heading inward crosses D1); command peers (it requests; they
  may decline).

## 5. Interface contract
- **Stomach → MoRAG:**
  `request_context(query: str, budget_limit: num) -> Envelope` — ask MoRAG for relevant world
  context to enrich a digestion. `budget_limit` caps how much the retrieval may cost (MoRAG
  reports actual cost back; M3 records it).
- **Stomach → Microagents:**
  `delegate(task: str, budget_limit: num) -> Envelope` — delegate a sub-task (fetch, pre-process)
  to a microagent. Same budget/cost protocol.
- **SAE → Stomach:**
  `anomaly_signal(finding: str) -> Envelope` — SAE pushes a signal if it detects anomalous
  stomach output. The stomach logs it (M3) but does not self-correct (F2-L2: detection only,
  no closed elimination loop).
- All exchange envelopes use `OrganSecretion` provenance (outer-to-outer, no membrane crossing).

## 6. Dependencies & stubs
- Ichor `Broker` + `Envelope` (existing) — transport.
- MoRAG (F1) — context provider; *stub:* fixed context response.
- SAE (F2) — anomaly detector; *stub:* no signals.
- Microagents (F3) — task delegates; *stub:* echo task back.
- M3 cost ledger — records exchange costs.
- M4 budget governor — caps exchange spending via `budget_limit`.

## 7. Invariants / laws
- **L1 (C5):** outer-to-outer exchange **never crosses Ada** — it stays on Ichor. Only the final
  digested output (M5) crosses the membrane. This is by design: peer coordination is "skin-level"
  and doesn't need border screening.
- **L2 (C4):** every exchange has a **budget limit** — no unbounded retrieval or delegation. The
  stomach asks for what it can afford (M4).
- **L3 (C3):** exchanges are **request/response, not streaming** — the stomach sends a request,
  waits for a response (or timeout), and proceeds. No long-lived channels between peers.
- **L4 (C3):** the stomach **never self-corrects** based on SAE signals — it logs them. Correction
  is a G1/G2 governance concern, not the organ's.

## 8. Build steps
1. Define the exchange envelope subtypes (request_context, delegate, anomaly_signal).
2. Implement Stomach → MoRAG context request (extend the existing `main.pony` wire).
3. Implement budget-limited exchange (M4 check before request; M3 record on response).
4. Implement SAE → Stomach anomaly logging.

## 9. Tests
MoRAG exchange: request sent, response received, cost recorded. Budget limit: exchange rejected
when over budget. Anomaly signal: logged but no state change in the stomach. Outer-only: no
exchange envelope targets `AdaBorder`.

## 10. Open items
- Whether MoRAG enrichment happens **before** digestion (pre-chew with context) or **during**
  (RAG-augmented digestion — the small model sees retrieved context alongside input). Big design
  fork (C2).
- Timeout/fallback when a peer doesn't respond (digest without enrichment? retry?).
- Microagent delegation scope — what tasks can be delegated vs what the stomach must do itself.
