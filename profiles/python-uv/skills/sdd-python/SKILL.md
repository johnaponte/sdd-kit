---
name: sdd-python
description: Use it whenever you write, run, test or review Python code in this project - the package in app/src/, tests with pytest, dependencies with uv, format and lint with ruff. Includes teaching mode (explaining the code to someone who is learning Python).
---

# Python with uv (in Docker), in teaching mode

It complements the `sdd` skill: that one says WHICH phase comes next; this one, HOW Python
work is done here. The person running the project **is learning Python**: they must be able
to read and understand the code, and every task ends with an explanation (see "Teaching
mode").

## Running Python
- Python only exists inside Docker. Always run with `bin/py.sh <command>` from the project
  root. The container only sees `app/` (at `/work`), with no network.
- Never `python`, `pip`, `uv` or `docker` directly. Never `pip install`.
- `bin/py.sh --net …` gives the container network access (and the API keys): only to install
  packages or call an API, and it asks for approval.
- No redirections (`>`) in commands with `bin/`: read the result from the output.

| To | Command |
|---|---|
| **Check a task** (format + lint + tests) | `bin/check.sh` → `CHECK: OK` or `CHECK: FAIL` |
| Format | `bin/py.sh uv run ruff format .` |
| Fix what ruff can fix | `bin/py.sh uv run ruff check --fix .` |
| Tests | `bin/py.sh uv run pytest -q` |
| A single test | `bin/py.sh uv run pytest -q tests/test_x.py::test_y` |
| Run a module | `bin/py.sh uv run python -m <package>.<module>` |
| New dependency (asks for approval) | `bin/py.sh --net uv add <package>` |
| Development-only dependency | `bin/py.sh --net uv add --dev <package>` |

## Where things go (inside `app/`)
- `src/<package>/`: the code, in small modules with one responsibility each.
- `tests/test_<module>.py`: pytest tests. Import the package by name
  (`from <package>.<module> import f`), never with paths relative to `src/`.
- `pyproject.toml`: dependencies and configuration (ruff, pytest). `uv.lock`: exact versions;
  never edited by hand, and it goes into git.
- `.venv/` and `.uv-cache/`: environment and cache (Linux, from the container). They do not go
  into git; do not touch them.

## A typical task
1. Test first in `tests/`, with small data written in the test itself. Run it: it must fail.
2. The code in `src/<package>/` until it passes.
3. Finish with `bin/check.sh`: the task is only done with `CHECK: OK`. ruff warnings are fixed
   in the code; do not silence them (`# noqa`, configuration changes) without approval.
4. Explain the task (teaching mode).

## Style
- Clear before clever: descriptive names, short functions, an explicit `for` loop before a
  nested comprehension. If an advanced construct is the best option, use it and explain it.
- Type hints on public functions (`def split_text(text: str, size: int) -> list[str]:`) and a
  one-line docstring saying what it does.
- `pathlib.Path` for paths, f-strings for text, `with` to open files.
- No `print` in the package code except at the entry point; results are returned.
- Comments only where they explain a why that the code does not tell.

## Network, data and keys
- Tests **never** use the network or an API: test data is created in the test and external
  calls are replaced (for example with pytest's `monkeypatch` or a fake function passed as an
  argument).
- Keys are read from the environment (`os.environ["ANTHROPIC_API_KEY"]`), never written in the
  code or in repository files. `.env` is in `.gitignore`.
- Whatever calls an API is run with `bin/py.sh --net …`, with approval.

## Teaching mode
When each task ends, after `CHECK: OK`, add to your answer:
1. **What I did** (2-4 lines, no jargon): what the new code does and how it fits into the
   project.
2. **New Python concepts**: only those that appear for the first time in the project (for
   example `dataclass`, generator, `pathlib`, pytest fixture), one sentence each and the line
   where they are used. Keep the list of concepts already explained in `MEMORY.md` (section
   "Concepts covered") so you do not repeat them.
3. **Try it yourself**: a command to run or a small experiment that helps to understand it.

## Known pitfalls
- uv error "offline" or "failed to resolve": it needs network to download; it is not a bug in
  the code. Ask for approval for `--net`.
- pytest returns exit code 5 when there are no tests: `bin/check.sh` treats it as "no tests
  yet".
- `.venv/` is a Linux environment: it cannot run Python from the Mac.
