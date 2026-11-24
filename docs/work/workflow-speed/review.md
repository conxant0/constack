# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: PASS
Spec: docs/work/workflow-speed/spec.md
Range: db1a6de0df8f1d0805fbb73c3c6e15bf72aa81af...45266ef4ee5a3438c293f660879cbdfcd7a72da6
Mode: delta since 5672a1e1344dfaf847b2284c232103fc6dcd4a26
Date: 2026-11-24

## Acceptance criteria

Guards on this branch carry prose `Mutation:` lines only: the build ran on the installed skills from Base, before the diff-fence rule this branch adds, so no guard is judged by a patch.

Delta scope: the fix diff 5672a1e..45266ef (F04) changes only skills/build/scripts/earlier-tests.sh and earlier-tests-block-test.sh. Re-judged: every US-5 AC (T00, T09, T10, F03, F04 deliver through earlier-tests.sh) and US-6.AC13 (F01 lists earlier-tests.sh). Every other row is carried from 5672a1e.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh; carried from 5672a1e |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run; carried from 5672a1e |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from 5672a1e |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from 5672a1e |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN; carried from 5672a1e |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only; carried from 5672a1e |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading; carried from 5672a1e |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b; carried from 5672a1e |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only; carried from 5672a1e |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08; carried from 5672a1e |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out; carried from 5672a1e |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from 5672a1e |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard; carried from 5672a1e |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06; carried from 5672a1e |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0; carried from 5672a1e |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged; carried from 5672a1e |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode; carried from 5672a1e |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour; carried from 5672a1e |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard; carried from 5672a1e |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied; carried from 5672a1e |
| US-5.AC1 | a1f622e | yes | exact WARN line and log line; one per file; no-merge (doing commit) case. Guard 40a9e10 covers own-red exemption, dedupe and no-merge start; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC2 | 4cc8d7e | yes | ruling in ticket and in index allows; a non-matching path (`tests/t1.sh.bak`, other ticket's ruling) does not; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC3 | 444d79c | yes | Base test file edit warns with Fix; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC4 | 26db4ad (guard) | yes | new test file in ordinary commit: no warning. Planned guard; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC5 | bcd3d47 (guard) | yes | after a WARN, index row is `done` and `docs(build): T02 done` committed. Planned guard; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC6 | 2059cd1, 48cf6c0 | yes | rewrite and delete of a start line warn; 48cf6c0 adds removal of one of two identical lines (earlier-tests-block-test.sh `dup` case), which F04 compares as a sorted multiset against the ticket start; the case fails with 5672a1e's earlier-tests.sh swapped in (`AC6 [repeated line] ... not flagged`, measured), and the F03-round probe `bash /tmp/fr2-80119/beh/dup-line.sh` now logs the WARN at HEAD (measured). Non-UTF-8 test file: see Behaviour note earlier-tests.sh:29 |
| US-5.AC7 | 5b00ec1 (guard), 542df9c | yes | add-only red on a branch from main's tip (guard) and, from 542df9c, an add-only red merged after a sibling changed the file (`sib` case): F04 compares with merge-base(`$3^1`,`$3^2`); the case fails with 5672a1e's earlier-tests.sh swapped in (`AC7 [sibling merged first] warned`, measured), and `bash /tmp/fr2-80119/beh/stale-branch.sh` is silent at HEAD (measured). AC7 is still false in two off-path states, recorded as Behaviour notes: a non-UTF-8 byte (earlier-tests.sh:29) and a ticket branch that merged main into itself (earlier-tests.sh:9) |
| US-5.AC8 | f8fb6fd | yes | exact FAIL line with undo-merge Fix, exit 1, row stays todo, no commit, no log; two findings both FAIL; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-5.AC9 | e72a89d | yes | base and T1 files: second red rewrites T2's own added line, no warning; fails at a90a613 with the WARN (measured); re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-6.AC1 | c48c548 (guard) | yes | runs with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch, wording, earlier-tests WARN exit 0. Planned guard; carried from 5672a1e |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL. Other checks' block modes covered in their own tests; carried from 5672a1e |
| US-6.AC3 | fe2fe21 | yes | exact log line; carried from 5672a1e |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added; carried from 5672a1e |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard; carried from 5672a1e |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix; carried from 5672a1e |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard; carried from 5672a1e |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard; carried from 5672a1e |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once; carried from 5672a1e |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from 5672a1e |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged; carried from 5672a1e |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks, others warn. Green 300c319 (T02). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided); carried from 5672a1e |
| US-6.AC13 | b9455aa | yes | `wf done` with `earlier-tests=blok`: exit 2, exact ERROR line with Fix, row stays todo; fails at a90a613 (`exit 1, want 2`, measured). Check-red-green cases from c579269 unchanged; re-judged at 45266ef: test unchanged and passing; the fix diff touches earlier-tests.sh start-point and comparison only |
| US-6.AC14 | be9eb62 | yes | PASS review, `(fixed in T03)` with T03 done among two done rows (8e1b5c0): exit 0, no check-warning line; fails at a90a613 (measured); carried from 5672a1e |
| US-6.AC15 | 2911955 | yes | unknown T09 and todo T05 each print the exact fixed-in line with Fix, exit 1; fails at a90a613 (measured). Guard 0cc93c7 adds a no-index case; its Mutation names the `$idx` code that refactor ccdcbd4 replaced, the case still fails closed at HEAD; carried from 5672a1e |

Copy: n/a, no Python source in range (`git diff --name-only $BASE...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0 at 45266ef).

Clean checkout (detached worktree at 45266ef, no `.worktreeinclude` in the repo, `env -u <a vendor token> -u PUBLIC_BASE_URL` from `~/.claude/checks/clean-suite-env`): pass (rc=0).

`wf red`: no output (every AC has a red or guard commit).

## Out of Scope

none. `wf scope` lists TODOS.md and skills/build/scripts/test/ac-covered-test.sh, both judged in the previous round (doc entry for a declined finding; /encode-comments' test-only commit 5672a1e). The F04 fix diff touches only earlier-tests.sh and its test, both in F04's Files; nothing an Out of Scope line excludes.

## Structure

`wf size`: none

1. skills/build/scripts/check-red-green.sh:14 and skills/build/scripts/earlier-tests.sh:2: the red/guard subject regex `^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$` is defined twice (the second awk-escaped); the T09 ruling deferred this dedupe to final review. Smaller structure: define `red_re` once in skills/build/scripts/test-re.sh beside `test_re` and have earlier-tests.sh pass it to awk through ENVIRON instead of `-v`. declined. Decided (fable): decline; a refactor no AC needs is declined (decide.md preference 2); TODOS.md entry added.

Delta: no new finding. F04 adds one local (`st`) and swaps one comparison inside `earlier_tests`; no helper is duplicated.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. Finder (delta, base 5672a1e, caller instruction added) coverage: all 5 files of `git diff --stat 5672a1e...HEAD`; changed code `earlier_tests()` in skills/build/scripts/earlier-tests.sh (new `st`, sorted-diff comparison), callers wf:71 (source) and wf:580 (`wf done`); test file, index, review.md and F04 ticket read. Spot-checked caller: skills/build/scripts/wf:579 resolves `$3` with `git rev-parse -q --verify "$3^{commit}"` before wf:580 calls `earlier_tests`, so `$3^1`, `$3^2` and the merge-base inputs are full shas, as the report says. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. The fix diff does not touch check-red-green.sh, so the previous proof was re-run at HEAD: `bash /tmp/fr-proof/proof.sh` (runs this worktree's skills/build/scripts/check-red-green.sh) ->

```
../escape.txt -> WARN guard-patch US-1.AC1 3546b594: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 e36d5a72: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

Previous US-5.AC6 and US-5.AC7 failures are fixed by F04 (rows above).

none. The delta finder reproduced five bugs; each probe was re-run by the lead at 45266ef with the same output. None costs money; none is common (reasons in each note), so all are notes. earlier-tests.sh does not exist at Base, so the new ones are `neither`.

### Notes

- skills/build/scripts/check-red-green.sh:27: a TERM or Ctrl-C during the guard-patch test run leaves a file the patch created; the re-run warns "patch does not apply" (`bash /tmp/fr-beh/p3-guard-int.sh INT`). neither
- skills/build/scripts/review-lanes:42: on INT or TERM it exits 2 with no output and no Fix, and the three suites keep running (`bash /tmp/fr-beh/p2b-lanes-ctrlc.sh INT`). neither
- skills/build/scripts/review-lanes:101-103: a base that does not resolve makes the wording lane PASS with exit 0 (`bash /tmp/fr-beh/p1-badbase.sh`). neither
- skills/build/scripts/wf:496: a `(fixed in T03)` row followed by `.` or a space misses the end-anchored match and is told to end with `(F<nn>)`, exit 1 (`bash /tmp/fr2-80119/beh/fixed-in-trailing.sh`). neither
- skills/build/scripts/wf:494-497: `Verdict: PASS` with `Fix tickets: none` and a `real: ... (F04)` row naming no ticket passes check-review, exit 0 (`bash /tmp/fr2-80119/beh/pass-real-f.sh`). older
- skills/build/scripts/wf:580: re-running `wf done` for a ticket already done prints `commit failed`, exit 2, while the index already says done (`bash /tmp/fr2-80119/beh/done-twice.sh`, again `bash /tmp/fr4-beh/retry-clean.sh`). older
- skills/build/scripts/earlier-tests.sh:23,36: a ticket commit that edits an earlier test file outside a red, later restored by a fix commit, still warns (warn mode: true per US-5.AC1, graded false alarm in review); in opt-in block mode the restore commit never clears the FAIL, only a ticket ruling or rewritten history does (`bash /tmp/fr4-beh/review-fix.sh`, `bash /tmp/fr4-beh/block-fix.sh`). Not common: block mode is off until spec Decision 18 flips it. neither
- skills/build/scripts/earlier-tests.sh:29: a non-UTF-8 byte in a test file makes `sort` fail (`sort: Illegal byte sequence`), so an add-only red warns (AC7 false) and a deleting red is silent (AC6 false) (`bash /tmp/fr4-beh/locale.sh`). Not common: needs a non-UTF-8 test file. neither
- skills/build/scripts/earlier-tests.sh:9: a ticket branch that merged main into itself after a sibling changed the file makes `st` include the sibling's lines, so an earlier add-only red warns (AC7 false) (`bash /tmp/fr4-beh/sync.sh`). Not common: no build skill path merges main into a ticket branch (conflicts go `blocked: conflict`). neither
- skills/build/scripts/earlier-tests.sh:28: a file that existed at Base, deleted by T1's red, recreated by T2's first red and rewritten by its second red warns on the second red (`bash /tmp/fr4-beh/recreate.sh`). Not common. neither

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes.

## Fix tickets

none

## OPEN

none
