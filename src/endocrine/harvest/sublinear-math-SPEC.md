# Endocrine / REPRAG math — sublinear-time-solver (concept → R)

Source: `sublinear-time-solver` — MIT/Apache (permissive; may be referenced).
Harvest the *math*, discard the "consciousness/emergence" framing.

## Useful algorithms

- **Johnson–Lindenstrauss** dimensionality reduction — shrink embeddings before
  ranking; useful for REPRAG candidate ranking under tight memory.
- **Spectral sparsification** — reduce matrix ops while preserving spectrum;
  candidate for the drive-box numeric updates.
- **Forward-push** (single-source, O(1/ε)) — sparse priority propagation;
  candidate for tool-call / skill priority ranking.

## Placement

- Port the chosen routines into `src/endocrine/` (R, full float fidelity) and/or
  the REPRAG ranking step. Fixed-point variants if/when mirrored into SPARK.
- The neural-net / strange-loop crates are out of scope.
