# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: FAIL
Spec: docs/work/workflow-speed/spec.md
Range: 9d13f46cb7f75eb15ab3d993a8a9a96d4594be3b...2fc744813644dbcdaf14fa04fe39bee0b0430c67
Mode: full
Date: 2026-11-25

## Acceptance criteria

Full run after 2fc7448 removed US-5 (the earlier-tests check in `wf done`) and moved it to Out of Scope. Every row was judged against the test file as it stands at HEAD, not only at its red commit: 2fc7448 edited modes-test.sh and shipped-modes-test.sh and deleted earlier-tests-test.sh, earlier-tests-block-test.sh and lib-lead.sh. US-5 has no ACs left, so it has no rows.

Guards on this branch carry prose `Mutation:` lines only: the build ran on the installed skills from Base, before the diff-fence rule this branch adds, so no guard is judged by a patch.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24 |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24 |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08 |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24 |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06 |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0 |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied |
| US-6.AC1 | c48c548 (guard) | yes | shipped-modes-test.sh:11-25 with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch WARN exit 0, wording WARN exit 0 (no SKIP in this run). Planned guard; Mutation flips checks.conf values |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL (modes-test.sh:15-24). wording block at wording-test.sh:29-31, guard-patch block at guard-patch-test.sh:44-46 |
| US-6.AC3 | fe2fe21 | yes | exact log line |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24 |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks through the check, wording and guard-patch print `warn` from `wf mode` (modes-test.sh:26-34); the check's use of `wf mode` is shown by the block cases under US-6.AC2. Green 300c319 (T02); guard on arrival after a same-ticket green (index ruling 2026-11-24) |
| US-6.AC13 | c579269, b9455aa | partly | modes-test.sh:37-46 runs the check only for `delivers=maybe` (exit 2, exact ERROR line with Fix); for `wording` and `guard-patch` it calls `wf mode` alone. With check-red-green.sh:85 and :88 changed to fall back to `warn` on a bad value, all 16 suite files still pass (measured, scratch copy), so the AC can be false for those two checks with no failing test. b9455aa's `wf done` case went with the removed check in 2fc7448. F05 |
| US-6.AC14 | be9eb62 | yes | PASS review, `(fixed in T03)` with T03 done among two done rows (8e1b5c0): exit 0, no check-warning line; fails at a90a613 (measured in the round that added it) |
| US-6.AC15 | 2911955 | yes | unknown T09 and todo T05 each print the exact fixed-in line with Fix, exit 1; fails at a90a613 (measured in the round that added it). Guard 0cc93c7 adds a no-index case; its Mutation names the `$idx` code that refactor ccdcbd4 replaced, the case still fails closed at HEAD |

Copy: n/a, no Python source in range (`git diff --name-only origin/main...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0 at 2fc7448, no SKIP line).

Clean checkout (detached worktree at 2fc7448, no `.worktreeinclude` in the repo, the 2 names in `~/.claude/checks/clean-suite-env` removed with `env -u`): pass (rc=0).

`wf red`: no output (every AC has a red or guard commit).

## Out of Scope

none. `wf scope` lists TODOS.md (one entry, the warning-log lock the spec's Out of Scope names) and skills/build/scripts/test/ac-covered-test.sh (/encode-comments' test-only commit). The removed US-5 check: `grep -rnE 'earlier[-_ ]tests'` outside docs/ finds nothing; `wf done` only records the status (wf:576-579), checks.conf has three lines, `wf mode earlier-tests` exits 2 with usage. The `may change:` ruling prose left in skills/build/SKILL.md:32, skills/direct/SKILL.md:16 and fix-ticket-template.md:33 is read by the ticket reviewer (reviewer.md:18), which the Out of Scope line keeps.

Stale Decisions (was OPEN 1): spec.md Decisions still described the removed US-5 check: "the four shipped modes", "A ticket's commits are the merged side of its merge ..." and "`wf done` reads `may change:` lines ...". Probe: `grep -rnE 'earlier[-_ ]tests' . --exclude-dir=.git --exclude-dir=docs` -> no output; wf:576-579 only records the status. Decided (fable): correct the three Decision lines in this commit (three shipped modes; drop the ticket's-commits sentence, keep the shared test-file definition; delete the `wf done` reads line), no ticket, skill prose untouched.

## Structure

`wf size`: none

none. The red/guard subject regex the last review found twice is now defined once (check-red-green.sh:14); its second copy went with earlier-tests.sh.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. Finder (full, base origin/main) coverage: its `git diff --stat origin/main...HEAD` lists the same 53 files as `git diff --name-only`; source files read: install.sh, skills/build/checks.conf, test-re.sh, ac-covered.sh, check-red-green.sh, review-lanes, wf, and the 9 changed skill and doc files; the 15 test files and the docs/work records marked skipped. Spot-checked caller: check-red-green.sh:60 (`finding`) calls `wf warn-log "$(dirname "$(dirname "$ticket")")" "$2" "$ticket_id" "$3: $4"`, and wf:584-591 appends that one line to `<feature-dir>/check-warnings.log` and the ignore entry, as the report says. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. Proof: `bash $TMPDIR/scratchpad/proof.sh` (runs this worktree's skills/build/scripts/check-red-green.sh) ->

```
../escape.txt -> WARN guard-patch US-1.AC1 5a5b50b4: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 626a8104: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

Probes are under $TMPDIR/scratchpad/beh/ (BEH below); each was re-run by the lead at 2fc7448 with the finder's output.

1. skills/build/scripts/check-red-green.sh:42 and :80. State: the ticket's Verify names its interpreter as `"$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3"`. The check takes `--git-common-dir)/../venv/bin/python3` as the interpreter, so the wording command is a shell syntax error. The lead gets `WARN wording T01: could not run: mutate-copy: TEST COMMAND fails before any edit; fix that first (run it yourself to see why). Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir.` The Verify passes when run by hand, there is no snapshot test and the tests are under one tests dir, so the reply is false and its Fix cannot clear it; the same tests with `../../venv/bin/python3` print `WARN wording packages/backend/app/msgs.py:MSG: SURVIVED Your card is charged once..`. Common: yes, 166 Verify lines in 147 ticket files under $HOME/Developer use that shape (measured by grep). Money: no. Base prints no wording line (`bash BEH/b4-main.sh`), so the reply is new. Probe: `bash BEH/b4-wording-py.sh` ->

```
1 passed in 0.01s
OK   red US-1.AC1 0f830ca3: bash: -c: line 0: syntax error near unexpected token `)'
OK   green HEAD 55426d0b
WARN wording T01: could not run: mutate-copy: TEST COMMAND fails before any edit; fix that first (run it yourself to see why). Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir.
exit=0
```

The variable form `PY="$(...)/../venv/bin/python3" && $PY -m pytest` (the probe's) and the direct quoted form both give this reply (direct form: `bash $TMPDIR/scratchpad/decide/q2-direct.sh`). New AC US-3.AC4, F06. Decided (fable): one AC naming both measured forms.

### Notes

- skills/build/scripts/check-red-green.sh:115,121: a guard that is not the last commit warns `Mutation has no patch`; its Fix says `git commit --amend`, which rewrites HEAD, so the warning stays and the run then FAILs on the amended commit (`bash BEH/b1-amend-fix.sh`). Not common: the implementer prompt writes the patch with the guard, so the warning needs a guard written against the prompt. neither
- skills/build/scripts/check-red-green.sh:42: with that same Verify shape a red commit's own run is a shell syntax error and still prints `OK   red` (`bash BEH/b4-main.sh`). older
- skills/build/scripts/check-red-green.sh:71,80: a red test file outside a `tests/` dir makes the wording command `false`; the warning says the tests fail though none ran, and the log line repeats the ticket id (`wording T01 T01: could not run`) (`bash BEH/b2-wording-false.sh`). Not common; the Fix it prints does apply. neither
- skills/build/scripts/wf:492-496: `Verdict: PASS` with `Fix tickets: none` and a `real: ... (F05)` row naming a ticket the index does not have passes check-review, exit 0 (`bash BEH/b3-pass-real.sh`). Not common. neither

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes.

## Fix tickets

F05 A bad mode for wording or guard-patch stops the check with exit 2: fixes US-6.AC13
F06 The wording check runs with a quoted command-substitution interpreter: fixes Behaviour 1 (US-3.AC4)

## OPEN

none
