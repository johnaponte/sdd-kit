#!/usr/bin/env bash
# Promotes an agent proposal (docs/proposals/) to its protected file and locks it again.
# Usage: promote.sh <project> constitution|agents
# Needs an interactive terminal: an agent session cannot confirm the promotion.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$KIT_DIR/lib.sh"

usage() {
  echo "Usage: $0 <project-folder> constitution|agents" >&2
  echo "Example, from the project root:  $0 . constitution" >&2
  exit 1
}
[[ -d "${1:-}" && "${2:-}" =~ ^(constitution|agents)$ ]] || usage

if ! { : </dev/tty; } 2>/dev/null; then
  echo "promote.sh needs an interactive terminal. Run it yourself, not the agent." >&2
  exit 1
fi

P="$(project_dir "${1:-}")"
case "${2:-}" in
  constitution) PAIRS=("docs/proposals/constitution.md:docs/constitution.md") ;;
  agents)       PAIRS=("docs/proposals/AGENTS.md:AGENTS.md" "docs/proposals/CLAUDE.md:CLAUDE.md") ;;
  *) echo "Usage: $0 <project> constitution|agents" >&2; exit 1 ;;
esac

FOUND=()
for pair in "${PAIRS[@]}"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  [[ -f "$P/$src" ]] || continue
  FOUND+=("$pair")
  echo "=== $src → $dst"
  if [[ -f "$P/$dst" ]]; then diff -u "$P/$dst" "$P/$src" || true
  else echo "(new file)"; cat "$P/$src"; fi
  echo
done
[[ ${#FOUND[@]} -eq 0 ]] && { echo "No proposals for '$2' in docs/proposals/." >&2; exit 1; }

read -r -p "Promote these files? [y/N] " ans </dev/tty
[[ "$ans" =~ ^[yY]$ ]] || { echo "Cancelled. Nothing was changed."; exit 0; }

MODE="$(cat "$P/$LOCK_MARKER" 2>/dev/null || echo uchg)"
"$KIT_DIR/unlock.sh" "$P" >/dev/null

for pair in "${FOUND[@]}"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  mkdir -p "$(dirname "$P/$dst")"
  cp "$P/$src" "$P/$dst" && rm "$P/$src"
  echo "Promoted: $dst"
done
if [[ "$2" == agents && ! -f "$P/CLAUDE.md" ]]; then
  echo "@AGENTS.md" > "$P/CLAUDE.md"; echo "Created: CLAUDE.md (@AGENTS.md)"
fi

if [[ "$MODE" == "strict" ]]; then "$KIT_DIR/lock.sh" "$P" --strict; else "$KIT_DIR/lock.sh" "$P"; fi
