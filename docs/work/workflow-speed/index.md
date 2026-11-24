# Faster /build and /final-review, weak tests caught during /build: build index

Spec: docs/work/workflow-speed/spec.md
Branch: feature/workflow-speed
Base: origin/main
Test command: `f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T00 | One shared test-file regex, and an empty earlier-tests hook in wf done | none | done bf1229bc |
| T01 | Red-green check fails a Delivers AC with no red or guard commit | T00 | done 708d9f27 |
| T02 | Checks read warn or block from a settings file | T01 | done 2ab7528a |
| T03 | Warnings are appended once to the feature's warning log | T02 | done 9fb2126f |
| T04 | Warning log survives resets and the gate ignores it | T03 | done b4515662 |
| T05 | check-review grades every logged warning | T04, T12 | done 9bbf65b9 |
| T06 | Guard patch applied: OK, still passes, does not apply, missing | T03 | done 1f10a65d |
| T07 | Guard patch: no Mutation, clean restore, test-file patch | T06 | done 51e76dea |
| T08 | Per-ticket wording check, and no ticket means no new lines | T07 | doing |
| T09 | wf done warns on edits to earlier or Base tests | T06 | done 52774752 |
| T10 | wf done: red-commit rewrites, brand-new files, block mode | T09 | todo |
| T11 | review-lanes runs the full and clean suites together | T00 | done fa9680ea |
| T12 | review-lanes wording lane in its own copy | T11 | done 2c5b053e |
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
- 2026-11-24, T12 quality (logged): review-lanes usage error text omits --only/--wording-tests flags; --diff-filter=AM untested (deleted .py would hit mutate-copy as COULD-NOT-RUN)
- 2026-11-24, T02 quality (logged): wf catch-all usage line lists mode under <index.md> though it takes a check name (wf:573); move mode ahead of the <index.md> part
- 2026-11-24, T03 quality (logged): wf warn-log wrong-argument-count usage/exit 2 (wf:577) untested; add a warn-log-test case calling it with 3 args
- 2026-11-24, T06 quality (logged): 'first fence after the Mutation: line' rule untested (check-red-green.sh:87); add a guard-patch-test case with a non-applying diff fence above Mutation: and assert no guard-patch line
- 2026-11-24, T05 quality (logged): wf:493-494 tests never assert the file:<n>: line-number prefix of 'not graded' / 'names no fix ticket' lines; assert exact heading/row line numbers
- 2026-11-24, T07 quality (logged): check-red-green.sh:27 EXIT trap does not remove paths the patch created, as the Approach says; an early exit between apply and apply -R leaves untracked files; remove create-mode paths in the trap or drop the Approach sentence
- 2026-11-24, T09 (afk): quality finding 3 (red_re repeated in check-red-green.sh:14) is fixed only within earlier-tests.sh; moving red_re into test-re.sh is deferred because T08 is editing check-red-green.sh in parallel and the move would conflict; final review should dedupe it

