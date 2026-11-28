#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL wording-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; . "$(dirname "$0")/lib-py.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
py=${1:-python3}
need_pytest "$py" wording-test
export PYTHONDONTWRITEBYTECODE=1
printf 'wording=warn\ndelivers=block\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf
V="cd pkg && $py -m pytest -q -p no:cacheprovider"

pyrepo "$d/r0" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V"); rc=$?
[ $rc = 0 ] || bad "AC5 exit $rc, want 0: $out"
[ "$(wc -l <<<"$out" | tr -d ' ')" = 2 ] || bad "AC5 want exactly 2 lines: $out"
grep -q "^OK   red US-1.AC1 " <<<"$out" && grep -qxF "OK   green HEAD ${head:0:8}" <<<"$out" || bad "AC5 lines: $out"
! grep -qE ' (delivers|wording) ' <<<"$out" || bad "AC5 printed a delivers or wording line: $out"
[ -z "$(find "$d" -name check-warnings.log)" ] || bad "AC5 wrote a warning log"

fx_ticket "$d/f1/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 0 ] || bad "AC1 warning changed the exit: $rc: $out"
grep -qxF "WARN wording pkg/msg.py:MSG: SURVIVED Keep it short.. Fix: add an assertion on the rule this sentence states to this ticket's test; a sentence that only describes needs none (the ticket reviewer decides)." <<<"$out" || bad "AC1 line: $out"
grep -q '^OK   red US-1.AC1 ' <<<"$out" && grep -q '^OK   green HEAD ' <<<"$out" || bad "AC1 other lines missing: $out"
grep -qxF 'wording T01 pkg/msg.py:MSG: SURVIVED Keep it short.' "$d/f1/check-warnings.log" || bad "AC1 not logged: $(cat "$d/f1/check-warnings.log" 2>&1)"
! grep -q '^WARN wording T01: could not run' <<<"$out" || bad "AC1 SURVIVED run also printed could-not-run: $out"
printf 'wording=block\n' > "$d/wb.conf"
out=$(CHECKS_CONF=$d/wb.conf "$s/check-red-green.sh" "$d/r0" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL wording pkg/msg.py:MSG: SURVIVED ' <<<"$out" || bad "wording block (exit $rc): $out"
pyrepo "$d/r1" pkg/tests/test_msg.py $'def test_x():\n    assert "short" in msg.MSG\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$V" "$d/f1/tickets/T01-w.md")
! grep -q '^WARN wording' <<<"$out" || bad "AC1 killed sentence printed a wording line: $out"
pyrepo "$d/r5" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
printf 'import os, sys\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport msg\ndef test_g():\n    assert "short" in msg.MSG\n' > "$d/r5/pkg/tests/test_guard.py"
git -C "$d/r5" add -A; git -C "$d/r5" commit -qm 'test(US-1.AC1): guard' -m 'Mutation: pkg/msg.py: MSG -> "" -> test_g fails'
out=$("$s/check-red-green.sh" "$d/r5" "$base" "$V" "$d/f1/tickets/T01-w.md")
! grep -q '^WARN wording' <<<"$out" || bad "AC1 guard test file left out of the wording command: $out"
pyrepo "$d/r6" pkg/tests/test_msg.py $'NOTE = "Not copy."\ndef test_x():\n    assert "short" in msg.MSG\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r6" "$base" "$V" "$d/f1/tickets/T01-w.md")
! grep -q '^WARN wording pkg/tests/test_msg.py:NOTE' <<<"$out" || bad "AC1 checked a test file's constant: $out"
pyrepo "$d/r7" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
printf 'import os, sys\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport msg\ndef test_o():\n    assert "short" in msg.MSG\n' > "$d/r7/pkg/tests/test_other.py"
git -C "$d/r7" add -A; git -C "$d/r7" commit -qm 'test: other'
out=$("$s/check-red-green.sh" "$d/r7" "$base" "$V" "$d/f1/tickets/T01-w.md")
grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED ' <<<"$out" || bad "AC1 a test file from a commit that is neither red nor guard joined the wording command. Fix: build the wording test command only from files added or changed in test(<id>): red and guard commits. Output: $out"

fix=" Fix: keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir."
pyrepo "$d/r2" pkg/tests/test_msg.py $'def test_x():\n    assert msg.MSG == "Keep it short."\n' $'X = 2\nMSG = "Keep it short."\n'
pyrepo "$d/r3" pkg/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
for r in r2 r3; do
  out=$("$s/check-red-green.sh" "$d/$r" "$(git -C "$d/$r" rev-list --max-parents=0 HEAD)" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "AC2 [$r] exit $rc, want 0: $out"
  grep -q "^WARN wording T01: could not run: .*\.$fix\$" <<<"$out" || bad "AC2 [$r] line: $out"
  ! grep -q '^FAIL wording' <<<"$out" || bad "AC2 [$r] printed FAIL: $out"
done

pyrepo "$d/r4" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'"""Module docstring that says a rule."""\n# A comment that says a rule.\nX = 2\n'
out=$("$s/check-red-green.sh" "$d/r4" "$base" "$V" "$d/f1/tickets/T01-w.md"); rc=$?
[ $rc = 0 ] || bad "AC3 exit $rc: $out"
! grep -q 'wording' <<<"$out" || bad "AC3 printed a wording line: $out"

real=$(command -v "$py")
for form in direct variable; do
  pyrepo "$d/r8-$form" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
  mkdir -p "$d/r8-$form/venv/bin"
  printf '#!/bin/sh\necho "$*" >> %q\nexec %q "$@"\n' "$d/used-$form" "$real" > "$d/r8-$form/venv/bin/python3"
  chmod +x "$d/r8-$form/venv/bin/python3"
  sub='"$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3"'
  if [ $form = direct ]; then V8="cd pkg && $sub -m pytest -q -p no:cacheprovider"
  else V8="cd pkg && PY=$sub && \$PY -m pytest -q -p no:cacheprovider"; fi
  fx_ticket "$d/f8-$form/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$("$s/check-red-green.sh" "$d/r8-$form" "$base" "$V8" "$d/f8-$form/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "AC4 [$form] exit $rc: $out"
  grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED Keep it short\.\. Fix: ' <<<"$out" || bad "AC4 [$form] no SURVIVED line: $out"
  ! grep -q 'could not run' <<<"$out" || bad "AC4 [$form] printed could-not-run: $out"
  grep -q 'no:xdist' "$d/used-$form" || bad "AC4 [$form] venv python not used by the wording run"
done

for form in envu assign pyvar; do
  case $form in
    envu)   V9="cd pkg && env -u TOKEN $sub -m pytest -q -p no:cacheprovider"
            x='X = 2 if "TOKEN" not in os.environ else 3' ;;
    assign) V9="cd pkg && DEV_MODE=true $sub -m pytest -q -p no:cacheprovider"
            x='X = 2 if os.environ.get("DEV_MODE") == "true" else 3' ;;
    pyvar)  V9="cd pkg && PY=$sub && DEV_MODE=true OTHER=1 \$PY -m pytest -q -p no:cacheprovider"
            x='X = 2 if os.environ.get("DEV_MODE") == "true" and os.environ.get("OTHER") == "1" else 3' ;;
  esac
  pyrepo "$d/r9-$form" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' "import os
$x
MSG = \"Keep it short.\"
"
  mkdir -p "$d/r9-$form/venv/bin"; printf '#!/bin/sh\nexec %q "$@"\n' "$real" > "$d/r9-$form/venv/bin/python3"; chmod +x "$d/r9-$form/venv/bin/python3"; echo venv/ >> "$d/r9-$form/.git/info/exclude"
  fx_ticket "$d/f9-$form/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$(TOKEN=1 "$s/check-red-green.sh" "$d/r9-$form" "$base" "$V9" "$d/f9-$form/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "US-3.AC5 [$form] wording exit $rc: $out"
  grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED Keep it short\.\. Fix: ' <<<"$out" || bad "US-3.AC5 [$form] no SURVIVED line: $out"
  ! grep -q 'could not run' <<<"$out" || bad "US-3.AC5 [$form] printed could-not-run: $out"

  g=$d/r9-$form; gb=$(git -C "$g" rev-parse HEAD)
  printf 'import os, sys\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport msg\ndef test_g():\n    assert msg.X == 2\n' > "$g/pkg/tests/test_guard.py"
  sed -i.bak 's/^X = .*/X = 0/' "$g/pkg/msg.py"; rm "$g/pkg/msg.py.bak"
  patch=$(git -C "$g" diff -- pkg/msg.py); git -C "$g" checkout -q -- pkg/msg.py
  git -C "$g" add -A
  printf 'test(US-1.AC2): guard\n\nMutation: pkg/msg.py X -> 0 -> test_g fails\n\n```diff\n%s\n```\n' "$patch" | git -C "$g" commit -q --cleanup=verbatim -F -
  out=$(TOKEN=1 "$s/check-red-green.sh" "$g" "$gb" "$V9"); rc=$?
  [ $rc = 0 ] || bad "US-3.AC5 [$form] guard exit $rc: $out"
  grep -q '^OK   guard US-1.AC2 ' <<<"$out" || bad "US-3.AC5 [$form] no OK guard line: $out"
  ! grep -q '^FAIL guard' <<<"$out" || bad "US-3.AC5 [$form] printed FAIL guard: $out"
done

[ $fail = 0 ] && echo "OK wording-test"; exit $fail
