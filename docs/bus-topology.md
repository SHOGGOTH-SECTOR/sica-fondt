# Gen.03 — concentric bus topology  *(DRAFT — captured live, correct freely)*

Two rings around a membrane. Outer organs ride Ichor up to Ada; Ada is the
gate; behind it the inner-brain bus carries the inner organs (Hermes among
them). The world is outside; nothing reaches the inner ring without crossing Ada.

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
  ▼  ADA (D1) — the membrane / border (screens, provenance, rate)
┌─────────────────────────────────────────────────────────┐
│ INNER ORGANS          inner-brain bus (Pony OPTIONAL)    │
│   • soul (B2)                                            │
│   • metacog (C2)                                         │
│   • Hermes   (the OpenHermes agent — a peer here)        │
│   • drive-box (A1)                                       │
│   • COBOL ontological structures (E1)                    │
└─────────────────────────────────────────────────────────┘
```

## The chain
```
outer organs ─► Ichor (Pony) ─► Ada (D1) ─► inner-brain bus ─► inner organs
                                                               { soul · metacog
                                                                 · Hermes
                                                                 · drive-box
                                                                 · COBOL ontology }
```

## Layers
1. **External** — the world (user / network). Reaches in only via the outer ring.
2. **Outer organs** — stomach/economy (small model), microagents, SAE, GoDAGRAG.
3. **Ichor (Pony)** — the **outer** bus; carries the outer organs up to Ada.
   (Already scaffolded in `src/ichor/`.)
4. **Ada (D1)** — the membrane between outer and inner. Screens everything
   crossing (blocklist / provenance / rate — `Trust_Boundary`).
5. **Inner-brain bus** — connects the inner organs. **Pony optional** (need not
   be Pony).
6. **Inner organs** — soul, metacog, **Hermes**, drive-box, COBOL ontology.
   Hermes is a peer on this bus, not a separate core.

## Flow of a turn
external input → **stomach digests** it → **GoDAGRAG** builds RAG context →
across **Ichor** → **Ada (D1)** screens (already pre-digested context) → **inner
bus** → inner organs (soul / metacog / Hermes / drive-box / COBOL) → synthesis
flows back out the same rings.

## Corrections baked in (vs earlier wrong models)
- **Hermes is an inner organ on the inner bus** — not external, and not a
  separate innermost core.
- **Ichor is the OUTER bus** (organs → Ada), not the brain bus.
- **The inner bus is transport-flexible** (Pony optional).
- The harness is **not** an Ichor (outer) organ.

## Open / to place
- Is the **inner bus Pony** or another mechanism? (decides 2nd Pony broker vs
  hand-off to something else)
- Each **outer organ's hand-off to Ada** (what crosses, in what shape).
