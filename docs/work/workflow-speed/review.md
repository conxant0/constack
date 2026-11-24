# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: FAIL
Spec: docs/work/workflow-speed/spec.md
Range: db1a6de0df8f1d0805fbb73c3c6e15bf72aa81af...caf3bbc7c47b7016cb816fb268020f2c861a82d3
Mode: delta (PREV a90a613d153fc1b03f1175c201790affc598a6c8)
Date: 2026-11-24

## Acceptance criteria

Guards on this branch carry prose `Mutation:` lines only: the build ran on the installed skills from Base, before the diff-fence rule this branch adds, so no guard is judged by a patch.

Delta scope: ACs with a red or guard in a90a613..caf3bbc (US-5.AC9, US-6.AC13-15), and ACs whose ticket lists a file the fix diff changed (wf, earlier-tests.sh, ac-covered.sh, review-lanes, check-review-warnings-test.sh, modes-test.sh, earlier-tests-block-test.sh: every US-1, US-2, US-5 and US-6 AC) are re-judged; US-3 and US-4 rows are carried.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in review-lanes |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in review-lanes |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in review-lanes |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in review-lanes |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in review-lanes |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in ac-covered.sh |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in ac-covered.sh |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in ac-covered.sh |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in ac-covered.sh |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08; re-judged at caf3bbc: test unchanged and passing; the fix diff touches only a header comment in ac-covered.sh |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out; carried from a90a613 |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from a90a613 |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard; carried from a90a613 |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06; carried from a90a613 |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0; carried from a90a613 |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged; carried from a90a613 |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode; carried from a90a613 |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour; carried from a90a613 |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard; carried from a90a613 |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied; carried from a90a613 |
| US-5.AC1 | a1f622e | yes | exact WARN line and log line; one per file; no-merge (doing commit) case. Guard 40a9e10 covers own-red exemption, dedupe and no-merge start; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC2 | 4cc8d7e | yes | ruling in ticket and in index allows; a non-matching path (`tests/t1.sh.bak`, other ticket's ruling) does not; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC3 | 444d79c | yes | Base test file edit warns with Fix; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC4 | 26db4ad (guard) | yes | new test file in ordinary commit: no warning. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC5 | bcd3d47 (guard) | yes | after a WARN, index row is `done` and `docs(build): T02 done` committed. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC6 | 2059cd1 | partly | rewrite and delete of a start line warn, but F03's `grep -vxFf` (earlier-tests.sh:27) asks only whether each start line's text survives anywhere: removing one of two identical assertion lines prints nothing and records done (`bash /tmp/fr2-80119/beh/dup-line.sh` -> `exit=0`, `log: (none)`; a90a613 warned). F04 |
| US-5.AC7 | 5b00ec1 (guard) | partly | add-only case covered only on a branch started from main's tip; F03 compares with `$3^1`, so an add-only red merged after a sibling changed the file warns (`bash /tmp/fr2-80119/beh/stale-branch.sh` -> `WARN earlier-tests tests/base.sh: T02 commit ... removed or rewrote lines`; a90a613 silent). F04 |
| US-5.AC8 | f8fb6fd | yes | exact FAIL line with undo-merge Fix, exit 1, row stays todo, no commit, no log; two findings both FAIL; re-judged at caf3bbc: test unchanged and passing; the fix diff touches earlier-tests.sh red-commit filter (see AC6, AC7) |
| US-5.AC9 | ff5211b | yes | base and T1 files: second red rewrites T2's own added line, no warning; fails at a90a613 with the WARN (measured) |
| US-6.AC1 | c48c548 (guard) | yes | runs with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch, wording, earlier-tests WARN exit 0. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL. Other checks' block modes covered in their own tests; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC3 | fe2fe21 | yes | exact log line; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged; re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks, others warn. Green 300c319 (T02). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); re-judged at caf3bbc: test unchanged and passing; the fix diff touches check_review fixed-in branch and the done exit code |
| US-6.AC13 | 3ce3d2c | yes | `wf done` with `earlier-tests=blok`: exit 2, exact ERROR line with Fix, row stays todo; fails at a90a613 (`exit 1, want 2`, measured). Check-red-green cases from c579269 unchanged |
| US-6.AC14 | d9c3cce | yes | PASS review, `(fixed in T03)` with T03 done among two done rows (a7dddb7): exit 0, no check-warning line; fails at a90a613 (measured) |
| US-6.AC15 | f91bf5b | yes | unknown T09 and todo T05 each print the exact fixed-in line with Fix, exit 1; fails at a90a613 (measured). Guard 8132f67 adds a no-index case; its Mutation names the `$idx` code that refactor 23c92d1 replaced, the case still fails closed at HEAD |

Copy: n/a, no Python source in range (`git diff --name-only $BASE...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0; all 20 test files printed their pass line, ac-covered-test included).

Clean checkout (detached worktree at caf3bbc, no `.worktreeinclude` in the repo, `env -u <a vendor token> -u PUBLIC_BASE_URL` from `~/.claude/checks/clean-suite-env`): pass (rc=0; all 20 test files passed).

`wf red`: no output (every AC has a red or guard commit).

## Out of Scope

none. `wf scope` lists TODOS.md and skills/build/scripts/test/ac-covered-test.sh. TODOS.md gains the declined structure finding's entry (doc only). ac-covered-test.sh is /encode-comments' `test(comment)` commit caf3bbc, which tests the contract of the comment ff04f6b stripped from ac-covered.sh; test only, no behaviour change. The fix diff adds nothing an Out of Scope line excludes.

## Structure

`wf size`: none

`wf size`: none

1. skills/build/scripts/check-red-green.sh:14 and skills/build/scripts/earlier-tests.sh:2: the red/guard subject regex `^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$` is defined twice (the second awk-escaped); the T09 ruling deferred this dedupe to final review. Smaller structure: define `red_re` once in skills/build/scripts/test-re.sh beside `test_re` and have earlier-tests.sh pass it to awk through ENVIRON instead of `-v`. declined. Decided (fable): decline; a refactor no AC needs is declined (decide.md preference 2); TODOS.md entry added.

Delta: no new finding. The F02 check_review change reuses `tickets()` (refactor 23c92d1) rather than re-parsing the index.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. Finder (delta, base a90a613, caller instruction added) coverage: all 18 files of `git diff --stat a90a613...HEAD`; changed code check_review and the `done` case in wf, earlier_tests, ac_uncovered (comment only), review-lanes (comment only), with callers (wf `check-review` case, afk-loop:86, final-review and pr SKILL.md, build SKILL.md:24/:55, serial.md:7, wf `red()`, check-red-green.sh:151); ticket prose and review.md skipped. Spot-checked caller: skills/build/scripts/wf:580 `earlier_tests "$1" "$2" "$sha" || exit $?` runs before `set_status`, so a non-zero exit still leaves the ticket unrecorded, as the report says. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. The fix diff does not touch check-red-green.sh, so the previous proof was re-run at HEAD: `bash /tmp/fr-proof/proof.sh` (runs this worktree's skills/build/scripts/check-red-green.sh) ->

```
../escape.txt -> WARN guard-patch US-1.AC1 e60a01a2: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 ef3efae3: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

Previous findings 1 and 2 are fixed by F02 and F03 (US-6.AC14, US-6.AC15, US-5.AC9 rows above).

none new as findings. The delta finder's two regressions in F03's comparison are AC failures, filed under US-5.AC6 and US-5.AC7 above (F04), not here.

### Notes

- skills/build/scripts/check-red-green.sh:27: a TERM or Ctrl-C during the guard-patch test run leaves a file the patch created; the re-run warns "patch does not apply" (`bash /tmp/fr-beh/p3-guard-int.sh INT`). neither
- skills/build/scripts/review-lanes:42: on INT or TERM it exits 2 with no output and no Fix, and the three suites keep running (`bash /tmp/fr-beh/p2b-lanes-ctrlc.sh INT`). neither
- skills/build/scripts/review-lanes:101-103: a base that does not resolve makes the wording lane PASS with exit 0 (`bash /tmp/fr-beh/p1-badbase.sh`). neither
- skills/build/scripts/wf:496: a `(fixed in T03)` row followed by `.` or a space misses the end-anchored match and is told to end with `(F<nn>)`, exit 1 (`bash /tmp/fr2-80119/beh/fixed-in-trailing.sh`). neither
- skills/build/scripts/wf:494-497: `Verdict: PASS` with `Fix tickets: none` and a `real: ... (F04)` row naming no ticket passes check-review, exit 0 (`bash /tmp/fr2-80119/beh/pass-real-f.sh`). older
- skills/build/scripts/wf:580: re-running `wf done` for a ticket already done prints `commit failed`, exit 2, while the index already says done (`bash /tmp/fr2-80119/beh/done-twice.sh`). older

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes.

## Fix tickets

F04 earlier-tests compares red commits with the ticket's real start, counting repeated lines: fixes US-5.AC6, US-5.AC7

## OPEN

none
