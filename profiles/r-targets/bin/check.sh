#!/usr/bin/env bash
# Quality check at the end of a task: format (Air), lint (lintr) and tests (testthat).
# No network. Ends with "CHECK: OK" (exit 0) or "CHECK: FAIL" (exit 1).
# Usage: bin/check.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R="$ROOT/bin/r.sh"
fail=0

# The project's code files (those that exist).
FILES=()
for f in R tests _targets.R _dependencies.R; do [[ -e "$ROOT/app/$f" ]] && FILES+=("$f"); done

echo "== Format (Air)"
if [[ ${#FILES[@]} -gt 0 ]] && ! "$R" air format --check "${FILES[@]}"; then
  echo "  Some files are not formatted. Fix it with: bin/r.sh air format ${FILES[*]}"
  fail=1
else
  echo "  OK"
fi

echo "== Lint (lintr, the image's version; exclusions in app/.lintr)"
"$R" Rscript --vanilla -e '
  l <- lintr::lint_dir(".")
  if (length(l)) {
    for (x in l) cat(sprintf("  %s:%d [%s] %s\n", x$filename, x$line_number, x$linter, x$message))
    quit(status = 1)
  }
  cat("  OK\n")' || fail=1

echo "== Tests (testthat)"
if ls "$ROOT"/app/tests/testthat/test-*.R >/dev/null 2>&1; then
  "$R" Rscript tests/testthat.R || fail=1
else
  echo "  (no tests yet)"
fi

if [[ $fail -eq 0 ]]; then echo "CHECK: OK"; else echo "CHECK: FAIL"; exit 1; fi
