# <Feature title>: build index

Spec: docs/work/<feature>/spec.md
Branch: <from spec>
Base: <from spec>
Test command: <full suite command from the code map, minus the frontend suite; every pytest gets -n auto>
Frontend test command: <frontend suite command, or delete this line if there is no frontend>

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | <title> | none | todo |
| T02 | <title> | T01 | todo |

## Rulings

<Decisions made during /build, one line each: date, ticket, ruling, why.>
