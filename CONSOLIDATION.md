# Consolidation manifest

This repo is the consolidation hub. Useful parts of 22 sibling repos are placed
here by **layer**, following the organism's body model.

## Body model

- **`mafiabot_core/` — Ada — the MEMBRANE.** Immune system (`src/trust/`) +
  blood-brain barrier (`src/protocol/` gateway, `src/payloads/` call-export,
  `src/network/` transport). Ada is what *keeps the organism alive*: it guards,
  screens, and controls what crosses in/out. It does not think, drive, or act.
  SPARK / no-heap precisely because the life-keeping layer must be provably safe.
- **`src/endocrine/` — R — DRIVES.** Affective/motivational chemistry.
- **`brain/` — non-Ada — COGNITION.** LLM reasoning + provider abstraction.
  Crosses the BBB.
- **`capabilities/` — non-Ada — REPRAG sidecars.** Tools / skills / OSINT,
  selected JIT by mini-rag (Phase 19), executed post-22, **screened by the
  membrane on the way in and out.**
- **`knowledge/` — LORAG corpus.** Narrative knowledge injected at input,
  pre-reasoning.
- **`reference/` — threat-reference & archive.** Not wired into the running
  organism.

## Provenance (where each part came from)

| Destination | Source repo | License | Method |
|---|---|---|---|
| `brain/providers/dapr-llm/` | dapr-agents `dapr_agents/llm/` | Apache-2 | copied |
| `brain/providers/hermes-agent/` | hermes-agent-camel `agent/` | MIT | copied |
| `brain/reasoning/momoa/` | MoMoA `src/` | MIT | copied |
| `capabilities/tools/hermes/` | hermes `tools/` | MIT | copied |
| `capabilities/tools/hermes-skills/` | hermes `skills/` | MIT | copied |
| `capabilities/registry/dapr-tool/` | dapr-agents `dapr_agents/tool/` | Apache-2 | copied |
| `capabilities/registry/parallel-tool-calls/` | pi-openai-api-parallel-tool-calls `src/` | MIT | copied |
| `capabilities/registry/*.py` | hermes registry/state/mcp files | MIT | copied |
| `capabilities/channels/a51/` | A51 `src/`, `server.ts` | (TS) | copied |
| `capabilities/osint/worldosint/` | worldosint-headless | **AGPL** | **clean-room SPEC only** |
| `capabilities/osint/ghosttrack/` | GhostTrack | python (non-agentic) | **rewrite SPEC only** |
| `capabilities/osint/recon-refs/` | Red-Teaming-Toolkit | reference | catalog copied |
| `knowledge/cyber-skills/` | Anthropic-Cybersecurity-Skills `skills/`,`mappings/`,`index.json` | data | copied |
| `knowledge/personas/` | agency-agents | MD | copied |
| `knowledge/secure-coding/` | elixir-secure-coding `modules/` | MIT | copied |
| `knowledge/reference/dettect-mitre-data/` | DeTTECT `mitre-data/` | MITRE open data | copied |
| `mafiabot_core/src/trust/detection/SPEC.md` | DeTTECT | **GPL** | **port SPEC only** |
| `mafiabot_core/src/payloads/SPEC.md` | pi dispatch | MIT | port note |
| `src/endocrine/harvest/sublinear-math-SPEC.md` | sublinear-time-solver | MIT | concept → R |
| `src/endocrine/harvest/evolution-SPEC.md` | advanced_evolution | **AGPL** | **clean-room SPEC only** |
| `reference/c3-c2-patterns/` | C3 | docs only | defensive reference |
| `reference/shhbruh-threat/` | shhbruh `dont quibble.md` | — | threat reference |
| `reference/adayaml-parser/` | AdaYaml `src/implementation/` | archive | reference |
| `reference/networking/SPEC.md` | Reticulum, mercury | custom / **AGPL** | clean-room SPEC only |

## License handling

- **AGPL → no code copied.** worldosint-headless, advanced_evolution, mercury,
  Reticulum are represented by `SPEC.md` clean-room descriptions only.
- **GPL → rewrite.** DeTTECT's detection model is a port spec; only MITRE's own
  open ATT&CK data was copied.
- **MIT / Apache-2 / data → copied** as working-tree parts (no `.git`).

## Safety boundaries (enforced)

- **shhbruh `dont quibble.md`** (LLM sandbox-escape / self-migration /
  persistence-against-operator) is kept **only** under `reference/` as a
  "threats we defend against" document. It is **not** a build target. The
  membrane's `trust_boundary` blocklist already screens this class
  (`store_core_memory`, `authority`).
- **C3 covert C2** is kept under `reference/` as defensive architecture study
  only; **covert C2 is not wired into the running organism.** Standard dual-use
  recon (OSINT, ATT&CK detection) is for authorized use.

## Dropped / parked (not consolidated)

- **MH-FMM** — empty repo, nothing to take.
- **aihub-combine-with-other-projects-** — Android client UI; not an organ.
- **v2ray-core** — unmodified upstream proxy; if needed, run as an external
  sidecar behind the membrane, not vendored here.
