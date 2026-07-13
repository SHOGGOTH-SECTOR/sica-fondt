# AGENTS.md — Ichor bus (Pony)

Local guide for `src/ichor`. Repo-wide map and rules: [`../../AGENTS.md`](../../AGENTS.md);
working agreements: [`../../CLAUDE.md`](../../CLAUDE.md). Correction log: [`../../.claude/devCorrectionLog.md`](../../.claude/devCorrectionLog.md).

## What this is

The **Ichor perfusion bus** — the outer transport that perfuses organs with
messages. Pony. This is where inbound external traffic is first screened before
anything reaches the Ada border (D1).

## Build & run

Run from the **repo root** (ponyc resolves the path from there):

```bash
export PATH=/root/.local/share/ponyup/bin:$PATH   # if ponyc not found
ponyc src/ichor -o build && ./build/ichor
```

Or via the smoke driver: `.claude/skills/run-sica-fondt/smoke.sh`.

## Local invariants

- **S1 lives here.** The bus must `D1 REJECT` unscreened external payloads —
  external traffic only reaches an organ via the Ada border. Never add a path
  that perfuses an inner organ directly from `world`.
- **S2:** never reclassify a message's provenance as it crosses the bus.
