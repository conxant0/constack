# T08 Per-ticket wording check, and no ticket means no new lines

Spec: docs/work/workflow-speed/spec.md
Blocked by: T07

## Delivers

- US-3.AC1: Given a ticket that adds a sentence to a module-level string constant in a Python source file, and its red and guard tests still pass with that sentence deleted, when the red-green check runs with that ticket, then it prints on standard output, with its other lines, a warning line naming the sentence as SURVIVED, with a `Fix:` line, and the warning alone does not change the exit status.
- US-3.AC2: Given a ticket whose red and guard tests make the wording check stop with no result (exit 2: a snapshot test fails its one-space probe, or the tests fail before any edit), when the red-green check runs, then it prints a warning saying the wording check could not run, with a `Fix:` line, not a FAIL.
- US-3.AC3: Given a ticket that changes only a comment and a docstring, when the red-green check runs, then it prints no wording line.
- US-2.AC5: Given no ticket argument (the test-only fix prompt's run), when the red-green check runs, then it prints no delivers line and no wording line, writes no warning log, and its other lines and exit status are as they are today.

## Files

- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/references/reviewer.md
- test: skills/build/scripts/test/wording-test.sh

## Interfaces

- Consumes: `check-red-green.sh <worktree> <base-sha> "<verify>" [<ticket.md> [<ticket-start-sha>]]` from T01; `wf mode wording` and the finding line shape from T02; `wf warn-log` from T03
- Consumes: `mutate-copy [--base REF] [--only NAME]... FILE.py... -- TEST COMMAND` from skills/build/scripts/mutate-copy (exit 0 all killed or nothing to check, 1 SURVIVED or bad `--base`, 2 could not run; lines `SURVIVED <path>:<NAME>: <sentence>`)
- Consumes: `fx_ticket` from T01 (skills/build/scripts/test/lib-fixture.sh)
- Produces: per SURVIVED sentence: `WARN wording <path>:<NAME>: SURVIVED <sentence>. Fix: add an assertion on the rule this sentence states to this ticket's test; a sentence that only describes needs none (the ticket reviewer decides).`
- Produces: could not run: `WARN wording <ticket-id>: could not run: <mutate-copy's last output line>. Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir.`
- Both print `FAIL ...` with exit 1 in block mode, and are logged through `wf warn-log` in warn mode.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL wording-test: $*"; fail=1; }`, sources `lib-fixture.sh`, `s=$(cd "$(dirname "$0")/.." && pwd)`, `py=${1:-python3}`; `"$py" -c 'import pytest' 2>/dev/null || { echo "SKIP wording-test: no python with pytest"; exit 0; }`; `export PYTHONDONTWRITEBYTECODE=1`; `printf 'wording=warn\ndelivers=block\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf`; `V="cd pkg && $py -m pytest -q -p no:cacheprovider"`. Helper `pyrepo <dir> <test path> <test body> <new msg.py>`: `git init -q`, user config, `pkg/msg.py` = `X = 1`, `pkg/tests/__init__.py` empty, commit `init` (sets `base`); then writes `<test path>` with `import os, sys; sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))`-style import of `msg` plus `<test body>`, commits `test(US-1.AC1): red`; then writes `<new msg.py>` to `pkg/msg.py`, commits `feat: green` (sets `head`). Ends `[ $fail = 0 ] && echo "OK wording-test"; exit $fail`.

### US-2.AC5 (guard)
File: skills/build/scripts/test/wording-test.sh
```bash
pyrepo "$d/r0" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V"); rc=$?
[ $rc = 0 ] || bad "AC5 exit $rc, want 0: $out"
[ "$(wc -l <<<"$out" | tr -d ' ')" = 2 ] || bad "AC5 want exactly 2 lines: $out"
grep -q "^OK   red US-1.AC1 " <<<"$out" && grep -qxF "OK   green HEAD ${head:0:8}" <<<"$out" || bad "AC5 lines: $out"
! grep -qE ' (delivers|wording) ' <<<"$out" || bad "AC5 printed a delivers or wording line: $out"
[ -z "$(find "$d" -name check-warnings.log)" ] || bad "AC5 wrote a warning log"
```
Mutation to prove it: run the wording check when no ticket is given (use `<base-sha>` as start and a feature dir of `.`); the test fails on the extra line and the log.

### US-3.AC1
File: skills/build/scripts/test/wording-test.sh
```bash
fx_ticket "$d/f1/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 0 ] || bad "AC1 warning changed the exit: $rc: $out"
grep -qxF "WARN wording pkg/msg.py:MSG: SURVIVED Keep it short.. Fix: add an assertion on the rule this sentence states to this ticket's test; a sentence that only describes needs none (the ticket reviewer decides)." <<<"$out" || bad "AC1 line: $out"
grep -q '^OK   red US-1.AC1 ' <<<"$out" && grep -q '^OK   green HEAD ' <<<"$out" || bad "AC1 other lines missing: $out"
grep -qxF 'wording T01 pkg/msg.py:MSG: SURVIVED Keep it short.' "$d/f1/check-warnings.log" || bad "AC1 not logged: $(cat "$d/f1/check-warnings.log" 2>&1)"
! grep -q '^WARN wording T01: could not run' <<<"$out" || bad "AC1 SURVIVED run also printed could-not-run: $out"
# block mode turns it into FAIL and exit 1 (US-6.AC2 for this check)
printf 'wording=block\n' > "$d/wb.conf"
out=$(CHECKS_CONF=$d/wb.conf "$s/check-red-green.sh" "$d/r0" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL wording pkg/msg.py:MSG: SURVIVED ' <<<"$out" || bad "wording block (exit $rc): $out"
# a sentence the ticket's test asserts is killed, not reported
pyrepo "$d/r1" pkg/tests/test_msg.py $'def test_x():\n    assert "short" in msg.MSG\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$V" "$d/f1/tickets/T01-w.md")
! grep -q '^WARN wording' <<<"$out" || bad "AC1 killed sentence printed a wording line: $out"
# a guard commit's test file is part of the wording command
pyrepo "$d/r5" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
printf 'import os, sys\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport msg\ndef test_g():\n    assert "short" in msg.MSG\n' > "$d/r5/pkg/tests/test_guard.py"
git -C "$d/r5" add -A; git -C "$d/r5" commit -qm 'test(US-1.AC1): guard' -m 'Mutation: pkg/msg.py: MSG -> "" -> test_g fails'
out=$("$s/check-red-green.sh" "$d/r5" "$base" "$V" "$d/f1/tickets/T01-w.md")
! grep -q '^WARN wording' <<<"$out" || bad "AC1 guard test file left out of the wording command: $out"
```

### US-3.AC2
File: skills/build/scripts/test/wording-test.sh
```bash
fix=" Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir."
# snapshot: the test pins the exact text, so the one-space probe fails (exit 2)
pyrepo "$d/r2" pkg/tests/test_msg.py $'def test_x():\n    assert msg.MSG == "Keep it short."\n' $'X = 2\nMSG = "Keep it short."\n'
# no tests dir: the red test is outside tests/, so no narrow command exists and the command is `false`
pyrepo "$d/r3" pkg/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
for r in r2 r3; do
  out=$("$s/check-red-green.sh" "$d/$r" "$(git -C "$d/$r" rev-list --max-parents=0 HEAD)" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "AC2 [$r] exit $rc, want 0: $out"
  grep -q "^WARN wording T01: could not run: .*\.$fix\$" <<<"$out" || bad "AC2 [$r] line: $out"
  ! grep -q '^FAIL wording' <<<"$out" || bad "AC2 [$r] printed FAIL: $out"
done
```
(`$fix` holds regex characters `.` and `'`; if the regex trips, split the check into a `^WARN wording T01: could not run: ` grep and a `grep -F "$fix"`.)

### US-3.AC3 (guard)
File: skills/build/scripts/test/wording-test.sh
```bash
pyrepo "$d/r4" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'"""Module docstring that says a rule."""\n# A comment that says a rule.\nX = 2\n'
out=$("$s/check-red-green.sh" "$d/r4" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 0 ] || bad "AC3 exit $rc: $out"
! grep -q 'wording' <<<"$out" || bad "AC3 printed a wording line: $out"
```
Mutation to prove it: print a `WARN wording` could-not-run line whenever the ticket changed any `.py` source, before calling mutate-copy.

## Approach

- Run only with a ticket argument, only after `OK   green`, on the branch at HEAD with a clean tree; mutate-copy restores its own files.
- Sources: `git diff --name-only --diff-filter=AM <ticket-start>..HEAD` ending `.py` and not matching `test_re`. None: no wording line and mutate-copy is not called.
- Tests: the union of `tests/` or `tests_unit/` `test_*.py` files added or changed by red/guard commits in `<ticket-start>..HEAD`. With exactly one package root the command is `"$here/mutate-copy" --base <ticket-start> <sources> -- bash -c "cd <root> && <py> -m pytest -q -x -p no:cacheprovider -p no:xdist <tests>"`, `<py>` picked as `narrowed()` does. No such files or two roots: the command after `--` is `false`; never the full verify.
- Results: exit 0 prints nothing; each `SURVIVED` line gives one wording finding; exit 2, or exit 1 with no `SURVIVED` line, gives the could-not-run finding with mutate-copy's last output line.
- reviewer.md (spec Decisions): the ticket reviewer treats a `wording` SURVIVED line as final review does: a sentence that states a rule a delivered AC carries is a finding, any other is ignored.

## Constraints

- Spec Decisions: the wording check uses the ticket's own red and guard test files as its test command; a `warn` check never stops an AFK run.
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Prose edits follow the writing-for-agents skill.
- macOS bash 3.2.

## Verify

`bash skills/build/scripts/test/wording-test.sh python3 && bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/delivers-test.sh`

## Out of scope

- Final review's wording lane (T12); comments, docstrings and deleted constants.
- Changing mutate-copy.
