# Faster /build and /final-review, weak tests caught during /build: build index

Spec: docs/work/workflow-speed/spec.md
Branch: feature/workflow-speed
Base: origin/main
Test command: `f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T00 | One shared test-file regex | none | todo |
| T01 | Red-green check fails a Delivers AC with no red or guard commit | T00 | todo |
| T02 | Checks read warn or block from a settings file | T01 | todo |
| T03 | Warnings are appended once to the feature's warning log | T02 | todo |
| T04 | Warning log survives resets and the gate ignores it | T03 | todo |
| T05 | check-review grades every logged warning | T04, T12 | todo |
| T06 | Guard patch applied: OK, still passes, does not apply, missing | T03 | todo |
| T07 | Guard patch: no Mutation, clean restore, test-file patch | T06 | todo |
| T08 | Per-ticket wording check, and no ticket means no new lines | T07 | todo |
| T09 | wf done warns on edits to earlier or Base tests | T05, T06 | todo |
| T10 | wf done: red-commit rewrites, brand-new files, block mode | T09 | todo |
| T11 | review-lanes runs the full and clean suites together | T00 | todo |
| T12 | review-lanes wording lane in its own copy | T11 | todo |
| T13 | Shipped modes: delivers blocks, the other three warn | T08, T10 | todo |

## Rulings
- 2026-11-24, T00 (afk): resumed interrupted doing ticket, reset to todo

