# Gen.03 — concentric bus topology  *(DRAFT — captured live, correct freely)*

The body is an **onion**: Hermes at the core, organs in rings around it, Ada as
the membrane between inner and outer, the world on the outside. Nothing reaches
the core without crossing inward through the rings.

```
External (world: user / network)
  │
  ▼  outer bus — ICHOR (Pony)
┌─────────────────────────────────────────────────────────┐
│ OUTER ORGANS                                             │
│   • stomach / economy organ  (small-model operated;      │
│       digests external input → RAG context)              │
│   • microagents                                          │
│   • SAE  (sparse autoencoder)                            │
│   • GoDAGRAG  (Graph of Directed Acyclic Graphs of RAGs) │
└─────────────────────────────────────────────────────────┘
  │
  ▼  ADA (D1) — the border / membrane (screens, provenance, rate)
┌─────────────────────────────────────────────────────────┐
│ INNER ORGANS         inner-brain bus (Pony OPTIONAL)     │
│   • soul (B2)                                            │
│   • metacog (C2)                                         │
│   • drive-box (A1)                                       │
│   • COBOL ontological structures (E1)                    │
└─────────────────────────────────────────────────────────┘
  │
  ▼
HERMES  ← innermost core (the OpenHermes agent)
```

## Layers (innermost → outermost)
1. **Hermes** — innermost core. The OpenHermes agent. **Not external.**
2. **Inner-brain bus** — connects the inner organs around Hermes. **May be Pony,
   but need not be.** Carries: soul, metacog, drive-box, COBOL ontology.
3. **Ada (D1)** — the membrane between inner and outer. Screens everything
   crossing in/out (blocklist / provenance / rate — `Trust_Boundary`).
4. **Ichor (Pony)** — the **outer** bus. Connects the outer organs and wires up
   to Ada. (This is the bus already scaffolded in `src/ichor/`.)
5. **Outer organs** — stomach/economy (small model), microagents, SAE, GoDAGRAG.
6. **External** — the world. Reaches in only via the outer ring → Ada.

## Flow of a turn
external input → **stomach digests** it → **GoDAGRAG** builds RAG context →
across **Ichor** → **Ada (D1)** screens (input is already pre-digested context) →
**inner bus** → inner organs (soul/metacog/drive-box/COBOL) → **Hermes** →
synthesis flows back out the same rings.

## Corrections this doc bakes in (vs earlier wrong models)
- **Hermes is the core, not an external harness on Ichor.**
- **Ichor is the OUTER bus** (organs → Ada), not the brain bus.
- **The inner bus is transport-flexible** (Pony optional).
- The cerebellum/harness is **not** an Ichor organ.

## Open / to place
- Exact tier + role of each outer organ's hand-off to Ada.
- Whether the inner bus is Pony or another mechanism (decides 2nd-broker vs not).
- How Hermes-at-core is reached from the inner bus (in-process vs IPC).
