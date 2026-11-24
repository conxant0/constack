#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL wording-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; . "$(dirname "$0")/lib-py.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
py=${1:-python3}
"$py" -c 'import pytest' 2>/dev/null || { echo "SKIP wording-test: no python with pytest"; exit 0; }
export PYTHONDONTWRITEBYTECODE=1
printf 'wording=warn\ndelivers=block\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf
V="cd pkg && $py -m pytest -q -p no:cacheprovider"

# US-2.AC5: no ticket, no delivers or wording line, no log
pyrepo "$d/r0" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V"); rc=$?
[ $rc = 0 ] || bad "AC5 exit $rc, want 0: $out"
[ "$(wc -l <<<"$out" | tr -d ' ')" = 2 ] || bad "AC5 want exactly 2 lines: $out"
grep -q "^OK   red US-1.AC1 " <<<"$out" && grep -qxF "OK   green HEAD ${head:0:8}" <<<"$out" || bad "AC5 lines: $out"
! grep -qE ' (delivers|wording) ' <<<"$out" || bad "AC5 printed a delivers or wording line: $out"
[ -z "$(find "$d" -name check-warnings.log)" ] || bad "AC5 wrote a warning log"

# US-3.AC1: a sentence no red or guard test catches is a WARN wording line, logged, exit unchanged
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

# US-3.AC2: the wording check stops with no result -> a could-not-run warning, not a FAIL
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

# US-3.AC3: a ticket that changes only a comment and a docstring prints no wording line
pyrepo "$d/r4" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'"""Module docstring that says a rule."""\n# A comment that says a rule.\nX = 2\n'
out=$("$s/check-red-green.sh" "$d/r4" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 0 ] || bad "AC3 exit $rc: $out"
! grep -q 'wording' <<<"$out" || bad "AC3 printed a wording line: $out"

[ $fail = 0 ] && echo "OK wording-test"; exit $fail
