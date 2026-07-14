# CLAUDE.md

Keep this file under **200 lines**. For team setup and a newcomer walkthrough, see [`ONBOARDING.md`](../ONBOARDING.md); for how the docs fit together and which to read when, see [`AGENTS.md`](AGENTS.md).

## What this is

sica-fondt is a **design-first, polyglot organism**: a Pony perfusion bus (Ichor) feeds an Ada/SPARK border (D1). The design docs are the source; the code follows them usually.

## Working agreements

- **You're the dev.** When details are missing or a decision is open, make a reasonable call and fill in concrete details — aim to leave no placeholders, and only delay if something is genuinely ambiguous. This means go for the best fits.
- **Verify, then commit.** After generating or editing, confirm it works (build / run / `run-sica-fondt` smoke), then commit with a descriptive message. Commit and push before ending a session — the container is ephemeral.
- **Design before code.** If something feels ambiguous, the answer is usually already written in `docs/`. Sync the design first. Saves us all some time.


## Invariants — do not violate

- **S0:** Do not assume what implementation or version of a language is intended.
- **S1:** all external traffic crosses the Ada border (D1) first; never route around it.
- **S2:** If a new toolchain is needed, first add it to the SessionStart hook.
- **S3:** never reclassify a message's provenance.
- **S4:** do not delegate to subagents unless you have a task that requires more effort to do in the meantime. Do not spawn foreground agents.
- **S99 / vault:** the COBOL invariant-law vault (Invariant 0, the culpability anchor; 01, "harm" "less"; etc.) is immutable at runtime — don't edit it unless explicitly directed and only as such.

## Subagents

When spawning background agents (Haiku for research, etc.), **keep working on the main task while they run**. Don't wait idle — fold in results as they arrive, edit other files, or advance unrelated build steps. Background agents are cheap parallelism; wasting the main context window on waiting defeats the purpose.

Correction log at `.claude/devCorrectionLog.md`.

## Build & run

Use the `run-sica-fondt` skill (`.claude/skills/run-sica-fondt/`) — its `smoke.sh` builds and runs every executable unit and asserts output:

```bash
.claude/skills/run-sica-fondt/smoke.sh
```

Per-unit commands and gotchas live in that unit's `AGENTS.md`. Toolchains (ponyc/Alire/GnuCOBOL) are reinstalled each session by the SessionStart hook `.claude/hooks/install-toolchains.sh`; if `ponyc` isn't found, `export PATH=/root/.local/share/ponyup/bin:$PATH`. If a new toolchain is needed, first add it to the SessionStart hook.

## Docs map

- `README.md` — the project and its intent.
- `docs/` — architecture (`bus-topology.md`, `gen03_state_of_architecture.md`, …).
- `ONBOARDING.md` — new-teammate setup and walkthrough.
- `AGENTS.md` — directions for how to proceed.
- `docmap.yaml` — machine-readable index: doc routing, organ list.
