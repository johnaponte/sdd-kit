---
description: SDD · Split the plan into small, verifiable tasks
argument-hint: <NNN-name>
---
Do NOT write code. You may only write `specs/$1/tasks.md`. Use the sdd skill.

From `specs/$1/spec.md` and `specs/$1/plan.md` (if the plan does not exist, stop and tell me),
write `specs/$1/tasks.md` from `docs/sdd-templates/tasks.template.md`:
- Small tasks (20-30 minutes each at most), in dependency order.
- Each one lists the FRs it covers and a "Done when:" line that **the agent can check on its
  own** (tests, the AGENTS.md check, generated files). Never "reviewed by the user": human
  review happens once, at the end, in `/sdd-validate`.
- Checkboxes.
- Try to keep it to 10 tasks or fewer; if there are more, propose splitting the spec.
- Check that every FR in the spec appears in at least one task.

When done, wait for my approval; the next step is `/sdd-implement $1 T1`.
