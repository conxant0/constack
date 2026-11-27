# Final review grades each test yes or no, on proof: build index

Spec: docs/work/binary-test-verdict/spec.md
Branch: feature/binary-test-verdict
Base: origin/main
Test command: `f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | binary-test-verdict (direct) | none | doing |

## Rulings
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "missing AC row, weak test" expects the new partly line (US-1.AC1)

