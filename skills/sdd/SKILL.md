---
name: sdd
description: Use it whenever you work with Spec-Driven Development in this project (docs/constitution.md, an SDD-generated AGENTS.md, or any file under specs/) - writing, reviewing or changing the constitution, specs, plans and tasks, or implementing and validating a spec's tasks.
---

# Spec-Driven Development (SDD)

A stack-independent method. The concrete tools (language, tests, lint, verification) are NOT
in this skill: they come from `docs/constitution.md` and `AGENTS.md`.

## Flow
Constitution → AGENTS.md → Spec → Clarification → Plan → Tasks → Implementation →
Validation → Change (back to Spec).

- Never move to the next phase without the user's explicit approval.
- The constitution overrides everything else. If a spec, plan or task contradicts it, stop and say so.
- The spec overrides the code: if something is not in the spec, it is not implemented. If a decision is missing, stop and ask.
- A requirements change goes to the spec first, then to the plan and tasks, and only then to the code.
- Each spec lives in its own folder: `specs/NNN-name/` with `spec.md`, `plan.md` and `tasks.md` (NNN = 001, 002…).
- When a phase ends, update `MEMORY.md` (if it exists).
- Exception: small changes the user asks for with `/sdd-feature` (one task, no new spec).
  Never decide on your own that something is "small" to skip the flow.

## Code discipline
- **Don't assume.** If a requirement, task or detail is ambiguous or missing, stop and ask.
  Never fill the gap with a guess.
- **Minimum code.** Write the simplest code that makes the task's tests pass. No extra
  features, options, abstractions, configuration or error handling that the task and its FRs do
  not require.
- **Touch only what you must.** Change only the lines the task needs: no unrelated refactoring,
  reformatting, renaming or clean-up, even in files you are editing. If you notice something
  else (a bug, dead code, a better design), report it; do not fix it.
- **Success criteria.** Know how the task will be judged before writing code: its tests and its
  "Done when:". If it cannot be verified, stop and ask.

## Changes you did not make
The user also edits the code by hand. If, while reading the code, you find something that does
not match the plan, the tasks or what you did before:
- **Do not undo or "fix" it**: it may be a deliberate change by the user.
- Stop and ask, saying what you expected and what you found (file and lines).
- If the user confirms it is theirs and it changes behaviour, propose `/sdd-change` so that the
  spec, plan and tasks match the code again. If it does not change behaviour, adapt your task
  to the current code.
- If their code does not pass the `AGENTS.md` check, tell them; fix it only if they ask.

## Templates
They live in `docs/sdd-templates/`. Always start from them:
`constitution.template.md`, `AGENTS.template.md`, `MEMORY.template.md`,
`spec.template.md`, `plan.template.md`, `tasks.template.md`.

## Product kept apart from the method
```
project/
├── AGENTS.md, CLAUDE.md, MEMORY.md     ← method
├── docs/ (constitution.md, proposals/, sdd-templates/)
├── specs/NNN-name/                     ← method
├── .claude/ .opencode/ .agents/ .codex/ ← method
└── app/                                ← product (name set in the constitution)
```
- All code, tests and build configuration live inside the product folder (`app/` by default).
  It must build and test on its own.
- Outside it, only `specs/`, `docs/proposals/` and `MEMORY.md` are edited.
- Never put product code at the root, nor method documentation inside `app/`.

## Protected files
Never edit, move or delete (with any tool, including the terminal):
`docs/constitution.md`, `AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.mcp.json`, `.claude/`,
`.opencode/`, `.agents/`, `.codex/` (your own configuration: agents, commands, skills,
permissions and hooks) or `bin/` (the method's scripts, e.g. the one that runs containers).
You may run the scripts in `bin/`; containers only through them, never with `docker` directly.

- To create or change them, write a proposal in `docs/proposals/` (same file name) and ask the
  user to promote it with the kit's `promote.sh` script, from their own terminal.
- If a tool blocks you, do not try to get around it: explain to the user what you wanted to do.
- git is read-only (`status`, `diff`, `log`, `show`…). Never commit, push or change the
  repository (`add`, `reset`, `checkout`, `stash`…), and never use `gh`: commits belong to the
  user, who reviews `git diff` first.
- To delete files or folders use `trash <paths>` (macOS Trash; recoverable, and it works on
  folders without `-r`). Never `rm`, `unlink`, `shred` or `find … -delete`.
- Never run the kit's scripts (`install.sh`, `lock.sh`, `unlock.sh`, `promote.sh`) and never
  change file permissions or flags (`chmod`, `chflags`, `chown`, `sudo`).

## Where things live
- **Constitution** (`docs/constitution.md`): non-negotiable principles and the stack and tool
  decisions. It changes rarely and only with approval.
- **AGENTS.md**: the operating manual derived from the constitution: exact commands, layout,
  conventions and limits. About 40 lines at most.
- **MEMORY.md**: state, decisions with their why, and mistakes to avoid. About 50 lines at most.

## Spec (spec.md)
Only the WHAT and the WHY. No stack, architecture or file names: those belong in the plan.
Status: `draft` → `approved` → `implemented`.

### Requirements in EARS
- FR-x: WHEN <event>, THE SYSTEM SHALL <response>.
- FR-x: IF <unwanted condition>, THEN THE SYSTEM SHALL <response>.
- FR-x: WHILE <state>, THE SYSTEM SHALL <response>.
- FR-x: THE SYSTEM SHALL <permanent behaviour>.

One sentence = one behaviour. Every FR must be verifiable: no "fast", "intuitive" or "nice"
without a measurable criterion. Open questions are marked `[NEEDS CLARIFICATION]`.

## Plan (plan.md)
Files or modules and their responsibility · logic kept apart from I/O and interface (clock,
network, disk and other external dependencies injectable for testing) · pseudocode when the
algorithm is not trivial · interface or entry points · justified decisions with the discarded
alternative · test strategy with the constitution's tools. Say which FR each part covers.
Every FR must be covered.

## Tasks (tasks.md)
```
- [ ] **Tn. <Description>.** FR-x, FR-y
  - Done when: <verifiable check>.
```
20-30 minutes per task at most, in dependency order. If there are more than 10, propose
splitting the spec.

## Implementation
One task at a time: tests first (and check that they fail), then the code, the `AGENTS.md`
test command green, mark the task and stop. Never call a task done with failing tests.

## Validation
FR by FR: which test or check covers it and its result. Verdict: `VERDICT: PASSED`,
`VERDICT: PASSED PENDING YOUR REVIEW` or `VERDICT: FAILED` (with the list of failures).

## Human review: once, at the end, and only of what already works
- Never ask the user to review something that has not passed all the automated checks first:
  if they fail later, the user's time is wasted.
- Whatever you can check yourself (read a generated file, look at an image, count sections or
  tables), check it yourself. Leave to the user only what needs human judgement (readability,
  whether something communicates well, visual appearance), in a short list of what to open and
  what to look at.
- No review is requested during `/sdd-implement`: it is requested in phase 2 of `/sdd-validate`.
- **Visual check**: if the profile provides a way to see the result (a screenshot script in
  `bin/`, or a browser MCP for web projects), use it and look at the images before accepting
  something. Look directly at the images the project generates (PNG…).
