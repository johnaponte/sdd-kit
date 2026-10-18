---
description: SDD · New or changed requirement - the spec first, then the code
argument-hint: <NNN-name> <change>
---
Do NOT touch code. You may only edit `specs/$1/spec.md`. Use the sdd skill.

Change for the spec `specs/$1/` (the text after the folder name): $ARGUMENTS

1. Check that the change does not contradict `docs/constitution.md`. If it does, stop: explain
   the conflict and, if I ask you to, write an amendment proposal in
   `docs/proposals/constitution.md` (the constitution is protected; I promote it).
2. Update `specs/$1/spec.md`: a new FR (or a changed one) in EARS, its edge cases and what is
   out of scope. Set it back to `Status: draft`.
3. Say which parts of `plan.md` and `tasks.md` will have to change afterwards.
4. Show me the spec diff and wait for my approval. Then: `/sdd-clarify $1`, `/sdd-plan $1`
   and `/sdd-tasks $1`.
