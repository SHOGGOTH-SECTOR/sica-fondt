# C3 — Inference cycle orchestration (the 23-step pipeline)

## 1. Component
The forward-only sequencer that runs one turn: input → enrich (Drive-Box + MoRAG across Ada) →
init → the 4+4 passes interleaved with Celtic-Cross draws → final cognition → mini-rag → route →
synthesize → coherence check.

## 2. Status / certainty
Exists in Ada (`organs/ada_medium/ada_medium.{ads,adb}`, 344 L, SPARK) with a protected orchestrator
enforcing legal phase progression — but **defunct-flagged** ("must be deleted/replaced"). **Reuse-vs-rebuild
is the key decision** here. Structure C4.

## 3. Language & location
Open. The *sequencer* could stay Ada/SPARK (it's gate-like, forward-only) OR move to the harness side
with Ada only policing crossings (D1). Decide in build step 1.

## 4. Does / does-not
- **Does:** order the 23 steps; enforce forward-only progression (illegal jumps = error); call each organ
  at its step; carry the coherence/drift check at the end.
- **Does-not:** *be* any organ — it sequences C2/B3/A1/F1/D3/D1, it doesn't implement them.

## 5. Interface contract
- `run_inference_cycle(session_key, input) -> result` (today's `Ada_Medium.Run_Inference_Cycle`).
- Step map (canonical): 1 input · 2 enrich (A1 secretes + F1 injects, **D1 polices**) · 3 init ·
  4-17 wMC/eMC + draw CC (C2/B3) · 10/14/18 llmCog · 19 mini-rag (D3) · 20-21 sendAda + **route (D1)** ·
  22 synthesize · 23 contrast intent vs final cognition (drift).

## 6. Dependencies & stubs
Every organ it calls — *stub:* each returns canned output (the C1 spec already lists a pass-through stub).
Standalone-testable as pure sequencing over stubs.

## 7. Invariants / laws
- **L1 (C4):** **forward-only** phase progression; illegal jumps yield an error state.
- **L2 (C5):** tool **routing is Ada's job** (step 21), not the LLM's.
- **L3 (C4):** step 23 is a **drift detector**, never a reward signal (per C1/L4).

## 8. Build steps
1. **Decide reuse-vs-rebuild** of `ada_medium` (audit its SPARK proofs vs the "defunct" flag) and where
   the sequencer lives. 2. Lock the step map + L1 as tests. 3. Wire real organs as their specs land,
   replacing stubs. 4. Add Energy-gating (skip later C2 passes at low E).

## 9. Tests
Phase-progression test (legal path passes, illegal jump errors); routing-is-Ada test; drift-check fires on mismatch.
(Existing `mafiabot_core/tests/cycle_tests.adb` if Ada path is reused.)

## 10. Open items
- **Reuse-vs-rebuild + home** of the sequencer (the central open call here).
- **Level1** placement in `Hermes → Level1 → Ada` (C1, shared).
