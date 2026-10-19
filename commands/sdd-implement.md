---
description: SDD · Implement ONE task, tests first (usage - /sdd-implement 001-name T3)
argument-hint: <NNN-name> <Tn>
---
Implement ONLY task $2 from `specs/$1/tasks.md`, following `specs/$1/plan.md`,
`docs/constitution.md`, `AGENTS.md` and the sdd skill.

You may only edit inside the constitution's product folder (code and tests), plus
`specs/$1/tasks.md` and `MEMORY.md`. If the task requires touching anything else, stop and ask.

Follow the "Code discipline" section of the sdd skill: if anything in the task is ambiguous,
stop and ask; write the minimum code that makes the tests pass; change only the lines the task
needs. Mention anything else you notice, but do not fix it.

1. Write the task's tests first and run them with the test command from `AGENTS.md` to check
   that they fail.
2. Write the code until they pass.
3. Run the full test suite (and the lint, if `AGENTS.md` defines it) and show me the result.
4. If the task has visible effects that the tests do not cover, check them yourself as far as
   you can (read the generated file, look at an image). **Do not ask me to review anything**:
   whatever needs a person is reviewed once, at the end, in `/sdd-validate`.
5. Read your own `git diff`: every changed line must be justified by the task or its FRs.
   Revert your own changes that are not.
6. Mark $2 as done in `tasks.md` and say which FRs it covers.
7. If it is the last task of the spec, update `MEMORY.md`.

If the task or the plan is wrong or impossible, STOP and explain: do not improvise another solution.
If the code is not what the plan expected, it may be a manual change by the user: do not undo
it; STOP and ask (sdd skill, "Changes you did not make").
When finished, STOP. Do not start the next task.
