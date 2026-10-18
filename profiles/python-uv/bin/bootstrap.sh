#!/usr/bin/env bash
# Sets up app/ as a Python project with uv: package in src/, tests with pytest, and ruff.
# Idempotent: it does not overwrite anything that already exists.
# The first time it downloads pytest and ruff, so it needs network: bin/bootstrap.sh --net
# Usage: bin/bootstrap.sh [--net] [package-name]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app"
PY="$ROOT/bin/py.sh"
NET=""; if [[ "${1:-}" == "--net" ]]; then NET="--net"; shift; fi
NAME="${1:-}"
mkdir -p "$APP/tests"

ignore() { # ignore <pattern>  (adds it to app/.gitignore if missing)
  touch "$APP/.gitignore"
  grep -qxF "$1" "$APP/.gitignore" || { echo "$1" >> "$APP/.gitignore"; echo "  .gitignore: $1"; }
}
need_net() {
  [[ -n "$NET" ]] && return 0
  echo "  This step downloads packages and needs network. Run: bin/bootstrap.sh --net" >&2
  exit 1
}

echo "== Project (uv init --package)"
if [[ -f "$APP/pyproject.toml" ]]; then
  echo "  already exists: app/pyproject.toml"
else
  if [[ -z "$NAME" ]]; then  # a valid Python name derived from the folder name
    NAME="$(basename "$ROOT" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g; s/^([0-9])/p_\1/')"
  fi
  "$PY" uv init --package --name "$NAME" --vcs none
fi

echo "== Files that stay out of git"
for p in .venv/ .uv-cache/ __pycache__/ .pytest_cache/ .ruff_cache/ .env; do ignore "$p"; done

echo "== ruff and pytest configuration (app/pyproject.toml)"
if grep -q '^\[tool\.ruff\]' "$APP/pyproject.toml"; then
  echo "  already configured"
else
  cat >> "$APP/pyproject.toml" <<'EOF'

[tool.ruff]
line-length = 88
extend-exclude = [".uv-cache"]

[tool.ruff.lint]
# E/W: PEP 8 style · F: errors (pyflakes) · I: import order
# B: common bugs (bugbear) · UP: modern Python syntax
select = ["E", "W", "F", "I", "B", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
  echo "  added"
fi

echo "== Development tools (pytest, ruff)"
if grep -q '"pytest' "$APP/pyproject.toml" && grep -q '"ruff' "$APP/pyproject.toml"; then
  echo "  already in pyproject.toml"
  if [[ ! -d "$APP/.venv" ]]; then  # e.g. a freshly cloned project
    if [[ -n "$NET" ]]; then "$PY" --net uv sync
    else "$PY" uv sync || { echo "  They are not in the cache. Run: bin/bootstrap.sh --net" >&2; exit 1; }; fi
  fi
else
  need_net
  "$PY" --net uv add --dev pytest ruff
fi

echo "== Initial formatting (ruff)"
"$PY" uv run ruff format . && "$PY" uv run ruff check --fix --quiet . && echo "  OK"

echo "Done. Check with: bin/check.sh"
