#!/bin/bash
# SessionStart hook — install the endocrine toolchains so the project's tests run
# in Claude Code on the web:
#   * R (Rscript)      -> the Drive-Box drivers + tests  (src/endocrine/*.R)
#   * GNU Octave       -> the ETR torus + tests          (src/endocrine/etr/*.m)
#
# Synchronous + idempotent (safe to re-run; installs only what's missing).
# Ada/Alire (mafiabot_core) is intentionally NOT installed here: it is not an apt
# package (the CI uses the setup-alire action) and its CI is scheduled-only. Add
# it if you want web sessions to build/test the Ada side.
set -euo pipefail

# Only do the heavy apt install in the remote (web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

pkgs=()
command -v Rscript >/dev/null 2>&1 || pkgs+=(r-base-core)
command -v octave  >/dev/null 2>&1 || pkgs+=(octave)

if [ "${#pkgs[@]}" -gt 0 ]; then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends "${pkgs[@]}"
fi

# Surface versions in the session log (non-fatal).
command -v Rscript    >/dev/null 2>&1 && Rscript --version 2>&1 | head -1 || true
command -v octave-cli >/dev/null 2>&1 && octave-cli --version 2>&1 | head -1 || true
