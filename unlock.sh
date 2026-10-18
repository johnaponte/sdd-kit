#!/usr/bin/env bash
# Unlocks the SDD method's protected files (to edit them by hand or reinstall).
# Usage: unlock.sh <project>
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$KIT_DIR/lib.sh"

P="$(project_dir "${1:-}")"
TARGETS=()
while IFS= read -r t; do TARGETS+=("$t"); done < <(existing_protected "$P")
[[ ${#TARGETS[@]} -eq 0 ]] && { echo "Nothing to unlock."; exit 0; }

if [[ -n "$(find "${TARGETS[@]}" -user root -print -quit 2>/dev/null)" ]]; then
  sudo chflags -R nouchg "${TARGETS[@]}"
  sudo chown -R "$(id -un):$(id -gn)" "${TARGETS[@]}"
else
  chflags -R nouchg "${TARGETS[@]}"
fi

echo "Unlocked. Lock again with: $KIT_DIR/lock.sh $P"
