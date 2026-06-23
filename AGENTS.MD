# AGENTS.md

**Instructions** for agents (any tool) working in this repo. The **map** — where
everything lives: read-order, doc routing, the organ list, build commands — is
[`docmap.yaml`](docmap.yaml). Claude-specific guidance: [`CLAUDE.md`](CLAUDE.md).

## How these files work
- AGENTS.md files are **instructions, and they nest**: an agent reads the
  *nearest* one walking up from the file it's editing. Each organ has its own
  (listed in `docmap.yaml` → `organs`).
- Keep each file to **instructions for its scope**, non-overlapping. Locations
  belong in `docmap.yaml`, not in prose here — don't duplicate the map.

## Rules
- **Design before code.** The design docs are the source of truth; code follows.
- **Honor the invariants** (S1/S2/S3 — text in `CLAUDE.md`): the Ada border and
  the COBOL vault are not optional.
- **Verify, then commit.** Run the smoke driver; commit + push before leaving
  (the container is ephemeral).
- **Keep the map honest.** Add an organ or move a doc → update `docmap.yaml`.
  Keep `CLAUDE.md` ≤200 lines and this file ≤100.
- Install toolchains as needed.
