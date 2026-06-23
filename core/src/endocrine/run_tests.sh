#!/usr/bin/env bash
# Run every endocrine / Drive-Box R test from the repository root so that the
# repo-root-relative source() paths inside each test resolve correctly.
set -uo pipefail

# cd to repo root (this script lives at <root>/core/src/endocrine/run_tests.sh)
cd "$(dirname "$0")/../../.." || exit 2

if ! command -v Rscript >/dev/null 2>&1; then
  echo "ERROR: Rscript not found. Install with: sudo apt-get install -y r-base-core" >&2
  exit 2
fi

status=0
shopt -s nullglob
# Collect test files, excluding the harness itself (test_framework.R).
tests=()
for f in core/src/endocrine/test_*.R; do
  [ "$(basename "$f")" = "test_framework.R" ] && continue
  tests+=("$f")
done

if [ ${#tests[@]} -eq 0 ]; then
  echo "No test_*.R files found under core/src/endocrine/." >&2
  exit 2
fi

for t in "${tests[@]}"; do
  echo "== $t =="
  if ! Rscript "$t"; then
    status=1
  fi
  echo
done

if [ $status -eq 0 ]; then
  echo "ALL ENDOCRINE TESTS PASSED"
else
  echo "SOME ENDOCRINE TESTS FAILED"
fi
exit $status
