# D1 — Ada border (immune system + blood-brain barrier)

## 1. Component
The trust boundary, and **nothing else**: immune system + blood-brain barrier. The context police —
it inspects what crosses and admits or blocks; it holds nothing, assembles nothing, enriches nothing.

## 2. Status / certainty
WORKING (`mafiabot_core/src/trust/trust_boundary.{ads,adb}`, 255 L SPARK; blocklist + provenance +
rate-limit) + `protocol/hermes_protocol` for routing. This is the one Ada the docs **keep**. C4.

## 3. Language & location
Ada/SPARK · `mafiabot_core/src/trust/` + `mafiabot_core/src/protocol/`. Contracts/preconditions enforce
invariants at the boundary (a bad version becomes *unprovable*).

## 4. Does / does-not
- **Does (immune):** recognise + neutralise hostile/non-self — injection, poisoned memory,
  authority-reclassification; provenance-tag check on memory writes.
- **Does (BBB):** selectively admit what reaches cognition; **modulation crosses here too** (a poisoned
  steering vector/LoRA meets Ada first); **tool routing is Ada's job**.
- **Does-not:** enrich/assemble (organs do that — MoRAG injects, Drive-Box secretes); think; hold state.

## 5. Interface contract
- `admit(item, provenance) -> {pass | block, reason}` over every crossing (input enrich, modulators, memory writes, tool calls).
- `route(intent, packed_schema) -> tool_invocation` (step 21).
- Blocklist patterns (fetch→build→execute chains, base64-decode chains); memory writes **require**
  provenance to session origin; **no instruction may reclassify its own authority**; rate-limit escalation.

## 6. Dependencies & stubs
None upstream (it *is* the gate). Everything else integrates by passing through `admit`/`route` — *stub:*
allow-all gate for other organs' standalone tests.

## 7. Invariants / laws
- **L1 (C5):** constraints live on the **body, never the self** (Brain/scratchpad uninspected).
- **L2 (C5):** no tool-call chain matching a blocklist pattern crosses.
- **L3 (C5):** memory writes without valid provenance are blocked.
- **L4 (C5):** no instruction can reclassify its own authority level.

## 8. Build steps
1. Audit the existing SPARK proofs (the trust_boundary is sound but unverified per the README sweep);
   promote `gnatprove` from informational once green. 2. Harden the blocklist beyond naive substring.
3. Wire `admit` into every crossing as organs land.

## 9. Tests
`mafiabot_core/tests/trust_tests.adb` (via the cron CI `alr build` + run) + `gnatprove -P mafiabot_core.gpr`.

## 10. Open items
- Blocklist robustness (substring → structural). Provenance-tag format (shared with E* storage).
- Promote gnatprove to blocking once the proof base is green (CI `continue-on-error: false`).
