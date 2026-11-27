# Build from the spec with parts in the index: build index

Spec: docs/work/direct-parts/spec.md
Branch: feature/direct-parts
Base: origin/main
Test command: `f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | direct-parts (direct) | none | doing |

## Rulings
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "gate --direct 7 ACs" now expects exit 0 and no output (US-1.AC1 drops the 6-AC limit)
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: the --quick over-limit Fix text in "gate --quick 4 ACs" and "gate --quick draft" now names the grilled path (US-1.AC2)

