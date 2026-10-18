# sdd-kit

A stack-independent kit for **Spec-Driven Development (SDD)** with AI coding agents:
**Claude Code**, **OpenCode** and **Codex**.

You decide *what* to build (a spec with testable requirements), approve *how* it will be
built (a plan split into small tasks), and the agent implements one task at a time, tests
first, until an automatic validation passes. Only then are you asked to review, once.

The files that define the project's rules (the constitution, `AGENTS.md` and the agent's own
configuration) are protected: the agent can propose changes, but only you can apply them.

## Features

- **A guided flow** of slash commands: `/sdd-constitution`, `/sdd-agents`, `/sdd-spec`,
  `/sdd-clarify`, `/sdd-plan`, `/sdd-tasks`, `/sdd-implement`, `/sdd-validate`,
  `/sdd-change`, `/sdd-feature` and `/sdd-status` (`$sdd-*` skills in Codex).
- **Requirements in EARS** (`WHEN …, THE SYSTEM SHALL …`), each one traced to the test that
  covers it.
- **Two-phase validation**: everything automatic first, FR by FR; a short human review list
  only when all of it is green.
- **Any stack**: the method itself has no language or framework. Your choices go into the
  constitution, or into a reusable *profile* (starting values, a stack skill, container
  scripts and commands that must only run in the container). Two
  [example profiles](profiles/README.md) are included: Python with uv, and R with targets.
- **Protection in layers**: agent permissions, a `PreToolUse` hook (Claude Code and Codex)
  and macOS immutable flags (`chflags uchg`, optionally owned by root). The agent cannot edit
  the method's files, commit or push, delete with `rm` (it uses `trash`), call `docker`
  directly or add MCP servers.
- **Optional multi-agent mode**: a coordinator that hands the work to a planner, an
  implementer and a reviewer, each with its own permissions.

## Requirements

- macOS (the scripts use BSD tools such as `chflags`), bash 3.2 or later, `jq`
  (or `python3`) and `trash` (built into recent macOS versions).
- At least one of [Claude Code](https://claude.com/claude-code),
  [OpenCode](https://opencode.ai) or [Codex](https://github.com/openai/codex).
- Optional: Docker or Podman for profiles that run code in containers; `pandoc` to build the
  HTML version of the docs.

## Quick start

```bash
git clone https://github.com/johnaponte/sdd-kit.git
sdd-kit/install.sh ~/projects/my-project all        # Claude Code + OpenCode + Codex
# or, with an example profile:
sdd-kit/install.sh ~/projects/my-project all --profile sdd-kit/profiles/python-uv
cd ~/projects/my-project && claude                  # or: opencode, codex
```

Then, inside the agent, run `/sdd-constitution`, promote the proposal from your terminal
with `<kit-path>/promote.sh . constitution`, and follow the flow. `/sdd-status` always tells
you what comes next.

## Documentation

- [Usage guide](docs/USAGE.md): the method, every command, the coordinator, profiles,
  protected files and troubleshooting.
- [Developer guide](docs/DEVELOPMENT.md): how the kit is built, design decisions, the
  protection layers, testing and known limitations.
- [Example profiles](profiles/README.md): Python + uv and R + targets.

To read them as standalone HTML pages with rendered diagrams, run `docs-build/build.sh`
(needs `pandoc`).

## Inspiration

This kit was inspired by the spec-driven workflow taught in the course
**"Curso de Desarrollo con IA – El Nuevo Programador"** by
[BIG School](https://thebigschool.com), available on YouTube
([day 1](https://www.youtube.com/watch?v=GarWqdHzwac&list=PLPu5qT0kkOU0&index=1&t=132s)).
It is an independent project, written from scratch, and is not affiliated with or endorsed
by BIG School. No course materials are included.

## Disclaimer

The protections are a best effort to keep an AI agent within the method. They are not a
security boundary: the hook is heuristic, OpenCode has no hook, and anything you approve
yourself will run. Review what the agent does, keep backups and use version control. See
"Known limitations" in the [developer guide](docs/DEVELOPMENT.md#known-limitations).

## License

[MIT](LICENSE) © 2026 John J. Aponte
