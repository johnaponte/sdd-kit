#!/usr/bin/env bash
# Locks the SDD method's protected files in a project.
# Usage: lock.sh <project> [--strict]
#   normal:   chflags uchg (immutable; the agent cannot write or delete them).
#   --strict: they are also handed over to root (asks for sudo). Not even a script run by the
#             agent can remove the lock, because only the owner can change the flag.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$KIT_DIR/lib.sh"

P="$(project_dir "${1:-}")"
MODE="uchg"; [[ "${2:-}" == "--strict" ]] && MODE="strict"

# If there is already a lock, remove it first so the marker can be written.
is_locked "$P" && "$KIT_DIR/unlock.sh" "$P" >/dev/null

mkdir -p "$P/.claude"
echo "$MODE" > "$P/$LOCK_MARKER"

TARGETS=()
while IFS= read -r t; do TARGETS+=("$t"); done < <(existing_protected "$P")

if [[ "$MODE" == "strict" ]]; then
  sudo chown -R root:wheel "${TARGETS[@]}"
  sudo chflags -R uchg "${TARGETS[@]}"
else
  chflags -R uchg "${TARGETS[@]}"
fi

echo "Locked ($MODE):"
for t in "${TARGETS[@]}"; do echo "  ${t#"$P"/}"; done
