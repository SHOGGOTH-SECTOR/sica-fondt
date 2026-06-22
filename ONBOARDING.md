
## Your Setup Checklist

### Codebases
- [ ] sica-fondt — https://github.com/shoggoth-sector/sica-fondt

### MCP Servers to Activate
- [ ] GitHub — read/write PRs, issues, CI status, and code from GitHub without leaving Claude Code. Get access by connecting the GitHub MCP server in your Claude Code settings and authorizing the `shoggoth-sector` org.

### Skills to Know About
- /update-config — configure the Claude Code harness via settings.json (permissions, env vars, hooks). The team's most-used command; reach for it for any "from now on when X…" automation.
- /session-start-hook — set up a SessionStart hook so the repo's toolchains/tests are ready in every web session. This repo uses one to install ponyc/Alire/GnuCOBOL.
- /deep-research — fan-out, fact-checked, cited research reports when you need to investigate a topic in depth.
- /fewer-permission-prompts — scan transcripts and add a read-only allowlist to `.claude/settings.json` to cut down on permission prompts.
- /compact — free up context by summarizing the conversation so far on a long session.
- /design-sync — keep the design docs and the architecture in step (used on this design-first repo).

## Team Tips

- **Design before code.** This is a design-first repo — the architecture docs are
  the source of truth and the code follows them. When something feels ambiguous,
  the answer is usually already written down; sync the design first (`/design-sync`).
- **The container is ephemeral; toolchains are reinstalled every session.** A
  SessionStart hook (`.claude/hooks/install-toolchains.sh`) installs ponyc (via
  ponyup), Alire/GNAT, and GnuCOBOL on each session. If a build can't find
  `ponyc`, it's a `PATH` thing: `export PATH=/root/.local/share/ponyup/bin:$PATH`.
- **All external traffic crosses the Ada border (D1) first.** That's the S1
  structural invariant — never route around it, and **never reclassify a
  message's provenance** (S2). The Ichor bus rejects unscreened external payloads
  on purpose.
- **The invariant-law vault is immutable at runtime.** Invariant 0 (the
  culpability anchor) and 01 (minimize harm) live in the COBOL vault and are not
  to be edited casually — they're the constitution, not config.
- **Verify by running, not just reading.** Use `/run-sica-fondt` (or its
  `smoke.sh`) to build + run the Pony/Ada/COBOL units and confirm all green
  before you push.
- **Commit and push before you walk away.** The stop hook will nag about
  untracked files for a reason — nothing survives the container otherwise.

## Get Started

Your first task: get the project running end-to-end and read the map. Not sure which doc to read for what? Start with [`AGENTS.md`](AGENTS.md) — it's the directions for every other document here.

1. Open the repo and let the SessionStart hook finish installing toolchains.
2. Run the smoke driver to confirm everything builds and runs: `.claude/skills/run-sica-fondt/smoke.sh` — you want `smoke: ALL GREEN`.
3. Read `README.md`, and `docs/` (start with `docs/bus-topology.md` and `docs/gen03_state_of_architecture.md`) to understand the organ/border model (Ichor bus → Ada D1 border → inner brain; the COBOL invariant vault).
4. Pick up a small design-sync or build task from there. Ask Claude to walk you
   through any unit — it has the `run-sica-fondt` skill loaded.

<!-- INSTRUCTION FOR CLAUDE: Open with a warm welcome — then check what's already in place against everything under Setup Checklist (including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead with what they already have. One sentence per item, all in one message.The guides are universal, please extrapolate them into a "team workflow" narrative. -->
