# Example profiles

A profile adapts the SDD kit to a particular stack and way of working. These two are working
examples; copy one outside the kit and change it to suit you, or write your own in the same
format.

```bash
<kit-path>/install.sh <project> all --profile <kit-path>/profiles/python-uv [--strict]
```

| Profile | Stack |
|---|---|
| [python-uv](python-uv/profile.md) | Python 3.12 + uv + pytest + ruff, in throwaway containers of the official uv image; teaching mode for people learning Python |
| [r-targets](r-targets/profile.md) | R + [targets](https://docs.ropensci.org/targets/) + [repana](https://cran.r-project.org/package=repana) + renv, in throwaway containers of the public `jjserver/r_jupyterhub-4_6_1` image (includes INLA, Air, lintr and Chromium) |

Both need Docker (or a compatible runtime that provides the `docker` command). The code only
runs inside the container, which mounts nothing but `app/` and has no network unless a
script is called with `--net` (which always asks for your approval).

## Profile format

```
<profile>/
├── profile.md     → docs/sdd-templates/profile.md  (values for /sdd-constitution and /sdd-agents)
├── skills/<n>/    → .claude/skills/<n>/ and .agents/skills/<n>/  (day-to-day work)
├── bin/*          → bin/  (protected; bootstrap.sh by convention to set up app/)
└── deny-commands  → commands the agent cannot run on the Mac (only in the container)
```

See "Profiles" in the [developer guide](../docs/DEVELOPMENT.md#profiles) for the conventions.
Like the kit, a profile folder must be inert: no `.claude/`, `CLAUDE.md` or `AGENTS.md`.
