# D2 — The medium / "the blood"  *(DESIGN-FIRST)*

## 1. Component
The perfusion bus the organs share — what circulates between Brain and periphery. The architecture is
explicit that organs communicate by **perfusion, not direct wiring**; this is that medium. Currently
**unnamed and unimplemented**.

## 2. Status / certainty
SCAFFOLD · named **Ichor**, Pony scaffold at `src/ichor/` (envelope + broker + D1 barrier + C seam).
**Compiles & runs** on ponyc 0.64.0 (smoke wiring green). Backing/transport now C3.

## 3. Language & location
**Pony** (`src/ichor/`) — actor-model broker; capabilities give data-race-free sends. Transport split:
Pony actors = the broker (hosted on the D1 barrier) + **C/Fortran** for the Ada-side binding
(`ichor_ada_shim.c`). Cross-language organs (R/Octave/Ada/Guile) connect to the broker.

## 4. Does / does-not
- **Does:** carry organ secretions/injections between organs, always *through* Ada (D1) before reaching the Brain.
- **Does-not:** police (D1), enrich (organs), or hold state (storage E*). It is transport, not gate.

## 5. Interface contract (proposed)
- A typed envelope `{ from_organ, to, payload, provenance }` every organ emits/consumes.
- All cross-language organs (R Drive-Box, Octave ETR, Ada border, Guile mini-rag) speak this one shape →
  this is what makes the polyglot body interoperate without bespoke per-pair wiring.

## 6. Dependencies & stubs
Everything rides it; nothing it depends on. *Stub today:* in-process function calls + canned envelopes
(which is exactly how the per-organ specs stub their I/O now — the medium formalizes those stubs).

## 7. Invariants / laws
- **L1 (C5):** perfusion, not direct wiring — no organ holds a hard reference to another's internals.
- **L2 (C5):** everything reaching the Brain crosses **Ada (D1)** first.
- **L3 (C1):** envelope carries provenance (so D1 can enforce its provenance laws).

## 8. Build steps
1. **Name it** + choose transport. 2. Define the envelope. 3. Replace the per-organ in-process stubs with
   real medium calls, one edge of the DAG at a time (start R↔Octave for the Drive-Box, A8/A1).

## 9. Tests
Round-trip an envelope between two stub organs; assert it passes through a D1 `admit` check; provenance preserved.

## 10. Open items
- ~~The name~~ (**Ichor**). ~~Transport choice~~ (**Pony broker + C/Fortran Ada seam**).
- Build `ichor_ada_shim.c` into `libichor_ada` + wire `Barrier.admit` to Ada `Trust_Guard` (needs ponyc).
- Socket layer for out-of-process organs (in-process routing works today). Whether RDE drives idle-perfusion (C1).
