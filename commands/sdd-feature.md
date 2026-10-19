---
description: SDD · Small change without the full flow (usage - /sdd-feature description)
argument-hint: <change description>
---
Small change: $ARGUMENTS

Use the sdd skill (and the stack skill, if there is one). Read `docs/constitution.md`,
`AGENTS.md` and `MEMORY.md`, and the affected code.

1. **Is it really small?** Only if it fits in one 20-30 minute task, adds no dependencies,
   does not change the data format and does not contradict the constitution. Otherwise stop and
   recommend `/sdd-spec` (something new) instead.
2. **Does it change what a spec says?** Look in `specs/` for a spec that describes the affected
   behaviour. If the change alters it, it is `/sdd-change <spec> …`: stop and say so.
3. **Short plan** (no edits yet): which files you would touch, which test you would write,
   edge cases and questions I need to decide. Wait for my approval.
   Follow the "Code discipline" section of the sdd skill: do not assume, write the minimum
   code, touch only what the change needs.
4. **With my approval**: tests first (and check that they fail), then the code, and the
   `AGENTS.md` check (e.g. `bin/check.sh`) green. You may only edit the product folder and
   `MEMORY.md`.
5. **Record it** in `MEMORY.md`, section "Quick changes": date, what and why (one line).
6. **Summarise** what you changed and any decision I should review (and, if the stack skill
   asks for it, the teaching explanation).
