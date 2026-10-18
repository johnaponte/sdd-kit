#!/usr/bin/env bash
# Runs a command in the project's Python (uv) container.
# Usage: bin/py.sh [--net] <command…>      e.g.: bin/py.sh uv run pytest
#
# - Mounts ONLY app/ (at /work). The container does not see the method, bin/ or the rest of the Mac.
# - No network by default (uv in offline mode). --net turns the network on: to install packages
#   or call APIs. It always asks for approval.
# - With --net, it passes to the container the API keys in PASS_ENV that are set in your
#   environment (without writing them to any file). Without --net, never.
# - No extra privileges: --cap-drop ALL and no-new-privileges.
# - uv cache in app/.uv-cache: what is downloaded once with network works later without it.
# This file is protected: to change the image, unlock.sh, edit it and lock.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Official uv image (python3.12-bookworm-slim: Python 3.12.12, uv 0.9.30), pinned by
# digest. Multi-platform (amd64 + arm64). To get the digest of another version:
#   docker buildx imagetools inspect ghcr.io/astral-sh/uv:<tag> | grep '^Digest'
IMAGE="ghcr.io/astral-sh/uv@sha256:e5b65587bce7de595f299855d7385fe7fca39b8a74baa261ba1b7147afa78e58"

# Keys passed to the container only with --net.
PASS_ENV=(ANTHROPIC_API_KEY VOYAGE_API_KEY OPENAI_API_KEY)

NET_ARGS=(--network=none -e UV_OFFLINE=1)
if [[ "${1:-}" == "--net" ]]; then
  NET_ARGS=(--network=bridge)
  for v in "${PASS_ENV[@]}"; do [[ -n "${!v:-}" ]] && NET_ARGS+=(-e "$v"); done
  shift
fi
[[ $# -gt 0 ]] || { echo "Usage: bin/py.sh [--net] <command…>" >&2; exit 1; }
[[ -d "$ROOT/app" ]] || { echo "$ROOT/app does not exist" >&2; exit 1; }

exec docker run --rm "${NET_ARGS[@]}" \
  --cap-drop ALL --security-opt no-new-privileges \
  -e UV_CACHE_DIR=/work/.uv-cache -e UV_LINK_MODE=copy -e UV_PYTHON_DOWNLOADS=never \
  -v "$ROOT/app":/work -w /work \
  "$IMAGE" "$@"
