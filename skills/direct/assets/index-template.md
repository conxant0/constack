# <Feature title>: build index

Spec: docs/work/<feature>/spec.md
Branch: <from spec>
Base: <from spec>
Test command: <full suite command from the project's CLAUDE.md>

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Part | Title | Blocked by | Status |
|---|---|---|---|
| P1 | <title> | none | todo |
| P2 | <title> | P1 | todo |

## Open questions

<"none", or one line per choice the spec leaves open or contradicts:>
- Q1: <question, citing the spec line> Answer: <the decision agent's DECISION> (fable)

## Parts

<One line per row: its ACs in spec order (at most 13) and the files it owns. A file two parts need goes to one of them, or the later part is blocked by the other.>
- P1: US-1.AC1, US-1.AC2; files: <path>, <test path>
- P2: US-2.AC1; files: <path>, <test path>

## Rulings

<Decisions made during /direct, one line each: date, part, ruling, why.>
