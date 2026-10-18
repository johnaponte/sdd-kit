#!/usr/bin/env bash
# Sets up app/ for an R/targets project: repana structure, tests with testthat and renv,
# with INLA taken from the image (never from renv). Idempotent: it does not overwrite anything
# that already exists. It needs no network.
# Usage: bin/bootstrap.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app"
R="$ROOT/bin/r.sh"
mkdir -p "$APP/tests/testthat"

create() { # create <file> <content>
  if [[ -e "$1" ]]; then echo "  already exists: ${1#"$ROOT"/}"
  else printf '%s\n' "$2" > "$1"; echo "  created: ${1#"$ROOT"/}"; fi
}
ignore() { # ignore <pattern>  (adds it to app/.gitignore if missing)
  touch "$APP/.gitignore"
  grep -qxF "$1" "$APP/.gitignore" || { echo "$1" >> "$APP/.gitignore"; echo "  .gitignore: $1"; }
}

echo "== Structure (repana::targets_structure)"
# Once renv is active, repana is not in the project library: it only runs the first time.
if [[ -f "$APP/_targets.R" ]]; then echo "  already exists: app/_targets.R"
else "$R" Rscript -e 'repana::targets_structure()'; fi

echo "== Tests (testthat)"
create "$APP/tests/testthat.R" '# Test entry point.
# library(testthat) also makes renv detect it.
library(testthat)
test_dir("tests/testthat", stop_on_failure = TRUE)'
create "$APP/tests/testthat/helper-source.R" '# Loads the functions in R/ the same way the pipeline does.
targets::tar_source(file.path("..", "..", "R"))'

echo "== Quality (Air formats, lintr checks: bin/check.sh)"
# commented_code_linter turned off: the repana template (and common R practice) leaves
# commented-out example options in _targets.R.
create "$APP/.lintr" 'linters: linters_with_defaults(commented_code_linter = NULL)
exclusions: list("renv", "_targets", "dat", "out")
encoding: "UTF-8"'

echo "== INLA (from the image; renv ignores it)"
# renv cannot install INLA (it is not on CRAN and there are no binaries for ARM Linux). Only
# INLA is exposed to renv, through a link in renv/external/ (a container path; always
# recreated and not in git). Its dependencies are declared in _dependencies.R so renv manages them.
# --vanilla: looks for INLA in the image without activating renv (which would hide the site-library).
"$R" sh -c 'p=$(Rscript --vanilla -e "cat(find.package(\"INLA\", quiet = TRUE))"); [ -n "$p" ] || { echo "  the image has no INLA"; exit 0; }
  mkdir -p renv/external && ln -sfn "$p" renv/external/INLA && echo "  link: renv/external/INLA -> $p"'
ignore "renv/external/"
if [[ ! -e "$APP/_dependencies.R" ]]; then
  "$R" Rscript --vanilla -e '
    d <- read.dcf(file.path(find.package("INLA"), "DESCRIPTION"), c("Depends", "Imports"))
    p <- trimws(sub("\\(.*", "", unlist(strsplit(paste(na.omit(d), collapse = ","), ","))))
    p <- setdiff(p[nzchar(p)], c("R", rownames(installed.packages(priority = "base"))))
    writeLines(c("# INLA dependencies. INLA comes from the image and renv ignores it:",
                 "# they are declared here so they get into renv.lock (bin/bootstrap.sh).",
                 sprintf("library(%s)", p)), "_dependencies.R")'
  echo "  created: app/_dependencies.R"
else echo "  already exists: app/_dependencies.R"; fi

echo "== Environment (renv: copies the packages the image already has, without network)"
REPO="https://p3m.dev/cran/__linux__/noble/latest"   # the same one as the image's Rprofile.site
if [[ -f "$APP/renv.lock" ]]; then
  echo "  already exists: app/renv.lock"
  if [[ ! -d "$APP/renv/library" ]]; then
    echo "  the project library is missing (freshly cloned project?). Restore it with network:"
    echo "    bin/r.sh --net Rscript -e 'renv::restore(prompt = FALSE)'"
  fi
else
  "$R" Rscript -e "options(repos = c(CRAN = '$REPO'))
    renv::init(settings = list(ignored.packages = 'INLA', external.libraries = '/work/renv/external'),
               restart = FALSE)"
fi

# The project's .Rprofile: replaces the image's Rprofile.site, which bin/r.sh does not load.
if ! grep -q "inla.call" "$APP/.Rprofile" 2>/dev/null; then
  cat > "$APP/.Rprofile" <<EOF
# The image's CRAN repository (its Rprofile.site is not loaded: see bin/r.sh).
options(repos = c(CRAN = "$REPO"))
source("renv/activate.R")
# INLA comes from the image, not from renv. Its ARM engine is at /opt/inla/bin/inla.
setHook(packageEvent("INLA", "onLoad"), function(...) INLA::inla.setOption(inla.call = "/opt/inla/bin/inla"))
EOF
  echo "  written: app/.Rprofile"
else echo "  already configured: app/.Rprofile"; fi

echo "== Initial formatting (Air) of the generated files"
FILES=(); for f in R tests _targets.R _dependencies.R; do [[ -e "$APP/$f" ]] && FILES+=("$f"); done
"$R" air format "${FILES[@]}" && echo "  OK"

echo "== Pipeline validation"
"$R" Rscript -e 'targets::tar_validate(); cat("tar_validate: OK\n")'
echo "Done. Run the tests with: bin/r.sh Rscript tests/testthat.R (once the first one exists)."
