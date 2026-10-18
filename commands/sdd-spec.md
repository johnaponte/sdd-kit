---
description: SDD · Interview the user and write the spec (usage - /sdd-spec 001-name initial idea)
argument-hint: <NNN-name> <initial idea>
---
Do NOT write code at any point. You may only write inside `specs/$1/`.
Read `docs/constitution.md`, `AGENTS.md` and `MEMORY.md`, and use the sdd skill.

Spec folder: `specs/$1/`
Initial idea (the text after the folder name): $ARGUMENTS

1. Ask me ONE question at a time to remove ambiguity (edge cases, error behaviour, what is
   out of scope for this version). 5 questions at most.
2. With my answers, write `specs/$1/spec.md` from `docs/sdd-templates/spec.template.md`, with the
   requirements in EARS and `Status: draft`.
3. Only the WHAT and the WHY: no stack, architecture or file names.
4. When done, tell me the next step is `/sdd-clarify $1`.
