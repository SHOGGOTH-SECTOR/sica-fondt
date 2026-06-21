# Gen.03 — concentric bus topology  *(DRAFT — captured live, correct freely)*

Two rings around a membrane. Outer organs ride Ichor up to Ada; Ada is the
gate and routes the inner bus; behind it the inner organs (Hermes among them).
The world is outside; nothing reaches the inner ring without crossing Ada.

```
External (world: user / network)
  │
  ▼  outer bus — ICHOR (Pony)
┌─────────────────────────────────────────────────────────┐
│ OUTER ORGANS                                             │
│   • stomach / economy organ  (small-model operated;      │
│       digests external input → context)                  │
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
│   • mini-rag  (MUSCLE MEMORY — tool-shape recall, D3)    │
│   • COBOL ontological structures (E1)                    │
└─────────────────────────────────────────────────────────┘
```

## Three different "memories" — do NOT conflate
- **MoRAG = GoDAGRAG** — OUTER. Reads the **world** (the graph of DAGs of RAGs).
- **mini-rag** — INNER. **Muscle memory.** Pre-motor: before an action reaches
  the actual hands (the real tools / effectors), mini-rag recalls the **right
  shape** for it — the tool schema (D3). HD associative recall of the learned
  form, like a hand pre-shaping its grip. It is **tool lookup**, not
  world-retrieval and not self-knowledge.
- **E1 ontology** — INNER. What the brain **is** (the invariant COBOL structures).

## The deck (B1) — integers + a table
- **Shuffle kernel:** 169 × 2 = **338 integers**, shuffled + randomized → pure
  RNG/permutation → **Fortran** (native to the Ada inner bus).
- **Lookup table:** card meaning keyed by integer → **COBOL** indexed records.

## Language map
Two **distinct Fortran scripts** and (at least) two **distinct COBOL stores** —
not shared modules.

| Component | Language | Status |
|---|---|---|
| Ichor (outer bus) | Pony | built |
| Ada (membrane + inner-bus router) | Ada/SPARK | decided |
| deck shuffle — *Fortran script #1* | Fortran | decided |
| mini-rag (muscle memory / tool-shape recall) — *Fortran script #2* | Fortran | decided |
| deck lookup table — *COBOL store #1* | COBOL | decided |
| tool-schema store (mini-rag reads this) — *COBOL store #2* | COBOL | decided |
| COBOL ontology / E1 (invariant structures, separate) | COBOL | given |
| drive-box (A1) | R | existing |
| MoRAG / GoDAGRAG (outer) | Haskell or Crystal | open |
| Hermes | OpenHermes agent (external model) | given |

## Corrections baked in (vs earlier wrong models)
- Hermes is an inner organ on the inner bus — not external, not a separate core.
- Ichor is the OUTER bus (organs → Ada), not the brain bus.
- Inner bus is **Ada-routed**, not Pony.
- **mini-rag = muscle memory / tool-shape recall (D3)** — it reads the
  **tool-schema** COBOL store, NOT the ontology, and is NOT the MoRAG.
- MoRAG/GoDAGRAG (outer) ≠ mini-rag (inner).
- The deck is integers + a table; no fancy ADT language needed.

## Open / to place
- **COBOL store inventory:** confirmed two stores (deck table + tool-schema). Is
  the **E1 ontology** a third COBOL store, or a different kind of COBOL structure
  (vault) that isn't a "store"?
- **MoRAG / GoDAGRAG language** (Haskell vs Crystal vs other).
- Each outer organ's hand-off shape to Ada.
- The stomach/economy organ's exact placement + which small model runs it.
