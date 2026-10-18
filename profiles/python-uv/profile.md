# Profile: Python + uv (in Docker), teaching mode

An example profile for Python projects, designed for someone who is learning the language.
`/sdd-constitution` and `/sdd-agents` use it as a starting point: they propose these values
and only ask about what is left open (marked with `<…>`). Day-to-day work is guided by the
`sdd-python` skill, installed with this profile.

## Proposed values for the constitution

**Stack and tools**
- Kind of application: <what it is: library, CLI, service, pipeline…>.
- Language: Python 3.12 (the one in the image).
- Environment: Python only inside Docker, through `bin/py.sh`: throwaway containers of the
  official uv image, pinned by digest. Dependencies with uv (`app/pyproject.toml` +
  `app/uv.lock`). Never `pip`.
- Layout: package in `app/src/<package>/` (`uv init --package`, through `bin/bootstrap.sh`).
- Tests: pytest. Format and lint: ruff (rules E, W, F, I, B, UP; line length 88).
- Network: the container has no network. `--net` (with approval) to install packages or call
  APIs; only then does it receive the API keys from the environment.
- Allowed dependencies: <the ones you already know you will use>; any other, with approval.

**Suggested principles** (in addition to the general ones in the template)
- **Learning is part of the goal**: clear code before clever code; small steps (one spec per
  concept or step of the system); every task ends with an explanation (teaching mode).
- **Tests without network**: tests never call APIs or download anything; external things are
  faked.
- **Keys outside the code**: always from environment variables; never in the repository.
- **Pinned environment**: image by digest + `uv.lock`. New dependencies only with approval.

**Verification**
- Every task: `bin/check.sh` ending in `CHECK: OK` (ruff format, ruff check and pytest green).
- Anything that uses an API: a manual run with `--net`, reviewed by a person.

## Layout

```
project/
├── bin/py.sh, bootstrap.sh, check.sh          ← protected (method)
├── .claude/skills/sdd-python/, .agents/skills/sdd-python/
└── app/
    ├── pyproject.toml, uv.lock, .python-version
    ├── src/<package>/        ← the code
    ├── tests/                ← pytest tests
    └── .venv/, .uv-cache/    ← environment and cache (not in git)
```

## For AGENTS.md

```markdown
## Commands (from the root; Python only exists inside Docker)
- Set up the project (once, with network): `bin/bootstrap.sh --net`
- Check a task (format + lint + tests): `bin/check.sh` → must end in `CHECK: OK`
- Tests: `bin/py.sh uv run pytest -q`
- New dependency (with approval): `bin/py.sh --net uv add <package>`
- Working with Python and teaching mode: follow the `sdd-python` skill.
```

## Suggested limits
- ✅ Always: test first; `bin/check.sh` in OK; explain every task (teaching mode).
- ⚠️ Ask first: new dependencies (`--net`), any run that calls an API (it costs money and
  uses keys), changes to the ruff or pytest configuration.
- 🚫 Never: `pip`, `python` or `docker` directly (only `bin/py.sh`), keys in the code or in
  repository files, tests that use the network.

## Project bootstrap
1. `/sdd-constitution` → `promote.sh … constitution` → `/sdd-agents` → `promote.sh … agents`.
2. `bin/bootstrap.sh --net`: creates the package in `app/` with uv, installs pytest and ruff,
   configures them and formats what was generated. It ends with `bin/check.sh` in OK.
3. First spec: `/sdd-spec 001-…`, a small one.

## Environment notes (for you)
- **API keys**: `bin/py.sh` passes `ANTHROPIC_API_KEY`, `VOYAGE_API_KEY` and
  `OPENAI_API_KEY` to the container **only with `--net`** and only if they are set in your
  environment. To add another one: `unlock.sh`, edit `PASS_ENV` in `bin/py.sh`, `lock.sh`.
- **Cache**: what is downloaded with `--net` stays in `app/.uv-cache`, so recreating the
  environment later (`uv sync`) works without network.
- **Freshly cloned project**: `bin/bootstrap.sh --net` recreates `.venv` from `uv.lock`.
- **Visual check** (when the project has something to look at: a web page, a report): with a
  browser MCP server that you set up in `.mcp.json` (`unlock.sh`, edit, `lock.sh`). For an app
  with a graphical interface, it is not designed yet.
- **`.venv` is a Linux environment**: do not use it from the Mac.
- **Changing the image or the Python version**: `unlock.sh`, edit `IMAGE` in `bin/py.sh`
  (with its digest), `lock.sh`, then `bin/bootstrap.sh --net` to recreate the environment.
