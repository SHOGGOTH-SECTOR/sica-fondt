# D2 — Ichor: OUTER perfusion medium (Pony scaffold)

## 1. Component
**Ichor is the outer perfusion bus** of the computational body: the circulatory medium linking **outer** organs (stomach/economy, MoRAG, SAE-related interfaces, microagents, external/world ingress) and the **Ada/SPARK D1 border**. The Brain and inner organs belong to the **inner Ada-routed Jorvik bus**, not to Ichor. Do not connect the Brain directly to the skin.

## 2. Status / certainty
**Named and scaffolded**, not a completed cross-language circulation system. Pony actor Broker, immutable Envelope and Barrier stand-in exist under `core/src/ichor/`; an earlier ponyc 0.64.0 smoke run was reported green. This documentation edit does **not** rerun that test. The Ada bridge still has not replaced the Pony-local stand-in and out-of-process transport is unresolved.

## 3. Language & location
Pony `core/src/ichor/`: `envelope.pony`, `broker.pony`, `barrier.pony`, `main.pony`, `ichor_ada_shim.c`; see `core/docs/bus-topology.md`. The C shim is not proof that real Ada `Trust_Guard` is wired.

## 4. Does / does-not
- **Does:** deliver immutable envelopes between registered outer receivers; preserve source, destination, provenance and payload; send traffic destined for the `AdaBorder` receiver through a gate abstraction.
- **Does not:** host the Brain, DriveBox/ETR inner workings, SOUL, Tarot or Jorvik; replace Ada's security decisions; originate cognitive content; act as durable memory.
- **Observed scaffold behavior:** the current Broker routes some outer-to-outer traffic directly; traffic destined to AdaBorder passes the Pony stand-in `Barrier.admit`. That stand-in is **not** real Ada enforcement. Avoid claiming every outer-to-outer message has already crossed the Ada border.

## 5. Interface contract
Current `Envelope` is an immutable `class val` with fields `source: OrganId`, `dest: OrganId`, `provenance: Provenance`, `payload: String`. `OrganId` enumerates outer endpoints (including `AdaBorder`, `Stomach`, `Microagents`, `SAE`, `MoRAG`, `World`). Provenance is independent from content classification.

**Proposed (not implemented):** Ayurvedic-inspired **humoral computational physiology**. The five elements / Vāta-Pitta-Kapha may become regulatory constructs; persistent local humoral state and discrete secretions have been discussed, but there is **no approved runtime state schema, law or envelope extension**. Do not silently add `humor`, `bile` or concentrations to the implemented envelope.

## 6. Dependencies & stubs
Outer organs and Ada D1. The Pony→Ada production bridge and multi-process connections need design and tests. R/Octave DriveBox physiology interfaces should cross the appropriate inner/outer boundary, not become Pony `OrganId` enumeration members.

## 7. Invariants / laws
- **L1:** perfusion between outer organs, without hard references to each other's internals.
- **L2:** all content entering the Brain crosses the **actual** Ada D1 border first; a stand-in does not count.
- **L3:** the origin and authority of every envelope stay attributable; no reclassification by payload.
- **L4:** Ichor is strictly **OUTER**. Jorvik remains the inner Ada-routed bus.
- **L5:** experimental humoral state must not create an unguarded side-channel into the inner body or silently replace durable storage.

## 8. Build steps
Preserve the outer topology and current envelope; test Pony↔real Ada trust semantics before relying on gate guarantees. Then settle transport for non-Pony outer organs. Separately design humors/biles and their relationship to metabolic state; do not couple this unapproved idea into the DriveBox rewrite.

## 9. Tests
Pony smoke routing, provenance retention, rejection by real Ada `Trust_Guard`, cross-process routing, and no bypass into Jorvik/Brain. Historical smoke tests do not cover the unimplemented seam.

## 10. Open items
Ada FFI integration, socket/process layer, reliable perfusion/idle timing, future humoral representation, concentrations/clearance, physiology↔DriveBox interfaces. The medium is **not unnamed**; its scope is **outer-only**.
