# AGENTS.md — endocrine organs (R / Octave)

Local guide for `src/endocrine`. Repo-wide map and rules: [`../../AGENTS.md`](../../AGENTS.md);
working agreements: [`../../CLAUDE.md`](../../CLAUDE.md).

## What this is

The **endocrine array** — slow-signal organs that modulate the system: the R
**Drive-Box** (`drive_box.R`, `driver_*.R`, `endocrine_array.R`, `priors.R`) and
the Octave **ETR** under `etr/`. See `Plan.md` here and `etr/etr_invariants.md`
for design.

## Build & run

Toolchains (R 4.3.3, Octave 8.4) are installed each session by the SessionStart
hook. Run the organ tests directly:

```bash
src/endocrine/run_tests.sh        # R Drive-Box + drivers
src/endocrine/etr/run_etr_tests.sh   # Octave ETR
```

(Not yet wired into the top-level `run-sica-fondt` smoke driver — run them here.)

## Local notes

- Pure R/Octave; no compile step. Each `test_*.R` / `test_etr.m` pairs with its
  `driver`/source file.
- ETR invariants are documented in `etr/etr_invariants.md` — read before
  changing `etr.m`.
