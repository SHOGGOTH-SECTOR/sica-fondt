# AGENTS.md

How to use the documents in this repo. This is the map: read it first, then go
to the right doc for your task. Keep this file under **200 lines** (aim for
**100**) — it's a signpost, not a manual. The depth lives in the docs it points
to.

## Read in this order

1. **`README.md`** — what sica-fondt is.
2. **`SOUL.md`** — intent and principles; the "why."
3. **`docs/`** — the architecture in detail:
   - `bus-topology.md` — the Ichor bus and organ wiring.
   - `gen03_state_of_architecture.md` — current architectural state.
   - `gen03_body.md`, `gen03_self.md` — body/self model.
   - `plans/` — forward-looking plans.
4. **`CLAUDE.md`** — working agreements, build/run, invariants. Read before
   making changes.
5. **`ONBOARDING.md`** — setup checklist and first-task walkthrough (for people).

## Which doc for which task

| If you want to… | Go to |
|---|---|
| Understand the system at a high level | `README.md`, `SOUL.md` |
| Understand the architecture / organ model | `docs/` (start: `bus-topology.md`) |
| Build, run, or smoke-test | `run-sica-fondt` skill → `smoke.sh` |
| Know the rules before editing | `CLAUDE.md` (working agreements + invariants) |
| Onboard a new teammate | `ONBOARDING.md` |
| Find which doc covers a topic | this file |

## Rules of the road

- **Design before code.** The design docs are the source of truth; code follows.
- **Honor the invariants** (S1/S2/S3 in `CLAUDE.md`) — the Ada border and the
  COBOL vault are not optional.
- **Verify, then commit.** Run the smoke driver; commit + push before leaving
  (the container is ephemeral).
- **Keep the docs honest.** If you change behavior, update the doc that
  describes it — and keep `CLAUDE.md` ≤200 lines and this file ≤200 (≤100 pref).
