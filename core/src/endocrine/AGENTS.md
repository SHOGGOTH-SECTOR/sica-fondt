# AGENTS.md — endocrine organs (R / Octave)

Local guide for `src/endocrine`. Repo-wide map and rules: [`../../AGENTS.md`](../../AGENTS.md);
working agreements: [`../../CLAUDE.md`](../../CLAUDE.md). Correction log: [`../../../.claude/devCorrectionLog.md`](../../../.claude/devCorrectionLog.md).

READ THE CORRECTION LOG

## What this is

The **endocrine array** — strong-signal organs that modulate the system: the **Drive-Box** (`drive_box.R`, `driver_*.R`, `endocrine_array.R`, `priors.R`) and it's **ETR** under `etr/`. See `Plan.md` here and `etr/etr_invariants.md` for design principles.

## Build & run

Toolchains (R 4.3.3, Octave 8.4) are installed each session by the SessionStart
hook.

## Local notes

- ETR invariants are documented in `etr/etr_invariants.md` — read before changing `etr.m`.
