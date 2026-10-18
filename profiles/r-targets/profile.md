# Profile: R + targets + repana + renv (in Docker)

An example profile for reproducible analysis pipelines in R. `/sdd-constitution` and
`/sdd-agents` use it as a starting point: they propose these values and only ask about what
is left open (marked with `<…>`). Day-to-day work is guided by the `sdd-r` skill, installed
with this profile.

## Proposed values for the constitution

**Stack and tools**
- Kind of application: a reproducible analysis pipeline with `targets`.
- Language: R (the version in the Docker image; currently 4.6.1).
- Environment: R only inside Docker, through `bin/r.sh`: throwaway containers of the
  `jjserver/r_jupyterhub-4_6_1` image, pinned by digest. Long-running containers are never
  used. Project packages with `renv` (`app/renv.lock`).
- INLA: comes from the image (with its ARM engine at `/opt/inla/bin/inla`), never from renv.
  `bin/bootstrap.sh` sets it up: renv ignores it, sees it through `renv/external/` and only
  manages its dependencies (`_dependencies.R`).
- System dependencies (fonts such as Arial, libraries): <which ones the project needs>.
  They must come with the image; if they are missing, the pipeline stops with a clear message.
- Layout: created by `repana::targets_structure()` inside `app/` (through `bin/bootstrap.sh`).
- Tests: `testthat` (`app/tests/testthat.R`).
- Format: Air (in the image). Lint: lintr with its default rules except
  `commented_code_linter` (`app/.lintr`). All of it together with the tests: `bin/check.sh`.
- Network: the container has no network. `--net` only to install packages, with approval.

**Suggested principles** (in addition to the general ones in the template)
- **Functions in `R/`, orchestration in `_targets.R`**: `_targets.R` only declares targets;
  all the logic lives in functions in `R/`, tested with small data.
- **Every result comes from the pipeline**: nothing in `out/` is created or edited by hand.
- **Pinned environment**: image by digest + `renv.lock`. New packages only with approval and
  always with `renv::snapshot()`.
- **Data**: <where the input data comes from; whether there is sensitive data>. `dat/` and
  `out/` are never pushed to the repository.

**Verification**
- Every task: `bin/check.sh` ending in `CHECK: OK` (Air format, no lintr warnings, green tests).
- Logic: tests with testthat.
- Pipeline: `tar_validate()`, `tar_make(names = …)` of the affected targets and a check with
  `tar_read()`. The full `tar_make()` only if it is reasonably fast: <approximate time>.
- Reports (`rmd/`) and plots: structure with tests on the generated HTML (`xml2`); visuals,
  checked by the agent with screenshots (`bin/shot.sh`) and by looking at the PNG files. By
  hand, only what needs human judgement, once and at the end (`/sdd-validate`).

## Layout

```
project/
├── bin/r.sh, bootstrap.sh, check.sh, shot.sh ← protected (method)
├── .claude/skills/sdd-r/, .agents/skills/sdd-r/   ← this profile's skill
└── app/
    ├── _targets.R, config.yml, _template.txt, .gitignore   ← repana
    ├── R/                     ← functions (loaded by tar_source())
    ├── rmd/                   ← reports
    ├── dat/  out/             ← input and output (not in git)
    ├── tests/testthat.R       ← test entry point
    ├── tests/testthat/        ← helper-source.R + test-*.R
    ├── renv.lock, renv/, .Rprofile   ← renv (renv/library and renv/external not in git)
    ├── _dependencies.R        ← INLA dependencies for renv
    ├── .lintr                 ← lintr rules
    └── _targets/              ← targets cache (not in git)
```

## For AGENTS.md

```markdown
## Commands (from the root; R only exists inside Docker)
- Set up the structure (once): `bin/bootstrap.sh`
- Check a task (format + lint + tests): `bin/check.sh` → must end in `CHECK: OK`
- Format: `bin/r.sh air format R tests _targets.R`
- Tests: `bin/r.sh Rscript tests/testthat.R`
- Validate the pipeline: `bin/r.sh Rscript -e 'targets::tar_validate()'`
- Run targets: `bin/r.sh Rscript -e 'targets::tar_make(names = c(<targets>))'`
- Working with R: follow the `sdd-r` skill.
```

## Suggested limits
- ✅ Always: logic in functions in `R/` with tests; `renv::snapshot()` after changing packages.
- ⚠️ Ask first: new packages (`--net`), changes to `config.yml`, `repana::clean_structure()`
  (it deletes `out/`), running the full `tar_make()` if it is slow.
- 🚫 Never: use `docker`, `R` or `Rscript` directly (only `bin/r.sh`), edit `out/` or `dat/`
  by hand, push data to the repository.

## Project bootstrap
1. `/sdd-constitution` → `promote.sh … constitution` → `/sdd-agents` → `promote.sh … agents`.
2. `bin/bootstrap.sh`: creates the repana structure in `app/`, `tests/testthat.R`,
   `helper-source.R`, `.lintr`, the INLA configuration and `renv` (copies the image's
   packages, without network), formats what was generated and validates the pipeline. It ends
   with `bin/check.sh` in OK.
3. First spec: `/sdd-spec 001-…`.

## Environment notes (for you)
- **renv cache**: inside a throwaway container the cache disappears and the library would be
  left with broken links; `bin/r.sh` turns it off (`RENV_CONFIG_CACHE_ENABLED=FALSE`).
- **renv and testthat**: renv only detects testthat because `tests/testthat.R` calls
  `library(testthat)`.
- **Shell aliases or functions for R** that use `docker run -it` do not work for the agent
  (there is no interactive terminal): that is why `bin/r.sh` exists.
- **Long-running versus throwaway containers**: a long-running container is for you to work
  in; what you install by hand there (e.g. a font) is not in the image. The agent always uses
  new containers of the image, so everything the project needs must be in the image.
- **Screenshots**: `bin/shot.sh` uses the Chromium inside the image (on ARM Linux it comes
  from a third-party package repository, since Google does not publish Chrome for ARM Linux).
  It does not need `chromote`.
- **Entrypoint**: the JupyterHub image creates users at start-up, which fails without
  privileges; `bin/r.sh` uses `--entrypoint ""` and runs R directly.
- **INLA and renv**: the image's `Rprofile.site` loads INLA (and about 18 more packages)
  before renv is activated, and renv records INLA with a `URL` source but no URL, so any
  `restore` fails on ARM. Fix: `bin/r.sh` starts R without `Rprofile.site`
  (`R_PROFILE=/dev/null`); `app/.Rprofile` sets the repository and `inla.call` (with a hook
  when INLA is loaded); renv ignores INLA and sees it as an external library
  (`renv/external/INLA`, a link into the image that does not go into git); its dependencies go
  in `_dependencies.R`. Tested with a real INLA fit inside a throwaway container with no
  network.
- **Freshly cloned project**: `bin/bootstrap.sh` recreates the INLA link and, if the library
  is missing, suggests `bin/r.sh --net Rscript -e 'renv::restore(prompt = FALSE)'` (it does not
  try to install INLA).
- **Production**: package `app/` without `dat/`, `out/`, `_targets/` or `renv/library/`; at
  the destination, `renv::restore()` (or the same Docker image).
- **Changing the image**: `unlock.sh`, edit `IMAGE` in `bin/r.sh` (with its digest),
  `lock.sh`, then `bin/r.sh Rscript -e 'renv::snapshot(prompt = FALSE)'`.
