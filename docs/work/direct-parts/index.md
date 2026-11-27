# Build from the spec with parts in the index: build index

Spec: docs/work/direct-parts/spec.md
Branch: feature/direct-parts
Base: origin/main
Test command: `f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | direct-parts (direct) | none | todo |

## Rulings

<Decisions made during /build, one line each: date, ticket, ruling, why.>
