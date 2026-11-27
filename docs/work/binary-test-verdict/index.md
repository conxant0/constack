# Final review grades each test yes or no, on proof: build index

Spec: docs/work/binary-test-verdict/spec.md
Branch: feature/binary-test-verdict
Base: origin/main
Test command: `f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | binary-test-verdict (direct) | none | done bf66fee2 |
| F01 | guard an empty Note and a late "Mutation:" | none | done 6acbf94e |
| F02 | guard text deleted between f-string placeholders | none | done 83a5a4c0 |
| F03 | guard "Mutation" without its colon | none | todo |

## Rulings
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "missing AC row, weak test" expects the new partly line (US-1.AC1)
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "hyphen range and a waived row" becomes "hyphen range" (AC2 row stays yes) and "waiver without a date does not count" also expects the Mutation Note line (US-1.AC2)
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "waiver without a date does not count" expects the PASS line without waiver wording (US-1.AC3)
- 2026-11-27, final-review (fable): check-mutation reports a patch that changes only a behaviour-driving string (a compared literal, a format spec) as wording; reproduced: probe-cm.sh printed 'changes only wording' exit 1 for both cases; decided: Out of Scope line plus TODOS.md entry, no new AC; why: the smaller change (money no, common no, the spec's Logic only decision blanks every string on purpose)

