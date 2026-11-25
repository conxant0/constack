# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: PASS
Spec: docs/work/workflow-speed/spec.md
Range: 9d13f46cb7f75eb15ab3d993a8a9a96d4594be3b...b557fa8653b79b6f40e97e70d8153f46ef974377
Mode: delta since 72be583
Date: 2026-11-25

## Acceptance criteria

Delta run: the fix range 72be583..HEAD (F07) changes check-red-green.sh:37-48 (`pytest_cmd` now keeps the Verify's prefix words) and appends 32 lines to wording-test.sh. US-3.AC5 is judged in full. Every other row was re-judged only for this: its cited assertions are unchanged, because the one test diff only adds lines, and the suite passes at HEAD.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-3.AC4 | 62f7e89 | yes | wording-test.sh:64-79, direct and variable forms each: SURVIVED line with Fix, no could-not-run, venv python used. Re-run by the lead: the test fails at 62f7e89 (`AC4 [direct] no SURVIVED line`, `printed could-not-run`) and with the old `[^ ]*/python3?` regex restored at HEAD (judged at 72be583). re-judged at b557fa8: assertions unchanged, pass at HEAD; with no prefix the built command is unchanged by F07 |
| US-3.AC5 | 3cb0af5 | yes | wording-test.sh:81-111, for each of the three forms (`envu`, `assign`, `pyvar`; fixture X is 2 only under that prefix, TOKEN=1 exported to the check): (a) exit 0, the exact `WARN wording pkg/msg.py:MSG: SURVIVED Keep it short.. Fix:` line, no could-not-run; (b) a guard commit with a biting Mutation patch: exit 0, `OK   guard US-1.AC2`, no `FAIL guard`. `pyvar` needs both DEV_MODE and OTHER, so a prefix cut to one word fails it. Re-run by the lead: at 3cb0af5 (pre-green) all 15 assertions fail (5 per form, each listed once). Green 5ed4ffd |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC1 | c48c548 (guard) | yes | shipped-modes-test.sh:11-25 with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch WARN exit 0, wording WARN exit 0 (no SKIP in this run). Planned guard; Mutation flips checks.conf values. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL (modes-test.sh:15-24). wording block at wording-test.sh:29-31, guard-patch block at guard-patch-test.sh:44-46. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC3 | fe2fe21 | yes | exact log line. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks through the check, wording and guard-patch print `warn` from `wf mode` (modes-test.sh:26-34); the check's use of `wf mode` is shown by the block cases under US-6.AC2. Green 300c319 (T02); guard on arrival after a same-ticket green (index ruling 2026-11-24). re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC13 | c579269, 3a31088 (guard) | yes | modes-test.sh:46-48 now runs check-red-green.sh with `wording=maybe` and `guard-patch=maybe`: exit 2 and the exact ERROR line with Fix. Re-run by the lead: with check-red-green.sh:85 or :88 changed to fall back to `warn` (the guard's Mutation), modes-test fails `AC13 guard-patch through the check: exit 1, want 2` / `AC13 wording through the check: exit 1, want 2`. Guard on true code (exit 2 already held, measured in the last round). re-judged at b557fa8: assertions unchanged (modes-test.sh not in 72be583..HEAD), pass at HEAD |
| US-6.AC14 | be9eb62 | yes | PASS review, `(fixed in T03)` with T03 done among two done rows (8e1b5c0): exit 0, no check-warning line; fails at a90a613 (measured in the round that added it). re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
| US-6.AC15 | 2911955 | yes | unknown T09 and todo T05 each print the exact fixed-in line with Fix, exit 1; fails at a90a613 (measured in the round that added it). Guard 0cc93c7 adds a no-index case; its Mutation names the `$idx` code that refactor ccdcbd4 replaced, the case still fails closed at HEAD. re-judged at b557fa8: its test assertions are unchanged (wording-test.sh +32/-0 is append-only in 72be583..HEAD; no other test file changed) and pass at HEAD; judgment carried from 2fc7448 |
Copy: n/a, no Python source in range (`git diff --name-only origin/main...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0 at b557fa8, no FAIL or SKIP line).

Clean checkout (detached worktree at b557fa8, no `.worktreeinclude` in the repo, 2 variables from `~/.claude/checks/clean-suite-env` removed with `env -u`): pass (rc=0).

`wf red`: no output (every AC has a red or guard commit).

## Out of Scope

none. `wf scope` lists the same two files as the last round: TODOS.md and skills/build/scripts/test/ac-covered-test.sh. The fix range adds no unplanned file. F07 only changes how `pytest_cmd` builds its command, so it reaches no Out of Scope line.

## Structure

`wf size`: none

none.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. The finder ran on base 72be583 with the caller instruction. Its `git diff --stat 72be583...HEAD` lists the same 6 files as `git diff --name-only`. Source file read: check-red-green.sh (`pytest_cmd`, :37-48). Callers it opened: `narrowed()` :53-58 (run with `bash -c` at :64, :125, :131) and `wording()` :66-86 (`mutate-copy ... -- bash -c "$cmd"` at :75). It also opened the script's callers in build/SKILL.md, test-only-fix.md, implementer.md and wf. Test and doc files: all read. Spot-checked caller: check-red-green.sh:73-75 builds `cmd=$(pytest_cmd " -x" "$tests")` and runs it through `mutate-copy ... -- bash -c "$cmd"`, and :160 already runs the whole Verify with `bash -c "$verify"`, as the report says. The new `pre` text is a substring of the same lead-written Verify, so it adds no new input. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. The fix range does not touch that code, so the last round's proof was re-run at b557fa8: `bash $TMPDIR/scratchpad/proof.sh` ->

```
../escape.txt -> WARN guard-patch US-1.AC1 72d435d5: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 a09a0ec1: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

none. Last round's finding 1 (the Verify's environment prefix dropped) is fixed: the lead re-ran `bash $TMPDIR/fr-71220/beh/probe.sh <repo>/skills/build/scripts` at b557fa8, and 1a and 1c now print `WARN wording pkg/msg.py:MSG: SURVIVED Keep it short..` with exit 0, while 1b prints `OK   guard US-1.AC2` and `OK   green HEAD` with exit 0.

This round's finder probe is `bash $TMPDIR/fr-final3/beh/run-all.sh` (one fixture per Verify shape, with the check at HEAD and the 72be583 copy side by side). The lead re-ran it at b557fa8 and every bug below reproduced. Each prints a false `OK red` with a shell error as its reason, `FAIL guard` beside `OK green HEAD` on the same sha, and a false `WARN wording T01: could not run`, exit 1. None is money. None is common: 0 of the 302 distinct `-m pytest` Verify lines in ticket files under $HOME/Developer use any of these shapes (measured by the lead's grep). So each one is a note.

### Notes

- skills/build/scripts/check-red-green.sh:44: an interpreter option before `-m` (`python3 -B -m pytest`): the sed treats `-B` as the interpreter, and the built command runs `python3 python3 -m pytest`. 72be583 replied correctly. neither
- skills/build/scripts/check-red-green.sh:44: a Verify wrapped in `bash -c "..."` gives `pre` an unclosed quote, so the built command has a syntax error. 72be583 replied correctly. neither
- skills/build/scripts/check-red-green.sh:44: a `;` inside a quoted value before the interpreter (`env "A=1;2" python3 -m pytest`) is cut inside the quotes, leaving an unbalanced `pre`. 72be583 replied correctly. neither
- skills/build/scripts/check-red-green.sh:44: a multi-line Verify (`cd pkg` on line 1, pytest on line 2): the sed works one line at a time, so it turns line 1 into a bare `cd`. 72be583 replied correctly. neither
- skills/build/scripts/check-red-green.sh:42: an unquoted `PY=../venv/bin/python3 && $PY -m pytest` takes `PY=...` as the interpreter (`bash: -m: command not found`). 72be583 gives the same reply. neither
- skills/build/scripts/check-red-green.sh:42-43: a bare `python` in Verify runs as `python3`; where those differ, a red test that already passes gets `OK red ...: No module named pytest` (BEH 2b, re-run at b557fa8). older
- skills/build/scripts/check-red-green.sh:42,131: a substitution holding `)` or nested quotes gives a broken interpreter token and a false `OK red` on the syntax error (BEH 3, re-run at b557fa8). 0 occurrences measured. older
- skills/build/scripts/check-red-green.sh:42,131: `"$VAR/bin/python3"` keeps the opening quote and gives a false `OK red` on `unexpected end of file` (BEH 4). 0 occurrences measured. older
- skills/build/scripts/check-red-green.sh:115,121: a guard that is not the last commit gets an amend Fix that cannot clear it (carried from 2fc7448). neither
- skills/build/scripts/check-red-green.sh:71,80: a red test file outside `tests/` gives a could-not-run warning that names the ticket id twice (carried from 2fc7448). neither
- skills/build/scripts/wf:492-496: a PASS review with a `real ... (F05)` row naming a ticket missing from the index passes check-review (carried from 2fc7448). neither

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md; `git diff --name-only origin/main...HEAD -- .claude/skills/verify/` is empty). 0 minutes.

## Fix tickets

none

## OPEN

none
