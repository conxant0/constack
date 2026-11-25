# Faster /build and /final-review, weak tests caught during /build: final review

Verdict: FAIL
Spec: docs/work/workflow-speed/spec.md
Range: 9d13f46cb7f75eb15ab3d993a8a9a96d4594be3b...72be58379fc28c641d477a2f53d9ed360806c70a
Mode: delta since 2fc7448
Date: 2026-11-25

## Acceptance criteria

Delta run: the fix range 2fc7448..HEAD changes check-red-green.sh:42 (`pytest_cmd`'s interpreter pick), modes-test.sh and wording-test.sh. US-3.AC4 and US-6.AC13 are re-judged in full. Every other AC whose ticket lists check-red-green.sh was checked only for this: its test file is unchanged since 2fc7448 and the suite passes at HEAD. Its row is carried.

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 09ebeb8 | yes | review-lanes-test.sh:31-42: both lanes sleep 2s, second-granularity windows must overlap both ways; full and clean FAIL lines name tests/bad.sh. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-1.AC2 | 1dd722c | yes | review-lanes-wording-test.sh:30-41: full lane samples the review tree's tracked status 4 times, wording lane's own copy is seen in the log, full result equals a plain run. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-1.AC3 | 3f7f914 (guard) | yes | header `unset=NEEDED` and `FAILED tests/env.sh`, value not printed. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-1.AC4 | 54825f3 (guard) | yes | worktree list back to 1 and no temp dir after a FAIL run and a PASS run. Green a24ddfd (T11). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-1.AC5 | 41d7496 | yes | .venv/ and .env include cases report `1 sentences`, control without the include gives COULD-NOT-RUN. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-2.AC1 | 404fc5d | yes | exact FAIL line with Fix, exit 1. Row rests on the red; guards defb656, 0f69928, aaddf45 mutate line order, error text and path handling only. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-2.AC2 | 1279653 (guard) | yes | both `none` and `none (<reason>)` give exit 0 and no delivers line. Guard planned in T01 Tests heading. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-2.AC3 | 2ea3cba | yes | AC7b red accepted; an AC7 red does not satisfy AC7b. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-2.AC4 | 04900df | yes | red between start and reviewed head accepted with start passed; FAIL without it. Guard cc97613 mutates error text only. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-2.AC5 | 8f250bb (guard) | yes | no ticket: exactly the two lines Base prints (`OK red`, `OK green`), exit 0, no log file anywhere. Planned guard; true before T08. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-3.AC1 | af78bf5 | yes | exact WARN SURVIVED line with Fix, exit 0, logged; killed sentence and guard-test cases print nothing; non-red test files stay out. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-3.AC2 | 26921a4 (guard) | yes | snapshot (r2) and tests-fail-before-edit (r3) both give `WARN wording T01: could not run ... Fix:`, exit 0, no FAIL. Green bc5fe77 (T08). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-3.AC3 | 2e33e70 (guard) | yes | docstring and comment change prints no wording line. Planned guard. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC1 | 6236101 (guard) | yes | exact OK guard line and no guard-patch line for an applying, biting patch. Planned guard; true before T06. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC2 | 87a817e | yes | exact WARN line, OK line kept, exit 0. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC3 | 5a088cc | yes | exact WARN line, app.txt unchanged. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC4 | a228c13 | yes | exact WARN line, logged with ticket, FAIL in block mode. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC5 | 3ae2b5e (guard) | yes | exact FAIL line, exit 1, no guard-patch line. Planned guard; Base behaviour. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC6 | 683af61 (guard) | yes | biting, file-creating and non-applying patches: porcelain (untracked included) empty and same branch after. Planned guard. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-4.AC7 | 9583e37 | yes | exact WARN line, patch not applied. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC1 | c48c548 (guard) | yes | shipped-modes-test.sh:11-25 with the shipped checks.conf (CHECKS_CONF unset): delivers FAIL exit 1, guard-patch WARN exit 0, wording WARN exit 0 (no SKIP in this run). Planned guard; Mutation flips checks.conf values. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC2 | 0bff02e | yes | delivers block: FAIL exit 1 no WARN; warn: WARN exit 0 no FAIL (modes-test.sh:15-24). wording block at wording-test.sh:29-31, guard-patch block at guard-patch-test.sh:44-46. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC3 | fe2fe21 | yes | exact log line. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC4 | 297c110 | yes | re-run keeps 1 line; a different line is still added. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC5 | c029759 (guard) | yes | block run leaves no log. Planned guard. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC6 | 2e8e615 | yes | ungraded, bare, other-row and outside-section cases each named with Fix. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC7 | eec3b2e (guard) | yes | no log and empty log: nothing about check warnings. Planned guard. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC8 | c5a7143 (guard) | yes | both lines survive `reset --hard`; log untracked. Planned guard. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC9 | a55107b | yes | gate silent with warn-log and hand-written log; still flags other.txt; exclude entry once. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC10 | 293ffe9 (guard) | yes | two concurrent checks land both lines; 40 concurrent writers land 40 whole lines. Green c3cb637 (T03; already passes at 2b92c21^). Guard on arrival after a same-ticket green; the test fails on pre-green code and under its Mutation, index ruling 2026-11-24. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC11 | 0e9d225 | yes | `real` with no (F<nn>) named with Fix; `real ... (F02)` not flagged. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC12 | e98ec5e (guard) | yes | missing file and file without the name: delivers blocks through the check, wording and guard-patch print `warn` from `wf mode` (modes-test.sh:26-34); the check's use of `wf mode` is shown by the block cases under US-6.AC2. Green 300c319 (T02); guard on arrival after a same-ticket green (index ruling 2026-11-24). carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC13 | c579269, 3a31088 (guard) | yes | modes-test.sh:46-48 now runs check-red-green.sh with `wording=maybe` and `guard-patch=maybe`: exit 2 and the exact ERROR line with Fix. Re-run by the lead: with check-red-green.sh:85 or :88 changed to fall back to `warn` (the guard's Mutation), modes-test fails `AC13 guard-patch through the check: exit 1, want 2` / `AC13 wording through the check: exit 1, want 2`. Guard on true code (exit 2 already held, measured in the last round) |
| US-6.AC14 | be9eb62 | yes | PASS review, `(fixed in T03)` with T03 done among two done rows (8e1b5c0): exit 0, no check-warning line; fails at a90a613 (measured in the round that added it). carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-6.AC15 | 2911955 | yes | unknown T09 and todo T05 each print the exact fixed-in line with Fix, exit 1; fails at a90a613 (measured in the round that added it). Guard 0cc93c7 adds a no-index case; its Mutation names the `$idx` code that refactor ccdcbd4 replaced, the case still fails closed at HEAD. carried from 2fc7448 (test file unchanged in 2fc7448..HEAD, passes at 72be583) |
| US-3.AC4 | 62f7e89 | yes | wording-test.sh:64-79, direct and variable forms each: SURVIVED line with Fix, no could-not-run, venv python used. Re-run by the lead: the test fails at 62f7e89 (`AC4 [direct] no SURVIVED line`, `printed could-not-run`) and with the old `[^ ]*/python3?` regex restored at HEAD |
Copy: n/a, no Python source in range (`git diff --name-only origin/main...HEAD -- '*.py'` is empty).

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass (rc=0 at 72be583, no FAIL or SKIP line).

Clean checkout (detached worktree at 72be583, no `.worktreeinclude` in the repo, 2 variables from `~/.claude/checks/clean-suite-env` removed with `env -u`): pass (rc=0).

`wf red`: no output (every AC has a red or guard commit).

## Out of Scope

none. `wf scope` lists the same two files as the last round: TODOS.md and skills/build/scripts/test/ac-covered-test.sh. The fix range adds no unplanned file. The F06 change only picks the interpreter, so it reaches no Out of Scope line.

## Structure

`wf size`: none

none.

## Check warnings

none (no docs/work/workflow-speed/check-warnings.log: this branch was built before the checks existed).

## Security

none. The finder ran on base 2fc7448 with the caller instruction. Its `git diff --stat 2fc7448...HEAD` lists the same 8 files as `git diff --name-only`. Source file read: check-red-green.sh (`pytest_cmd` line 42). Callers it opened: `narrowed()` :53 and `wording()` :70, which run the result through `bash -c` at :105/:124/:131 and `mutate-copy -- bash -c` at :72. It also opened callers of the script in build/SKILL.md, test-only-fix.md and wf:361. Test and doc files: all read. Spot-checked caller: check-red-green.sh:70-72 builds `cmd=$(pytest_cmd " -x" "$tests")` and runs `mutate-copy ... -- bash -c "$cmd"`, and :158 already runs the whole Verify with `bash -c "$verify"`, as the report says. The copied interpreter text comes from the same lead-written Verify, so there is no new input. Finder result: NO FINDINGS, so no filter ran.

Safe because: a guard commit's Mutation patch can only write inside the worktree under check; a patch aimed outside it or into `.git/` is refused, and the tree ends clean on its branch. The fix range does not touch that code, so the last round's proof was re-run at 72be583: `bash $TMPDIR/scratchpad/proof.sh` ->

```
../escape.txt -> WARN guard-patch US-1.AC1 42a71c51: Mutation patch does not apply at the guard commit. Fix: ...
.git/hooks/post-checkout -> WARN guard-patch US-1.AC1 9ec9ec72: Mutation patch does not apply at the guard commit. Fix: ...
escape.txt exists: no
hook exists: no
PWNED exists: no
status: [] branch: main
```

## Behaviour

Probe: `bash $TMPDIR/fr-71220/beh/probe.sh <repo>/skills/build/scripts` (BEH below). The finder ran it, and the lead re-ran it at 72be583.

1. skills/build/scripts/check-red-green.sh:43, reported at :80 and :106. State: the ticket's Verify runs its interpreter behind an environment prefix, either `cd pkg && env -u TOKEN "$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" -m pytest ...` or `PY="$(...)/../venv/bin/python3" && DEV_MODE=true $PY -m pytest ...`. The tests pass only under that prefix. F06 now picks out the interpreter, so the narrowed and wording commands run, but `pytest_cmd` builds `cd <root> && <py> -m pytest` without the prefix. The Verify passes by hand. The lead still gets `WARN wording T01: could not run: ... TEST COMMAND fails before any edit ... Fix: keep snapshot and golden tests out ...`, which is false, and its Fix cannot clear it (1a, 1c). On a guard commit the same run prints `FAIL guard ...: verify failed at the guard commit: FAILED ... assert 3 == 2` beside `OK green HEAD` on that same commit, exit 1 (1b). Common: yes. 62 ticket and index files under $HOME/Developer that use the quoted-substitution interpreter put an `env -u` or `NAME=value` prefix before it (lead's grep). Money: no. Base gives a different reply: no wording line at all (Base has no wording check). New AC US-3.AC5, F07. Decided (fable): one AC covering three measured prefix forms (`env -u NAME "$(...)"`, `NAME=value "$(...)"`, `NAME=value OTHER=value $PY`), with a SURVIVED clause and an `OK   guard`/exit 0 clause. Probe output (lead's re-run):

```
--- 1a env -u, red ticket
OK   red US-1.AC1 12984f40: FAILED tests/test_msg.py::test_x - assert 1 == 2
OK   green HEAD f34b5636
WARN wording T01: could not run: mutate-copy: TEST COMMAND fails before any edit; fix that first (run it yourself to see why). Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir.
exit 0
--- 1b env -u, guard commit
FAIL guard US-1.AC2 7f4247ff: verify failed at the guard commit: FAILED tests/test_guard.py::test_g - assert 3 == 2. Fix: a guard must pass on arrival; if the code is missing, make it a red commit and add a green one.
OK   green HEAD 7f4247ff
exit 1
--- 1c PY=... && DEV_MODE=true $PY
OK   red US-1.AC1 f01ed795: FAILED tests/test_msg.py::test_x - assert 1 == 2
OK   green HEAD 0dcfe1bf
WARN wording T01: could not run: mutate-copy: TEST COMMAND fails before any edit; ... Fix: keep snapshot and golden tests out ...
exit 0
```

### Notes

- skills/build/scripts/check-red-green.sh:42-43: a bare `python` in Verify runs as `python3`; where those differ, a red test that already passes gets `OK red ...: No module named pytest` (BEH 2b). older
- skills/build/scripts/check-red-green.sh:42,131: a substitution holding `)` or nested quotes (`"$(dirname "$(git rev-parse ...)")/venv/bin/python3"`) gives a broken interpreter token and a false `OK red` on the syntax error (BEH 3). 0 occurrences measured. older
- skills/build/scripts/check-red-green.sh:42,131: `"$VAR/bin/python3"` keeps the opening quote and gives a false `OK red` on `unexpected end of file` (BEH 4). 0 occurrences measured. older
- skills/build/scripts/check-red-green.sh:115,121: a guard that is not the last commit gets an amend Fix that cannot clear it (carried from 2fc7448). neither
- skills/build/scripts/check-red-green.sh:71,80: a red test file outside `tests/` gives a could-not-run warning that names the ticket id twice (carried from 2fc7448). neither
- skills/build/scripts/wf:492-496: a PASS review with a `real ... (F05)` row naming a ticket missing from the index passes check-review (carried from 2fc7448). neither

## Verify

not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes.

## Fix tickets

F07 The red-green check keeps the Verify's environment prefix: fixes Behaviour 1 (US-3.AC5)

## OPEN

none
