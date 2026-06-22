# CLAUDE.md

Guidance for Claude Code when working in this repository. Keep this file under
**200 lines**. For team setup and a newcomer walkthrough, see
[`ONBOARDING.md`](ONBOARDING.md); for how the docs fit together and which to
read when, see [`AGENTS.md`](AGENTS.md).

## What this is

sica-fondt is a **design-first, polyglot architecture**: an Ichor perfusion bus
(Pony) feeds an Ada/SPARK border (D1), which fronts the inner brain, with a
COBOL invariant-law vault as the constitution. The design docs are the source of
truth; the code follows them.

## Working agreements

- **You're the dev.** When details are missing or a decision is open, make the
  reasonable call and fill in concrete details — don't leave placeholders or
  stall to ask, unless something is genuinely ambiguous.
- **Verify, then commit.** After generating or editing, confirm it works (build
  / run / `run-sica-fondt` smoke), then commit with a descriptive message.
  Commit and push before ending a session — the container is ephemeral.
- **Design before code.** If something feels ambiguous, the answer is usually
  already written in `docs/`. Sync the design first.

## Build & run

Use the `run-sica-fondt` skill (`.claude/skills/run-sica-fondt/`) — its
`smoke.sh` builds and runs every executable unit and asserts output:

```bash
.claude/skills/run-sica-fondt/smoke.sh   # want: smoke: ALL GREEN
```

Per-unit commands and gotchas live in that skill's `SKILL.md`. Toolchains
(ponyc/Alire/GnuCOBOL) are reinstalled each session by the SessionStart hook
`.claude/hooks/install-toolchains.sh`; if `ponyc` isn't found,
`export PATH=/root/.local/share/ponyup/bin:$PATH`.

## Invariants — do not violate

- **S1:** all external traffic crosses the Ada border (D1) first; never route
  around it.
- **S2:** never reclassify a message's provenance.
- **S3 / vault:** the COBOL invariant-law vault (Invariant 0, the culpability
  anchor; 01, minimize harm) is immutable at runtime — don't edit it casually.

## Docs map

- `README.md`, `SOUL.md` — the project and its intent.
- `docs/` — architecture (`bus-topology.md`, `gen03_state_of_architecture.md`, …).
- `ONBOARDING.md` — new-teammate setup and walkthrough.
- `AGENTS.md` — which document to read for what.
