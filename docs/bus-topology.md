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
│   • MoRAG = GoDAGRAG                                     │
│       (Graph of Directed Acyclic Graphs of RAGs)         │
└─────────────────────────────────────────────────────────┘
  │
  ▼  ADA (D1) — the membrane / border (screens, provenance, rate)
┌─────────────────────────────────────────────────────────┐
│ INNER ORGANS          inner-brain bus = ADA-routed       │
│   • soul (B2)                                            │
│   • metacog (C2)                                         │
│   • Hermes   (the OpenHermes agent — a peer here)        │
│   • drive-box (A1)                                       │
│   • COBOL ontological structures (E1)                    │
│   • mini-rag   (the brain-side RAG — inner, NOT MoRAG)   │
└─────────────────────────────────────────────────────────┘
```

## Layers
1. **External** — the world (user / network). Reaches in only via the outer ring.
2. **Outer organs** — stomach/economy (small model), microagents, SAE,
   **MoRAG / GoDAGRAG**.
3. **Ichor (Pony)** — the **outer** bus; carries the outer organs up to Ada.
   (Already scaffolded in `src/ichor/`.)
4. **Ada (D1)** — the membrane between outer and inner; also routes the inner
   bus. Screens everything crossing (blocklist / provenance / rate —
   `Trust_Boundary`). Native COBOL (`Interfaces.COBOL`) + C interop.
5. **Inner-brain bus** — **Ada-routed** (decided; not Pony). Native path to the
   COBOL organs.
6. **Inner organs** — soul, metacog, **Hermes**, drive-box, COBOL ontology,
   **mini-rag**. Hermes is a peer here, not a separate core.

## The two RAGs (do not conflate)
- **mini-rag** — INNER, brain-side RAG.
- **MoRAG = GoDAGRAG** — OUTER, the Graph of Directed Acyclic Graphs of RAGs.

## The deck (B1) — it's just integers + a table
- **Shuffle kernel:** 169 × 2 = **338 integers**, shuffled + randomized. Pure
  RNG/permutation → **Fortran** (native to the Ada inner bus; integer arrays are
  its home turf).
- **Lookup table:** the card meaning (names, phases, synestries) is **static data
  keyed by the integer** → **COBOL** indexed records (fits the COBOL ontology,
  native to Ada) — not JSON.
- So the deck is a Fortran shuffler + a COBOL table, both native on the Ada bus.

## Language map (settled / proposed)
| Component | Language | Status |
|---|---|---|
| Ichor (outer bus) | Pony | built |
| Ada (membrane + inner bus router) | Ada/SPARK | decided |
| deck shuffle | Fortran | proposed |
| deck lookup table | COBOL | proposed |
| COBOL ontology (E1) | COBOL | given |
| drive-box (A1) | R | existing |
| MoRAG / GoDAGRAG | Haskell or Crystal | open |
| Hermes | OpenHermes agent (external model) | given |

## Corrections baked in (vs earlier wrong models)
- Hermes is an inner organ on the inner bus — not external, not a separate core.
- Ichor is the OUTER bus (organs → Ada), not the brain bus.
- Inner bus is **Ada-routed**, not Pony.
- **mini-rag (inner) ≠ MoRAG/GoDAGRAG (outer).**
- The deck is integers + a table; no fancy ADT language needed.

## Open / to place
- **MoRAG / GoDAGRAG language** (Haskell vs Crystal vs other).
- Each outer organ's hand-off shape to Ada.
- Where the stomach/economy organ sits exactly and what its small model is.
