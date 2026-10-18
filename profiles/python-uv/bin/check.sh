#!/usr/bin/env bash
# Quality check at the end of a task: format (ruff format), lint (ruff check) and tests
# (pytest). No network. Ends with "CHECK: OK" (exit 0) or "CHECK: FAIL" (exit 1).
# Usage: bin/check.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="$ROOT/bin/py.sh"
fail=0

echo "== Format (ruff format)"
if "$PY" uv run ruff format --check .; then echo "  OK"
else echo "  Fix it with: bin/py.sh uv run ruff format ."; fail=1; fi

echo "== Lint (ruff check)"
if "$PY" uv run ruff check .; then :
else echo "  Some warnings can be fixed automatically with: bin/py.sh uv run ruff check --fix ."; fail=1; fi

echo "== Tests (pytest)"
"$PY" uv run pytest -q; rc=$?
case $rc in
  0) ;;
  5) echo "  (no tests yet)" ;;   # pytest exit code 5: no tests were found
  *) fail=1 ;;
esac

if [[ $fail -eq 0 ]]; then echo "CHECK: OK"; else echo "CHECK: FAIL"; exit 1; fi
