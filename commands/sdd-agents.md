---
description: SDD · Generate AGENTS.md and MEMORY.md from the approved constitution
argument-hint: [extra notes]
---
Use the sdd skill. Read `docs/constitution.md`; if it does not exist (or there is only a proposal
in `docs/proposals/`), stop and tell me to promote it or to run `/sdd-constitution`.
Also read the existing code and configuration.
`AGENTS.md` and `CLAUDE.md` are protected: never edit them. Your output is proposals in
`docs/proposals/`. Do NOT write application code.
Extra notes: $ARGUMENTS

1. Draft `AGENTS.md` from `docs/sdd-templates/AGENTS.template.md` (about 40 lines at most).
   If `docs/sdd-templates/profile.md` exists, take from it the commands, limits and pitfalls
   that apply (adjusted to what the constitution decided):
   - Exact, copy-pasteable commands (setup, run, tests, lint, build) for the constitution's
     tools, runnable from the project root (e.g. `cd app && …`).
   - Build and test configuration lives inside the product folder, not at the root.
   - Commands must work without an interactive terminal: no aliases or functions from the
     user's shell, no `docker run -it`. If Docker is used, mount only the product folder
     (e.g. `-v "$PWD/app":/work -w /work`), never the project root.
   - If the project already exists, check that those commands work by running them (only
     read-only ones or tests; ask me before installing anything). If there is no code yet,
     mark them as `(not verified yet)`.
   - Limits ✅ / ⚠️ / 🚫 consistent with the constitution.
   - Do not copy the constitution: AGENTS.md says HOW, the constitution says WHAT.
2. Draft `MEMORY.md` from `docs/sdd-templates/MEMORY.template.md`, with the initial state and
   the constitution's decisions (with their why). `MEMORY.md` is not protected.
3. `CLAUDE.md` only needs one line, `@AGENTS.md` (so that Claude Code reads AGENTS.md; OpenCode
   and Codex read it natively). The promotion script creates it if missing; propose
   `docs/proposals/CLAUDE.md` only if it needs other content.
4. Show me the files and wait for my approval. Then write `docs/proposals/AGENTS.md`
   (and `docs/proposals/CLAUDE.md`, if needed) and `MEMORY.md`.
5. When done, tell me to promote it from my own terminal with
   `<kit-path>/promote.sh . agents`, and that the next step is `/sdd-spec 001-name idea…`.
