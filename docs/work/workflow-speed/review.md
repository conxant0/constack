# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: FAIL
Spec: docs/work/workflow-speed/spec.md
Range: db1a6de0df8f1d0805fbb73c3c6e15bf72aa81af...a90a613d153fc1b03f1175c201790affc598a6c8
Mode: full
Date: 2026-11-24

## Acceptance criteria

Guards on this branch carry prose `Mutation:` lines only: the build ran on the installed skills from Base, before the diff-fence rule this branch adds, so no guard is judged by a patch.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided) |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided) |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08 |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided) |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06 |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0 |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied |
| US-5.AC1 | a1f622e | yes | exact WARN line and log line; one per file; no-merge (doing commit) case. Guard 40a9e10 covers own-red exemption, dedupe and no-merge start |
| US-5.AC2 | 4cc8d7e | yes | ruling in ticket and in index allows; a non-matching path (`tests/t1.sh.bak`, other ticket's ruling) does not |
| US-5.AC3 | 444d79c | yes | Base test file edit warns with Fix |
| US-5.AC4 | 26db4ad (guard) | yes | new test file in ordinary commit: no warning. Planned guard |
| US-5.AC5 | bcd3d47 (guard) | yes | after a WARN, index row is `done` and `docs(build): T02 done` committed. Planned guard |
| US-5.AC6 | 2059cd1 | yes | rewrite and delete by T2's red both give the exact WARN line |
| US-5.AC7 | 5b00ec1 (guard) | yes | add-only red edit: no warning. Planned guard |
| US-5.AC8 | f8fb6fd | yes | exact FAIL line with undo-merge Fix, exit 1, row stays todo, no commit, no log; two findings both FAIL |
| US-6.AC1 | c48c548 (guard) | yes | runs with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch, wording, earlier-tests WARN exit 0. Planned guard |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL. Other checks' block modes covered in their own tests |
| US-6.AC3 | fe2fe21 | yes | exact log line |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided) |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks, others warn. Green 300c319 (T02). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, both re-run at final review (OPEN 1, decided) |
| US-6.AC13 | c579269 | partly | covers check-red-green and `wf mode` for all four names, never `wf done`: with `earlier-tests=blok` `wf done` prints the ERROR and Fix but exits 1 (`bash /tmp/fr-beh/p4-done-badmode.sh` -> `exit=1`; check-red-green with `wording=blok` -> `exit=2`). F01 |

Copy: n/a, no Python source in range (`git diff --name-only $BASE...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0; all 19 test files printed their pass line, no FAIL or SKIP).

Clean checkout (detached worktree at HEAD, no `.worktreeinclude` in the repo, `env -u <a vendor token> -u PUBLIC_BASE_URL` from `~/.claude/checks/clean-suite-env`): pass (rc=0; all 19 test files passed). Both ran at the same time; the installed final-review skill (Base) predates review-lanes, so they ran as two background jobs, not through review-lanes.

## Out of Scope

none. `wf scope` lists TODOS.md (no ticket's Files): its two lines are the spec's two `(fable, 2026-11-24)` Out of Scope entries, added in be5771f `docs(spec): fable rulings`; doc only. The skill doc diffs keep the prompt text the checks replace, add no fix-diff re-check for the ticket reviewer, no dispatch-order check, and no /encode-comments patch mutations.

## Structure

`wf size`: none

1. skills/build/scripts/check-red-green.sh:14 and skills/build/scripts/earlier-tests.sh:2: the red/guard subject regex `^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$` is defined twice (the second awk-escaped); the T09 ruling deferred this dedupe to final review. Smaller structure: define `red_re` once in skills/build/scripts/test-re.sh beside `test_re` and have earlier-tests.sh pass it to awk through ENVIRON instead of `-v`. declined. Decided (fable): decline; a refactor no AC needs is declined (decide.md preference 2); TODOS.md entry added.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. Finder coverage: all 51 files of `git diff --stat`; every changed non-test source (check-red-green.sh, wf, earlier-tests.sh, ac-covered.sh, test-re.sh, review-lanes, checks.conf, install.sh) with callers; tests and ticket docs marked skipped. Spot-checked caller: skills/build/scripts/wf:577 calls `earlier_tests "$1" "$2" "$sha" || exit 1` in `done`, as the report says. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. Proof: `bash /tmp/fr-proof/proof.sh` (guard patches creating `../escape.txt` and `.git/hooks/post-checkout`, run through the real check-red-green.sh) ->

```
../escape.txt -> WARN guard-patch US-1.AC1 48e5c9d9: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 5bb501cb: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

1. skills/build/scripts/check-red-green.sh:60 with skills/build/scripts/wf:494. State: a WARN logged in build round 1 is fixed in the fix round (the re-run is clean). What the user gets: the line stays in check-warnings.log, and `wf check-review` refuses the true grade (real, already fixed). The reviewer has to write a fix ticket for done work or a false `false alarm`, which skews the count used to switch a check to blocking. Money: no (it costs the owner a /build round, not a customer charge). Common: yes (WARN, reviewer flags it, implementer fixes it is the designed path). Base: code is new. Probe `bash /tmp/fr-beh/p9-stale-wording.sh` -> round 1 `WARN wording pkg/msg.py:MSG: SURVIVED Never charge twice.`, fix-round re-run clean (exit 0), log still holds the line, `wf check-review` -> `check warning graded real names no fix ticket ... Fix: end the row with (F<nn>)`, exit=1. New ACs US-6.AC14 and US-6.AC15. Decided (fable): check-review accepts `real: <reason> (fixed in <ticket id>)` naming a ticket the index records done; Decisions updated. F02
2. skills/build/scripts/earlier-tests.sh:25. State: T02's two red commits edit a test file that existed at Base; the second rewrites a line the first one added, and no Base line changes. What the user gets: `WARN earlier-tests tests/test_api.py: T02 commit ... (red or guard) removed or rewrote lines`, logged, with a Fix that asks for a ruling the ticket does not need. Money: no. Common: yes (two ACs tested in one existing test file). Base: code is new. Probe `bash /tmp/fr-beh/p6b-import-line.sh` -> `Base lines removed or changed: (none)`, then the WARN above, exit=0. New AC US-5.AC9, with US-5.AC6's Given narrowed to lines the file had when T2 started. Decided (fable): a red or guard commit warns only when a line the file had at the ticket's start is gone. F03

### Notes

- skills/build/scripts/check-red-green.sh:27: a TERM or Ctrl-C during the guard-patch test run leaves a file the patch created (`?? new.txt`); the re-run then warns "patch does not apply" and logs it (`bash /tmp/fr-beh/p3-guard-int.sh INT`). neither
- skills/build/scripts/review-lanes:42: on INT or TERM it exits 2 with no output and no Fix, and the three suites keep running (`bash /tmp/fr-beh/p2b-lanes-ctrlc.sh INT` -> slow.sh and mutate-copy still running). neither
- skills/build/scripts/review-lanes:101-103: a base that does not resolve makes the wording lane PASS with exit 0 (`bash /tmp/fr-beh/p1-badbase.sh` -> `fatal: bad revision 'orgin/main...HEAD'`, `LANE wording: PASS`, exit=0). neither

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes.

## Fix tickets

F01 wf done exits 2 on a bad earlier-tests mode: fixes US-6.AC13
F02 check-review accepts a real warning already fixed in /build: fixes Behaviour 1 (US-6.AC14, US-6.AC15)
F03 earlier-tests ignores a ticket rewriting its own added lines: fixes Behaviour 2 (US-5.AC9)

## OPEN

none

Decided items:

1. Five ACs whose ticket planned a red test landed as guards on arrival after a same-ticket green: US-1.AC3, US-1.AC4 (after a24ddfd, T11), US-3.AC2 (after bc5fe77, T08), US-6.AC10 (after c3cb637, T03), US-6.AC12 (after 300c319, T02). skills/build/references/implementer.md:30 allows such a guard; final-review step 4 says a guard's AC must have been true before its ticket. All five mutations re-run, and each test also fails on the code before its green (measured by fable). Decided (fable): the rows stand as `yes`, because the column asks whether the test fails whenever the AC is false, which is measured true, and implementer.md:30 asks for exactly this guard; a fix ticket would have nothing to change.
