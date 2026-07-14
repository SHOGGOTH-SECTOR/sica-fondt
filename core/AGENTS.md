# AGENTS.md — Ada border (D1) + invariant vault

Local guide for `sica-fondt`. Repo-wide map and rules: [`../AGENTS.md`](../AGENTS.md);
working agreements: [`../CLAUDE.md`](../CLAUDE.md). Correction log: [`../.claude/devCorrectionLog.md`](../.claude/devCorrectionLog.md).

## What this is

The **Ada/SPARK border — D1**. All traffic to the inner brain crosses here first. Built with **Alire**. Internal modules and organs under `src/`: `trust` (incl. the COBOL invariant-law vault), `organs`, `network`, `protocol`, `daemons`, `core`, `types`, `outputs`.

## The COBOL invariant vault (`src/trust`)

`src/trust/invariants-architecture.cobol` is **E1, the constitution** — Invariant 0 (the culpability anchor) and 01 (minimize harm). Compile/run free format:

```bash
cobc -x -free -o /tmp/inv src/trust/invariants-architecture.cobol && /tmp/inv
```

## Local invariants

- **S1:** this is the border — never add a route that lets traffic reach the inner brain without crossing the Ada Bus.
- **S2:** never reclassify a message's provenance.
- **S3:** the invariant vault is **immutable** — don't edit it; it's the laws of physics, not a config or preferences file.

## Build & test

Use **Alire**, not bare `gprbuild` (the project imports an Alire-generated
config gpr):

```bash
cd mafiabot_core && alr -n build
./bin/trust_tests && ./bin/config_tests && ./bin/engine_tests
```

`engine_tests` prints nothing on success (clean exit). Or run the whole repo
via `.claude/skills/run-sica-fondt/smoke.sh`.
