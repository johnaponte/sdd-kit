---
description: SDD · Where are we - current phase and next step (for the project or a spec)
argument-hint: [NNN-name]
---
Do NOT modify any file. Use the sdd skill.

Spec given (may be empty): $ARGUMENTS

1. Check whether `docs/constitution.md`, `AGENTS.md` and `MEMORY.md` exist. If any is missing,
   the next step is `/sdd-constitution` or `/sdd-agents`: tell me and stop. If there are pending
   proposals in `docs/proposals/`, remind me to promote them with `promote.sh`.
2. If no spec was given, list the folders in `specs/` with their status and tasks (x of y).
3. If a spec was given, read `specs/$1/` (spec.md, plan.md and tasks.md, whichever exist) and
   `MEMORY.md`, and tell me in a few lines:
   - Which phase of the SDD flow it is in and its status.
   - Tasks done and pending (x of y).
   - The exact next step, with the `/sdd-*` command I should run.
