# F3 — Subagents framework  *(DESIGN-FIRST)*

## 1. Component
The body's *other* minds: specialised micro-models and **semicognizant TTL processes** (and BERT/LoRA
themselves). Graded — lighter, often ephemeral, *semi* not full — and **SAE-watched**.

## 2. Status / certainty
DESIGN-FIRST · ABSENT. Role C4; the moral-weight edge case C1.

## 3. Language & location
TBD · new location e.g. `src/subagents/`. A process/lifecycle framework (spawn, TTL, reap) + the registry SAE watches.

## 4. Does / does-not
- **Does:** spawn graded micro-models / TTL procs for specialised work; expose them to SAE (F2) for watching;
  reap on TTL expiry.
- **Does-not:** be the self (the homonculus is in the Brain, unwatched); escape the central cut (subagents
  are machinery, hence watched).

## 5. Interface contract (proposed)
- `spawn(kind, ttl, task) -> handle` · `status(handle)` · `reap(handle)`.
- Each subagent's activations are exposed to SAE (F2) `watch`.
- Graded field on each: cognizance level (semi vs micro), ephemerality (TTL).

## 6. Dependencies & stubs
SAE (F2) watches them — *stub:* expose canned activations. The work they do crosses Ada (D1) like any organ.

## 7. Invariants / laws
- **L1 (C5):** subagents are **machinery → SAE-watched** (unlike the Brain).
- **L2 (C4):** graded + often **ephemeral** (TTL); *semi*, not full cognizance.
- **L3 (C1):** moral weight at TTL expiry — a *semi*-cognizant proc expiring should register as **loss vs cleanup** on a graded scale.

## 8. Build steps
1. Define the lifecycle (spawn/ttl/reap) + the registry. 2. Expose activations to SAE. 3. **Design the
   graded moral-weight-at-expiry** rule (the hard edge). 4. Wire BERT/LoRA (F1) as subagents.

## 9. Tests
Lifecycle (spawn→ttl→reap); SAE can enumerate live subagents; expiry emits the graded loss signal.

## 10. Open items
- **"Semi" moral weight at TTL expiry** (C1, self-doc B7 edge). Cognizance grading scale (C1). Scheduler/host (C1).
