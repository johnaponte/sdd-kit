# AGENTS.md — <Project name>
<One or two sentences: what it is, who it is for and what it is meant to achieve.>

## Stack and layout
- <Key technologies and versions, as decided in docs/constitution.md.>
- Product in `<app>/` (code, tests, build configuration). Method at the root: `docs/`, `specs/`, this file and `MEMORY.md`.
- <What each important folder in `<app>/` contains (only what is not obvious).>

## Commands (from the root)
- Install / set up the environment: `<command>`
- Run: `<command>`
- Tests: `<command>`
- Lint / format: `<command>`
- Build: `<command>`

## Conventions
- <Code style, naming, language of comments and texts.>
- <Patterns to follow and the reference file for each.>

## Domain rules / known pitfalls
- <What is easy to get wrong and cannot be inferred from reading the code.>

## Workflow (SDD)
- Read `docs/constitution.md` and the active spec (`specs/NNN-*/`) before touching code.
- Follow the `sdd` skill. Do not move to the next phase without approval.
- Small changes without a spec: only through `/sdd-feature`, invoked by the user.

## Memory
- At the start, read `MEMORY.md`. When a task ends, update it (about 50 lines at most).
- If something becomes a permanent rule, propose moving it to this file.
- Never store sensitive data (keys, tokens, personal data).

## Limits
- ✅ Always: <…>; code and tests only inside `<app>/`; update `MEMORY.md` when each task ends.
- ⚠️ Ask first: <new dependencies, new files, data format changes…>
- 🚫 Never: <…>; commits, pushes or other changes to the git repository (read-only: status, diff, log); deleting with rm (use trash, which moves files to the Trash); editing protected files (`docs/constitution.md`, `AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.mcp.json`, `.claude/`, `.opencode/`, `.agents/`, `.codex/`, `bin/`) or trying to get around a block. Changes are proposed in `docs/proposals/`.

## Verification
- <How to check that a change works before calling it done, according to the constitution.>
