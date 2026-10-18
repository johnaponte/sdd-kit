#!/usr/bin/env bash
# Runs a command in the project's R container.
# Usage: bin/r.sh [--net] <command…>      e.g.: bin/r.sh Rscript tests/testthat.R
#
# - Mounts ONLY app/ (at /work). The container does not see the method, bin/ or the rest of the Mac.
# - No network by default. --net turns it on (only to install packages; it asks for approval).
# - No extra privileges: --cap-drop ALL and no-new-privileges.
# - renv cache turned off: the library in app/renv/library holds real copies, not links to a
#   cache that disappears with the container.
# This file is protected: to change the image, unlock.sh, edit it and lock.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Image pinned by digest (not by tag, which can change), always in a new throwaway container.
# To get the digest: docker image inspect <image>:<tag> --format '{{index .RepoDigests 0}}'
# Tag 3 (2026-10-18): adds lintr, styler, Air and Arial. Multi-platform (amd64 + arm64).
IMAGE="jjserver/r_jupyterhub-4_6_1@sha256:f56be20c125ebb3d503090f79ef8f347d4a542d0837d8725afc4e751e47b26d4"

NETWORK="--network=none"
if [[ "${1:-}" == "--net" ]]; then NETWORK="--network=bridge"; shift; fi
[[ $# -gt 0 ]] || { echo "Usage: bin/r.sh [--net] <command…>" >&2; exit 1; }
[[ -d "$ROOT/app" ]] || { echo "$ROOT/app does not exist" >&2; exit 1; }

# --entrypoint "": the image's entrypoint sets up JupyterHub (creates users) and fails without
# privileges; here we only want to run R.
# R_PROFILE=/dev/null: the image's Rprofile.site loads INLA (and with it about 18 of the
# image's packages) before renv is activated, which causes version conflicts. What it did
# (CRAN repository and inla.call) is done by the project's .Rprofile (see bin/bootstrap.sh).
exec docker run --rm "$NETWORK" --entrypoint "" \
  --cap-drop ALL --security-opt no-new-privileges \
  -e R_PROFILE=/dev/null \
  -e RENV_CONFIG_CACHE_ENABLED=FALSE \
  -v "$ROOT/app":/work -w /work \
  "$IMAGE" "$@"
