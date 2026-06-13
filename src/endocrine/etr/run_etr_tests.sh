#!/usr/bin/env bash
# Run the ETR (Octave) invariants tests from this directory, so the in-dir
# source('etr.m') resolves. Mirrors src/endocrine/run_tests.sh for the R drivers.
set -uo pipefail

cd "$(dirname "$0")" || exit 2

if ! command -v octave >/dev/null 2>&1; then
  echo "ERROR: octave not found. Install with: sudo apt-get install -y --no-install-recommends octave" >&2
  exit 2
fi

octave --no-gui --quiet test_etr.m
