---
description: SDD · Review the spec like a QA engineer (find problems, do not solve them)
argument-hint: <NNN-name>
---
Do NOT edit any file. Use the sdd skill.
Review `specs/$1/spec.md` as a demanding QA engineer would, taking `docs/constitution.md` into
account. List:

1. Remaining ambiguities (requirements that cannot be verified).
2. Contradictions between requirements.
3. Edge cases that are not covered.
4. Conflicts with `docs/constitution.md`.

Do not propose solutions yet: only find problems. Format: numbered list.
If you find none, say so and remind me that, if I approve the spec, its status must change to
`approved` (or ask me and you change it), and the next step is `/sdd-plan $1`.
