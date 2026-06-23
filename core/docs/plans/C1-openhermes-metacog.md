# C1 — OpenHermes Agent ↔ Metacognitive Cycling  *(PRIORITY)*

## 1. Component
The seam where the **OpenHermes Agent** harness mounts the Gen.03 body and drives the **4+4
metacognitive inference cycle**. This is the integration spine: Hermes brings model-agnostic
harnessing (persistent memory, skills, tool-call parsing, Atropos RL); the body brings the
organ-systems cognition. C1 defines how a turn flows from Hermes through the cycle and back.

## 2. Status / certainty
DESIGN-FIRST. Entry mechanism C4 (the MCP bridge exists, `mafiabot.adb` + `hermes_protocol`);
the Hermes-side wiring and Level1 handoff are C1/C2.

## 3. Language & location
OpenHermes (harness, external) ↔ Ada/SPARK bridge. Existing: `mafiabot_core/src/mafiabot.adb`
(MCP stdio server), `mafiabot_core/src/protocol/hermes_protocol.{ads,adb}` (JSON-RPC).
New Hermes-side config/glue location TBD (Hermes `mcp_servers` entry + skill manifest).

## 4. Does / does-not
- **Does:** mount the body as a Hermes tool/MCP server; carry one user turn into the cycle
  scoped to a session key `(uid, channel, server)`; return the synthesized result; surface
  Drive-Box terrain + RAG context into the descent; let Hermes own memory/skills/RL.
- **Does-not:** *be* the cognition (that's C2/C4), route tools (that's Ada D1), or hold identity
  (that's B2). It is plumbing + sequencing, not an organ.

## 5. Interface contract
- **Hermes → body (per turn):** `{ input:str, uid:str, channel:str, server:str }` over JSON-RPC
  `tools/call` (already parsed by `Hermes_Protocol.Extract_Field`). Plus standard MCP
  `initialize` / `tools/list`.
- **body → Hermes:** `tools/call` result `{ content:str }` on success, JSON-RPC error otherwise
  (`Make_Tool_Result_Response` / `Make_Error_Response`).
- **Boot side-effect:** body fixes the Big-3 identity and writes `~/.hermes/SOUL.md` (B2).
- **Cycle internal contract:** each `tools/call` runs the 23-step cycle (see C3); step 2 pulls
  the Drive-Box snapshot (A1) + MoRAG context (F1) across Ada (D1); the 4+4 passes (C2) interleave
  Celtic-Cross draws (B3); step 19 mini-rag packs the tool schema (D3); step 21 Ada routes.

## 6. Dependencies & stubs
- Inference cycle C3 — *stub:* a pass-through that echoes input → lets C1 be tested as pure transport.
- Drive-Box A1, Tarot B1/B2/B3, MoRAG F1, mini-rag D3 — *stub:* each returns a canned block; C1
  only needs them present at their contract, not real.
- Hermes itself — *stub:* a local JSON-RPC driver script feeding `initialize`/`tools/list`/`tools/call`
  on stdin (the existing `mafiabot.adb` loop already speaks this).

## 7. Invariants / laws
- **L1 (C4):** every turn is scoped to its `(uid,channel,server)` session key — no cross-room bleed.
- **L2 (C4):** tool routing is **Ada's** job, not the LLM's (the LLM emits intent + packed schema).
- **L3 (C3):** methodology composition is **static** — the 4+4 ordering never changes per turn;
  responsiveness comes from Energy-gated compute (skip later passes when E low), not a learned router.
- **L4 (C2):** the coherence check (step 23) contrasts synthesized output vs final cognition — drift detector, not a reward signal to optimize.

## 8. Build steps
1. Write the laws + the turn-sequence as a doc-level contract (this file) → encode L1/L3 as tests
   on the bridge (session-key isolation; pass-count vs Energy).
2. Stand up the Hermes `mcp_servers` entry pointing at the `mafiabot` stdio binary; verify
   `initialize`/`tools/list`/`tools/call` round-trip with the C3-stub.
3. Wire Energy-gated compute: Drive-Box snapshot (A1) supplies E; C1 chooses how many of the
   4+4 passes run. Fit the gating thresholds invariants-first (no asserted cutoffs).
4. Resolve Level1 (see Open) and slot it into the `Hermes → Level1 → Ada` handoff.

## 9. Tests
- Bridge transport: feed canned JSON-RPC to the `mafiabot` binary (or stub), assert session-key
  scoping (L1) and that low-E input runs fewer passes (L3). Harness TBD (Ada test main + a shell driver).

## 10. Open items
- **Level1 — C1:** what it does and where it sits in `Hermes → Level1 → Ada`. Blocks full wiring.
- **Atropos RL integration — C1:** how/whether RL touches the cycle (must not optimize the
  coherence check, per L4).
- **Compute-gating curve — C1:** Energy→pass-count mapping, fitted invariants-first.
- **Reuse vs rebuild** the existing Ada `ada_medium` cycle (defunct-flagged) — decided in C3.
