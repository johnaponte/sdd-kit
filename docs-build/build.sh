#!/usr/bin/env bash
# Builds README.html, docs/USAGE.html and docs/DEVELOPMENT.html from the kit's Markdown files.
# Usage: docs-build/build.sh
# Needs pandoc. Mermaid is downloaded once (pinned version) and embedded in each HTML file,
# so the generated files work offline. The HTML files are not committed (.gitignore).
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
B="$KIT_DIR/docs-build"
MERMAID_VERSION="11.4.1"
MERMAID_URL="https://cdn.jsdelivr.net/npm/mermaid@$MERMAID_VERSION/dist/mermaid.min.js"
MERMAID_FILE="$B/.cache/mermaid-$MERMAID_VERSION.min.js"

command -v pandoc >/dev/null || { echo "pandoc is missing (brew install pandoc)" >&2; exit 1; }

# Mermaid is downloaded once with curl (some pandoc versions cannot fetch over HTTP) and
# pandoc embeds it from the local file.
if [[ ! -s "$MERMAID_FILE" ]]; then
  mkdir -p "$B/.cache"
  curl -fsSL "$MERMAID_URL" -o "$MERMAID_FILE.tmp" && mv "$MERMAID_FILE.tmp" "$MERMAID_FILE" \
    || { echo "Could not download Mermaid ($MERMAID_URL)" >&2; exit 1; }
fi

build() { # build <document without .md> <title>
  pandoc "$KIT_DIR/$1.md" -f gfm -t html5 --standalone --embed-resources \
    --template "$B/template.html" --lua-filter "$B/mermaid.lua" \
    --toc --toc-depth=2 \
    -V mermaid_url="$MERMAID_FILE" -M pagetitle="$2" \
    -o "$KIT_DIR/$1.html"
  echo "Built: $1.html ($(du -h "$KIT_DIR/$1.html" | cut -f1))"
}

build README "sdd-kit"
build docs/USAGE "sdd-kit: usage"
build docs/DEVELOPMENT "sdd-kit: development"
