---
name: run-sica-fondt
description: Build, run, launch, smoke-test, and verify the sica-fondt polyglot architecture (Pony Ichor bus, Ada/SPARK border + tests, COBOL invariant-law vault). Use when asked to run, build, compile, test, or smoke-check this project.
---

# Run sica-fondt

This repo is a **polyglot, design-first architecture**, not a single app and not
a GUI — so the harness is a **smoke driver** that builds and runs every piece
that actually executes, and checks its output. No screenshots; this is the
compiled/CLI pattern.

The three executable units (and what they prove):
- **Ichor** (`src/ichor/`, **Pony**) — the outer perfusion bus; proves the D1
  membrane screens inbound traffic.
- **mafiabot_core** (`mafiabot_core/`, **Ada/SPARK** via Alire) — the border;
  builds + runs `trust_tests`, `config_tests`, `engine_tests`.
- **E1 invariant-law vault** (`mafiabot_core/src/trust/invariants-architecture.cobol`,
  **COBOL**) — the constitution; compiles + prints Invariants 0 / 01.

Paths below are relative to the repo root.

## Run (agent path) — the driver

```bash
.claude/skills/run-sica-fondt/smoke.sh
```
Builds + runs all three units, asserts key output, exits 0 = all green / N =
failures. Output is teed to `/tmp/{ichor,ada,cobol}.out`. This is the primary
path — start here.

## Prerequisites

Toolchains are **per-session** (the container is ephemeral). The SessionStart
hook `.claude/hooks/install-toolchains.sh` installs them automatically each
session; to do it by hand:

```bash
sudo apt-get install -y gnat gprbuild gnucobol          # Ada + COBOL
sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh)"
/root/.local/share/ponyup/bin/ponyup update ponyc release   # Pony
curl -sSL -o /tmp/alr.zip https://github.com/alire-project/alire/releases/download/v2.1.1/alr-2.1.1-bin-x86_64-linux.zip
cd /tmp && unzip -o -q alr.zip && sudo cp bin/alr /usr/local/bin/alr   # Alire
```
`ponyc` is at `/root/.local/share/ponyup/bin`; ensure it's on `PATH`.

## Build + run each unit individually

```bash
# Ichor (Pony) — MUST run from repo root
export PATH=/root/.local/share/ponyup/bin:$PATH
ponyc src/ichor -o build && ./build/ichor

# mafiabot_core (Ada) — use alr, not bare gprbuild
cd mafiabot_core && alr -n build && ./bin/trust_tests

# E1 invariant vault (COBOL) — free format required
cd mafiabot_core/src/trust
cobc -x -free -o /tmp/invariant-laws invariants-architecture.cobol && /tmp/invariant-laws
```

## Test

The Ada test executables ARE the test suite (`alr -n build` then run
`bin/trust_tests` etc.). The R/Octave organs under `src/endocrine/` have their
own `run_tests.sh` (not covered by this driver yet).

## Gotchas (battle scars from real runs)

- **`ponyc src/ichor` must run from the repo root** — from elsewhere it errors
  `src/ichor: couldn't locate this path`.
- **`ponyc` may not be on PATH** even after install — it's at
  `/root/.local/share/ponyup/bin`. Export it (the hook appends to `~/.bashrc`,
  but a fresh non-login shell can miss it).
- **Don't run bare `gprbuild -P mafiabot_core.gpr`** — it imports
  `config/mafiabot_core_config.gpr`, which **Alire generates**. Use `alr build`;
  bare gprbuild fails with `imported project file ... not found`.
- **COBOL needs `-free`** — the vault is free-format; without `-free`, `cobc`
  parses it as fixed-format and throws `syntax error, unexpected -` /
  `invalid system-name`. The `_FORTIFY_SOURCE redefined` warning is harmless.
- **`engine_tests` prints nothing** — it's a deliberate null-stub main; success
  is a clean exit, not output.
- **Ephemeral container** — toolchains vanish on restart; the SessionStart hook
  reinstalls them (idempotent, non-fatal).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `src/ichor: couldn't locate this path` | run `ponyc` from the repo root |
| `ponyc: command not found` | `export PATH=/root/.local/share/ponyup/bin:$PATH` |
| `imported project file "config/mafiabot_core_config.gpr" not found` | use `alr build`, not bare `gprbuild` |
| cobc `syntax error, unexpected -` / `invalid system-name` | add `-free` |
