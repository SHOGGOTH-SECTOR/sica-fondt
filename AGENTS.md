# AGENTS.md

How to use the documents in this repo — the prose signpost. The full
directory/document index lives in [`docmap.yaml`](docmap.yaml) (machine-readable;
start there to find which file covers what, the newcomer read-order, and the
organ list). Working agreements and invariant text: [`CLAUDE.md`](CLAUDE.md).
Keep this file lean (≤100 lines) — depth lives in the docs it points to.

## Scope & nesting

`AGENTS.md` is **hierarchical** — an agent reads the *nearest* one walking up
from the file it's editing. So this root file is the **map**; each organ owns a
scoped `AGENTS.md` with its *local* build/run/invariants (see `docmap.yaml` →
`organs` for the list and paths).

Keep scopes **non-overlapping**: the root signposts, the organs detail. Don't
restate the root in an organ file (that's how the two drift) — link up instead.

## Rules of the road

- **Design before code.** The design docs are the source of truth; code follows.
- **Honor the invariants** (S1/S2/S3 in `CLAUDE.md`) — the Ada border and the
  COBOL vault are not optional.
- **Verify, then commit.** Run the smoke driver (`docmap.yaml` → `smoke`); commit
  + push before leaving (the container is ephemeral).
- **Keep the docs honest.** If you change behavior, update the doc — and the
  `docmap.yaml` entry — that describes it. Keep `CLAUDE.md` ≤200 lines and this
  file ≤100.
