---
description: SDD · Validate the spec FR by FR - automated checks first, then (only if all pass) your review
argument-hint: <NNN-name>
---
Do NOT edit or fix anything. Use the sdd skill.

Read `specs/$1/spec.md`, `plan.md`, `tasks.md`, `docs/constitution.md` and `AGENTS.md`.

## Phase 1 — Automated checks (on your own)
1. Run the check defined in `AGENTS.md` (tests, lint, format; e.g. `bin/check.sh`) and the
   pipeline or application verification the constitution describes.
2. Go through the spec requirement by requirement: which test or check covers it and its result.
   If you can check something yourself (read a generated file, look at a PNG image, count the
   sections of an HTML report), do it: do not leave it to the user. If the profile provides a
   visual check (a screenshot script in `bin/` or a browser MCP), use it and look at the result.
3. Check the completion criteria that do not need a person, and that no constitution principle
   is broken (including that no code or tests live outside the product folder).

4. Check the code discipline (sdd skill): in `git diff`, flag every changed line that no task or
   FR justifies (unrelated refactoring, reformatting, renaming) and any code beyond what the spec
   requires (extra features, options, abstractions). Each one is a `FAIL`.

Format: table `FR | Covered by | Result` (`OK`, `FAIL` or `HUMAN REVIEW`).

**If anything fails in phase 1: stop here** with `VERDICT: FAILED` and a numbered list
(file:line, what is broken — FR, task or principle — and what is expected). **Do not ask for any
human review**: there is no point in reviewing something that does not work yet.

## Phase 2 — Human review (only if phase 1 is fully green)
Give me a short, concrete list of what only a person can judge (readability, whether a chart or
a text communicates well, visual appearance): what to open (exact path) and what to look at.
Nothing you were able to check yourself.

End with one of these lines:
- `VERDICT: PASSED` (nothing needs human review), or
- `VERDICT: PASSED PENDING YOUR REVIEW`, and wait for my answer. If I confirm, the spec has
  passed; if I point out a problem, write down what has to change (do not fix it yet).

When the spec has passed, remind me to change its status to `implemented` and to update `MEMORY.md`.
