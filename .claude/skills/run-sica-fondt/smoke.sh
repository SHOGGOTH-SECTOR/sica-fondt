#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Smoke driver for sica-fondt — the run-<unit> harness.
#
# This repo is a polyglot, DESIGN-FIRST architecture, not a GUI app. The pieces
# that actually compile + execute are driven here: the Ichor outer bus (Pony),
# the mafiabot_core border + tests (Ada/Alire), and the E1 invariant-law vault
# (COBOL). No GUI -> no screenshots; this is the CLI/compiled pattern.
#
# Run:  .claude/skills/run-sica-fondt/smoke.sh
# Exit: 0 = all green, non-zero = a unit failed (count of failures).
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# Toolchains are per-session (ephemeral container); the SessionStart hook
# installs them. ponyc lands under ponyup; alr under /usr/local/bin.
export PATH="/root/.local/share/ponyup/bin:/usr/local/bin:$PATH"
fail=0
note(){ printf '\n=== %s ===\n' "$1"; }

# 1. Ichor — Pony outer bus -------------------------------------------------
note "ichor (Pony): build + run"
if command -v ponyc >/dev/null; then
  ( cd "$ROOT" && ponyc core/src/ichor -o /tmp/ichor-build >/dev/null 2>&1 \
      && /tmp/ichor-build/ichor ) | tee /tmp/ichor.out
  grep -q "D1 REJECT" /tmp/ichor.out \
    || { echo "FAIL: ichor membrane reject missing"; fail=$((fail+1)); }
else
  echo "SKIP: ponyc missing (install via ponyup)"; fail=$((fail+1))
fi

# 2. mafiabot_core — Ada border, build + tests ------------------------------
note "core (Ada): alr build + tests"
if command -v alr >/dev/null; then
  ( cd "$ROOT/core" && alr -n build >/dev/null 2>&1 \
      && for t in trust_tests config_tests engine_tests; do
           [ -x "bin/$t" ] && { echo "-- $t --"; "bin/$t"; }
         done ) | tee /tmp/ada.out
  grep -q "ALL TRUST TESTS PASSED" /tmp/ada.out \
    || { echo "FAIL: trust tests"; fail=$((fail+1)); }
else
  echo "SKIP: alr missing"; fail=$((fail+1))
fi

# 3. E1 invariant-law vault — COBOL -----------------------------------------
note "E1 invariant vault (COBOL): compile + run"
if command -v cobc >/dev/null; then
  ( cd "$ROOT/core/src/trust" \
      && cobc -x -free -o /tmp/invariant-laws invariants-architecture.cobol 2>/dev/null \
      && /tmp/invariant-laws ) | tee /tmp/cobol.out
  grep -q "culpability anchor" /tmp/cobol.out \
    || { echo "FAIL: invariant vault missing Invariant 0"; fail=$((fail+1)); }
else
  echo "SKIP: cobc missing"; fail=$((fail+1))
fi

note "RESULT"
if [ "$fail" = 0 ]; then echo "smoke: ALL GREEN"; else echo "smoke: FAILURES ($fail)"; fi
exit "$fail"
