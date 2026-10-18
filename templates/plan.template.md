# Plan — Spec NNN <Name>

Spec: `specs/NNN-name/spec.md` · Constitution: `docs/constitution.md`

## Files / modules
Paths from the root. All code and tests live inside the product folder (`<app>/`).

| File or module | New / changed | Responsibility | FR |
|---|---|---|---|
| `<app>/<path>` | <new> | <what it does> | FR-1 |

## Logic
<Logic functions or components, kept apart from I/O and interface. Which external dependencies
(clock, network, disk…) are injected so they can be tested.>

## Algorithm
<Pseudocode, only if it is not trivial.>

## Interface / entry points
<How the user or the system uses it: screen, command, endpoint…>

## Technical decisions
- <Decision> — why. Discarded alternative: <…> (reason).

## Test strategy
<What is tested automatically and with what, according to the constitution. What is checked
with the constitution's verification method.>

## Human review
<Only what needs a person's judgement and cannot be automated (readability, visual
appearance). Reviewed once, in phase 2 of /sdd-validate. Empty if there is nothing.>

## FR coverage
| FR | Where it is implemented | How it is checked |
|---|---|---|
| FR-1 | <…> | <test / check> |
