#!/usr/bin/env bash
# Takes a PNG screenshot of an HTML file (e.g. a report) to check how it looks.
# Uses the Chromium in the R image, in a throwaway container with no network that only mounts app/.
# Usage: bin/shot.sh <file-inside-app> [width | widthxheight ...]
#   bin/shot.sh out/report.html               → 1280x2400 and 375x2400 (desktop and mobile)
#   bin/shot.sh out/report.html 1280x6000     → long page
# Screenshots go to app/out/_screenshots/<name>-<width>x<height>.png
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
R="$ROOT/bin/r.sh"
HEIGHT=2400

usage() { echo "Usage: bin/shot.sh <file-inside-app> [width | widthxheight ...]" >&2; exit 1; }
[[ $# -ge 1 ]] || usage
FILE="${1#./}"; shift
[[ "$FILE" == app/* ]] && FILE="${FILE#app/}"
[[ "$FILE" != /* && "$FILE" != *..* ]] || { echo "Use a relative path inside app/, without '..'" >&2; exit 1; }
[[ -f "$ROOT/app/$FILE" ]] || { echo "app/$FILE does not exist" >&2; exit 1; }

SIZES=("$@"); [[ ${#SIZES[@]} -gt 0 ]] || SIZES=(1280 375)
NAME="$(basename "$FILE")"; NAME="${NAME%.*}"
mkdir -p "$ROOT/app/out/_screenshots"

for s in "${SIZES[@]}"; do
  [[ "$s" =~ ^[0-9]+(x[0-9]+)?$ ]] || { echo "Invalid size: $s (use 1280 or 1280x6000)" >&2; exit 1; }
  w="${s%%x*}"; h="$HEIGHT"; [[ "$s" == *x* ]] && h="${s#*x}"
  out="out/_screenshots/$NAME-${w}x${h}.png"
  rm -f "$ROOT/app/$out"   # so that an old screenshot does not hide a failure
  "$R" chromium --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage \
    --hide-scrollbars --no-first-run --virtual-time-budget=5000 \
    --window-size="$w,$h" --screenshot="/work/$out" "file:///work/$FILE" >/dev/null 2>&1 || true
  if [[ -s "$ROOT/app/$out" ]]; then echo "  screenshot: app/$out"
  else echo "  FAILED to screenshot $FILE at ${w}x${h}" >&2; exit 1; fi
done
