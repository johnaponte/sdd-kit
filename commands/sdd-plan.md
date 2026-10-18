---
description: SDD · Write the technical plan for an approved spec
argument-hint: <NNN-name>
---
Do NOT write code. You may only write `specs/$1/plan.md`.
Read `docs/constitution.md`, `AGENTS.md`, `specs/$1/spec.md` and the affected code. Use the sdd skill.

If the spec is not `approved` or still has `[NEEDS CLARIFICATION]` items, stop and tell me.

Write `specs/$1/plan.md` from `docs/sdd-templates/plan.template.md`: files or modules and what
each one is responsible for, logic kept apart from I/O and interface (with injectable
dependencies), pseudocode when the algorithm is not trivial, interface or entry points,
justified technical decisions (with the alternative you discarded) and a test strategy using
the constitution's tools.

In the test strategy, **automate everything that can be checked** (including generated
outputs: files, tables, report sections, images) and keep a separate "Human review" list with
only what needs a person's judgement. That list is reviewed once, at the end, in `/sdd-validate`.

All code and test files must live inside the product folder defined in the constitution.
Everything must respect the constitution and cover every functional requirement (FR). Mark
which FR each part covers. When done, summarise the plan in 5 lines and wait for my approval;
the next step is `/sdd-tasks $1`.
