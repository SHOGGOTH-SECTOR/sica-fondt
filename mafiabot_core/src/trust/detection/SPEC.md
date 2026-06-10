# Immune system — detection model (port SPEC, NO GPL code copied)

Source: `DeTTECT` — **GPL-3.0**, so its code is **not** copied; this is a port
spec. Only MITRE's own open ATT&CK data was copied (to
`knowledge/reference/dettect-mitre-data/`).

## What the immune system gains

DeTTECT scores detection coverage against MITRE ATT&CK. Ported into the membrane
(`src/trust/`), this enriches threat screening beyond the current static
blocklist:

- **Technique-aware screening** — map inbound/outbound patterns to ATT&CK
  technique IDs, not just substring blocklist hits.
- **Coverage/visibility scoring** — a data model of which techniques the
  organism can detect, and confidence per technique.
- **Provenance × technique** — combine the existing `Provenance_Tag` with
  technique classification for richer trust verdicts.

## Implementation notes

- Reimplement the scoring/mapping logic in SPARK-compatible Ada (no heap); the
  ATT&CK technique table becomes a static data package.
- Defensive only. Red-team C2 patterns (`reference/c3-c2-patterns/`) are inputs
  to *detect*, never to execute.
