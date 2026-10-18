---
name: sdd-r
description: Use it whenever you write, run, test or review R code in this project - functions in app/R/, the pipeline app/_targets.R, tests with testthat, packages with renv or reports in app/rmd/.
---

# R with targets, repana and renv (in Docker)

It complements the `sdd` skill: that one says WHICH phase comes next; this one, HOW R work is
done here.

## Running R
- R only exists inside Docker. Always run with `bin/r.sh <command>` from the project root.
  The container only sees `app/` (at `/work`), with no network.
- Never `Rscript` or `R` directly, nor `docker`, nor interactive sessions.
- `bin/r.sh --net …` gives the container network access: only to install packages, and it
  asks for approval.
- No redirections (`>`) in commands with `bin/`: read the result from the output.

| To | Command |
|---|---|
| **Check a task** (format + lint + tests) | `bin/check.sh` → `CHECK: OK` or `CHECK: FAIL` |
| Format (Air) | `bin/r.sh air format R tests _targets.R` |
| Tests | `bin/r.sh Rscript tests/testthat.R` |
| Validate the pipeline | `bin/r.sh Rscript -e 'targets::tar_validate()'` |
| Run specific targets | `bin/r.sh Rscript -e 'targets::tar_make(names = c(a, b))'` |
| What is outdated | `bin/r.sh Rscript -e 'print(targets::tar_outdated())'` |
| Read a result | `bin/r.sh Rscript -e 'print(targets::tar_read(a))'` |
| Screenshot an HTML report | `bin/shot.sh out/<report>.html` → `app/out/_screenshots/` |

## Where things go (inside `app/`)
- `R/`: functions, one responsibility each. They receive the data as arguments and return a
  result: no hard-coded paths, no reading or writing files inside the logic, no `library()`
  (packages are declared in `tar_option_set(packages = …)`).
- `_targets.R`: only declares targets that call functions in `R/`. No logic here.
- `tests/testthat/test-<topic>.R`: tests for the functions in `R/`. `helper-source.R` already
  loads them.
- `dat/`: input data. `out/`: pipeline outputs. Never edited by hand and never in git.
- `rmd/`: reports. `config.yml`: repana's folders; change it only with approval.

## A typical task
1. Test first in `tests/testthat/`, with small data created in the test itself
   (`data.frame(...)`), never reading `dat/`. Run the tests: they must fail.
2. The function in `R/` until the tests pass.
3. If the task adds or changes a target: edit `_targets.R`, `tar_validate()`, and
   `tar_make(names = …)` only for the affected targets; check the result with `tar_read()`.
4. If the spec requires clear errors (an FR with `IF … THEN`), use `stop()` with a message
   that names the problem and a test with `expect_error(…, "text")`.
5. Format with Air and finish with `bin/check.sh`: the task is only done with `CHECK: OK`.
   lintr warnings are fixed in the code; do not silence them (`# nolint`, changes to
   `.lintr`) without approval.
6. The full `tar_make()` only if the constitution says it is fast, or with approval.

## Style
- Air formats (tidyverse style); lintr checks what Air does not fix: `T`/`F` instead of
  `TRUE`/`FALSE`, unused or undefined variables, names, complexity.
- lintr runs with the image's version (`Rscript --vanilla`), not from renv: do not add it to
  the project. styler is also in the image, but the profile's formatter is Air.

## Packages (renv)
- With renv active, only the packages in `renv.lock` exist.
- New package: ask for approval (the constitution requires it). If it is already in the
  image, without network: `bin/r.sh Rscript -e 'renv::hydrate("pkg"); renv::snapshot(prompt = FALSE)'`.
  If not: `bin/r.sh --net Rscript -e 'renv::install("pkg"); renv::snapshot(prompt = FALSE)'`.
- Never edit `renv.lock` by hand. After changing packages, run the tests.
- To use repana functions inside the pipeline (`get_dirs()`…), first
  `renv::hydrate("repana")` + `snapshot`.

## Visual check (plots and reports)
Check it yourself before asking the user for any review.
- **PNG images** produced by the pipeline (e.g. `app/out/*.png`): open them and look at them
  directly.
- **HTML reports**: `bin/shot.sh out/<report>.html` takes screenshots at 1280 and 375 px
  (desktop and mobile) into `app/out/_screenshots/`; for long pages,
  `bin/shot.sh out/<report>.html 1280x6000`. Then look at the screenshots.
- What to look at: all sections are there; tables complete and aligned (on mobile too);
  plots with readable axes, titles and legend; labels that do not overlap; code folded if the
  spec asks for it; nothing empty and no R errors on the page.
- Structure is better checked with tests on the generated HTML (`xml2`: titles, number of
  tables and images, classes such as `code_folding`); screenshots are for the visuals.
- If you see a problem, fix it (or, in `/sdd-validate`, report it as a failure). Leave to the
  user only what needs judgement (whether the plot communicates well, whether the text is
  clear).

## INLA (comes from the image, never from renv)
- INLA is not on CRAN and there are no binaries for ARM Linux: **never**
  `renv::install("INLA")`, `install.packages("INLA")` or `renv::update()` of INLA. renv
  ignores it (`ignored.packages` in `renv/settings.json`): do not remove that.
- Use it with `INLA::` or in `tar_option_set(packages = …)`, like any package. The engine
  (`inla.call = /opt/inla/bin/inla`) is set by `app/.Rprofile` when INLA loads: do not touch it.
- Its dependencies (`_dependencies.R`: fmesher, Matrix, MatrixModels…) are in renv, copied
  from the image. Do not update them on your own: they must match the image's INLA.
- If `there is no package called 'INLA'` appears: run `bin/bootstrap.sh` (it recreates the
  `renv/external/INLA` link). If it persists, stop and tell the user.
- A test INLA fit must be small (tens of rows). Real fits can take hours: never start one in
  a task without approval.

## Known pitfalls
- `test_dir()` fails when there are no tests: that is normal until the first task.
- `repana::clean_structure()` deletes `out/`: never without approval.
- `_targets/` is a cache: do not delete or edit it; use `tar_invalidate()` if something has
  to be recomputed.
- If a test needs a date or another changing value, pass it to the function as an argument.
