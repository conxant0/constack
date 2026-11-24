# Faster /build and /final-review, weak tests caught during /build: build index

Spec: docs/work/workflow-speed/spec.md
Branch: feature/workflow-speed
Base: origin/main
Test command: `f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T00 | One shared test-file regex, and an empty earlier-tests hook in wf done | none | done bf1229bc |
| T01 | Red-green check fails a Delivers AC with no red or guard commit | T00 | doing |
| T02 | Checks read warn or block from a settings file | T01 | todo |
| T03 | Warnings are appended once to the feature's warning log | T02 | todo |
| T04 | Warning log survives resets and the gate ignores it | T03 | todo |
| T05 | check-review grades every logged warning | T04, T12 | todo |
| T06 | Guard patch applied: OK, still passes, does not apply, missing | T03 | todo |
| T07 | Guard patch: no Mutation, clean restore, test-file patch | T06 | todo |
| T08 | Per-ticket wording check, and no ticket means no new lines | T07 | todo |
| T09 | wf done warns on edits to earlier or Base tests | T06 | todo |
| T10 | wf done: red-commit rewrites, brand-new files, block mode | T09 | todo |
| T11 | review-lanes runs the full and clean suites together | T00 | done fa9680ea |
| T12 | review-lanes wording lane in its own copy | T11 | doing |
| T13 | Shipped modes: delivers blocks, the other three warn | T08, T10 | todo |

## Rulings
- 2026-11-24, T00 (afk): resumed interrupted doing ticket, reset to todo
- 2026-11-24, T00 (afk): resumed interrupted doing ticket again, reset to todo
- 2026-11-24, T00 (afk): resumed interrupted doing ticket a third time, reset to todo; prior worktrees agent-a6200908 and agent-a4c258df had no commits
- 2026-11-24, T00 (afk): 3 prior runs lost T00 with empty worktrees, likely headless session exiting while a background implementer ran; dispatching foreground
- 2026-11-24, T11 (afk): test header may export HOME=$d/home so the real ~/.claude/checks/clean-suite-env does not leak into unset=; fixture isolation, no assertion loosened
- 2026-11-24, T01 (afk): quality finding 4 (AC-coverage rule duplicated in check-red-green.sh and wf red) fixed by one helper in new skills/build/scripts/ac-covered.sh, wf added to Files; refactor, no behaviour change
- 2026-11-24, T11 quality (logged): review-lanes usage/no-Test-command ERROR Fix: text untested; ~/.claude/checks/clean-suite-env read (lines 44-45) untested and final-review SKILL.md step 2 dropped its mention; SKILL.md 'exit 2 means apply the Fix' false for INT/TERM exit 2 with no Fix
- 2026-11-24, T12 (afk): wording test header may export HOME=$d/home, same isolation as T11's ruling
- 2026-11-24, T01 (afk): delivers-test.sh US-9.AC9 probe may change to a line with ':' so the Delivers-section limit is actually tested; Tests block updated

