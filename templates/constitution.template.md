# Constitution — <Project name>

<One sentence: what it is, who it is for and what it is meant to achieve.>

Non-negotiable principles. Every spec, plan, task and change must comply with them.
Changing this constitution requires explicit approval.

## Principles
<!-- 6-8 at most. Short, verifiable, unambiguous. Starting examples: -->
1. **The spec rules**: nothing is implemented unless it is in the active spec. If a decision is missing, work stops and the question is asked.
2. **Tests are the gate**: the logic is tested with <test framework>. Never move on with failing tests.
3. **Logic apart from I/O and interface**: business logic does not depend on the UI, disk, network or clock; those dependencies are injected.
4. **Simplicity**: <what it means in this project; e.g. "no new dependencies without approval">.
5. **User data**: <how it is protected; backward compatibility, nothing lost, no sensitive data in the repository>.
6. **Language**: code in <language>; interface and documentation in <language>.
7. **Product apart from the method**: everything that runs, is tested or is packaged lives in `<app>/`. Outside `<app>/` there is only method documentation and configuration.

## Repository layout
- Product: `<app>/` — code, tests and build configuration. It must build and test on its own, with nothing from outside.
- Method: `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`, `docs/`, `specs/` and the agents' folders (`.claude/`, `.opencode/`, `.agents/`, `.codex/`). They are never part of the product.
- Exceptions at the root (if any): <`.gitignore`, `.github/`, `README.md`…>
- Protected files (no agent modifies them): this constitution, `AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.mcp.json`, `.claude/`, `.opencode/`, `.agents/`, `.codex/` and `bin/`. Agents propose changes in `docs/proposals/` and a person promotes them.

## Stack and tools
- Kind of application: <CLI, web, API, macOS app, library…>
- Language and version: <…>
- Allowed frameworks and libraries: <…>
- Dependency and environment management: <…>
- Need approval first: <new dependencies, external services…>
- Forbidden: <…>

## Quality
- Tests: <framework>
- Lint / format: <tool or "none">
- Build / packaging: <tool or "none">

## Verification
- Logic: automated tests with <framework>.
- Interface and external behaviour: <how it is checked: UI tests, screenshots, running the CLI, API calls, guided manual check…>
- General definition of "done": <e.g. green tests + a check of the main flow>.
