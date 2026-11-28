#!/usr/bin/env bash
# check-red-green-test.sh: a red commit runs only its own test files; one that touches code runs the full
# verify. Needs a python with pytest: `python` on PATH, or the one given as $1. Prints FAIL lines, exit 1 on any.
set -u
s=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
[ -z "${1:-}" ] || { mkdir "$d/bin"; printf '#!/bin/sh\nexec "%s" "$@"\n' "$1" > "$d/bin/python"; chmod +x "$d/bin/python"; PATH=$d/bin:$PATH; }
python -c 'import pytest' 2>/dev/null || { echo "SKIP check-red-green-test: no python with pytest"; exit 0; }
fail=0
export COUNT=$d/count # test_old.py appends a line on every run of the full suite
export PYTHONDONTWRITEBYTECODE=1 # src.py's two versions share size and mtime second: a stale .pyc
check() { # check <name> <extra file the red commit also touches, or ""> <want full-suite runs> [<want FAIL substring>]
  rm -rf "$d/r" "$COUNT"; mkdir -p "$d/r/pkg/tests" "$d/r/pkg/web"; cd "$d/r"; git init -q
  echo 'X = 1' > pkg/src.py
  printf 'import os\ndef test_old():\n    open(os.environ["COUNT"], "a").write("x\\n")\n' > pkg/tests/test_old.py
  git add -A; git commit -qm init; base=$(git rev-parse HEAD)
  printf 'import sys, os\nsys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))\nimport src\ndef test_new():\n    assert src.X == 2\n' > pkg/tests/test_new.py
  [ -z "$2" ] || echo note > "$2"
  git add -A; git commit -qm 'test(US-1.AC1): red'
  echo 'X = 2' > pkg/src.py; git commit -qam 'feat: green'
  out=$("$s/check-red-green.sh" "$d/r" "$base" "cd pkg && python -m pytest -q -p no:cacheprovider" 2>&1); rc=$?
  runs=$(wc -l < "$COUNT" | tr -d ' ')
  if [ -n "${4:-}" ]; then
    if [ $rc != 1 ] || ! grep -F "$4" <<<"$out" | grep -qF ' Fix: '; then
      printf 'FAIL %s: exit %s (want 1, a line with "%s" and " Fix: ")\n%s\n' "$1" $rc "$4" "$out"; fail=1
    fi
  elif [ $rc != 0 ] || ! grep -q '^OK   red US-1.AC1' <<<"$out" || [ "$runs" != "$3" ]; then
    printf 'FAIL %s: exit %s, full-suite runs %s (want %s)\n%s\n' "$1" $rc "$runs" "$3" "$out"; fail=1
  fi
}
check "red runs only its test file"            ""                   1
check "red with a frontend test runs all"      "pkg/web/a.test.ts"  2
check "red touching a non-test file fails"     "pkg/notes.md"       - "FAIL red US-1.AC1"
check "red touching code names the file"       "pkg/helper.py"      - "touches non-test files: pkg/helper.py"
. "$s/test/lib-fixture.sh"
printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf
frozen() { # frozen <repo> : a red commit for tests/ac1.sh, then a green commit that also edits tests/ac1.sh
  fx_repo "$1"; base=$(git -C "$1" rev-parse HEAD)
  fx_commit "$1" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
  sha=$(fx_commit "$1" 'feat(US-1.AC1): green' app.txt 2 tests/ac1.sh 'grep -x 2 app.txt >/dev/null')
  line="FAIL frozen US-1.AC1: ${sha:0:8} \"feat(US-1.AC1): green\" changed tests/ac1.sh after its red commit. Fix:"
}
plan() { # plan <ticket|index> <ruling line or "">: writes $d/feat/plan.md, prints its path
  mkdir -p "$d/feat/tickets"
  if [ "$1" = ticket ]; then
    fx_ticket "$d/feat/tickets/T1-x.md" '- US-1.AC1: a'
    printf '\n## Approach\n%s\n\n## Verify\nx\n' "$2" >> "$d/feat/tickets/T1-x.md"; echo "$d/feat/tickets/T1-x.md"
  else
    printf '# X: build index\n\n| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | doing |\n\n## Parts\n\n- P1: US-1.AC1; files: tests/ac1.sh\n\n## Rulings\n\n%s\n' "$2" > "$d/feat/index.md"; echo "$d/feat/index.md:P1"
  fi
}
rule='Ruling 2026-11-28 (lead): tests/ac1.sh may change: grep no longer checks the file twice'
irule='- 2026-11-28, P1 (direct): tests/ac1.sh may change: grep no longer checks the file twice'
tfix="revert that change to tests/ac1.sh, or add \`Ruling <date> (lead): tests/ac1.sh may change: <what>\` under ## Approach in the ticket $d/feat/tickets/T1-x.md."
ifix="revert that change to tests/ac1.sh, or log \`wf ruling $d/feat/index.md \"P1 (direct): tests/ac1.sh may change: <what>\"\` (a dated line under ## Rulings of the index)."
nfix="revert that change to tests/ac1.sh; a test only changes after red with a ruling line, so pass the ticket, or <index.md>:<part id>, as the 4th argument."
frozen "$d/f1"
out=$("$s/check-red-green.sh" "$d/f1" "$base" "$FX_VERIFY" "$(plan ticket "$rule")"); rc=$?
if [ $rc != 0 ] || ! grep -qxF "OK   frozen US-1.AC1: ${sha:0:8} changed tests/ac1.sh after its red commit, allowed by ruling in $d/feat/tickets/T1-x.md: $rule" <<<"$out" || grep -q '^FAIL' <<<"$out"; then
  printf 'FAIL ticket ruling allows the frozen file: exit %s (want 0 and an OK frozen line naming the ruling)\n%s\n' $rc "$out"; fail=1
fi
out=$("$s/check-red-green.sh" "$d/f1" "$base" "$FX_VERIFY" "$(plan index "$irule")"); rc=$?
if [ $rc != 0 ] || ! grep -qxF "OK   frozen US-1.AC1: ${sha:0:8} changed tests/ac1.sh after its red commit, allowed by ruling in $d/feat/index.md: $irule" <<<"$out" || grep -q '^FAIL' <<<"$out"; then
  printf 'FAIL index ruling allows the frozen file: exit %s (want 0 and an OK frozen line naming the ruling)\n%s\n' $rc "$out"; fail=1
fi
frozen_fails() { # frozen_fails <name> <want fix text> <4th argument>
  out=$("$s/check-red-green.sh" "$d/f1" "$base" "$FX_VERIFY" ${3:+"$3"}); rc=$?
  if [ $rc != 1 ] || ! grep -qxF "$line $2" <<<"$out"; then
    printf 'FAIL %s: exit %s (want 1 and the line "%s %s")\n%s\n' "$1" $rc "$line" "$2" "$out"; fail=1
  fi
}
frozen_fails "ticket without a ruling fails"        "$tfix" "$(plan ticket "")"
frozen_fails "index without a ruling fails"         "$ifix" "$(plan index "")"
frozen_fails "no plan file fails"                   "$nfix"
frozen_fails "ruling for tests/ac1.sh.bak fails"    "$tfix" "$(plan ticket "${rule/ac1.sh/ac1.sh.bak}")"
frozen_fails "ruling for x/tests/ac1.sh fails"      "$tfix" "$(plan ticket "${rule/tests\/ac1.sh/x/tests/ac1.sh}")"
frozen_fails "index ruling for another path fails"  "$ifix" "$(plan index "${irule/ac1.sh/ac1.sh.bak}")"
plan ticket "" >/dev/null; printf '\n## Out of scope\n%s\n' "$rule" >> "$d/feat/tickets/T1-x.md"
frozen_fails "ruling outside Approach fails"        "$tfix" "$d/feat/tickets/T1-x.md"
frozen_fails "ruling prose without Ruling prefix fails" "$tfix" "$(plan ticket "not a $rule")"

pipe_verify="$FX_VERIFY | tail -5"
fx_repo "$d/p1"; base=$(git -C "$d/p1" rev-parse HEAD)
fx_commit "$d/p1" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$d/p1" 'feat(US-1.AC1): green' app.txt 2 >/dev/null
out=$("$s/check-red-green.sh" "$d/p1" "$base" "$pipe_verify"); rc=$?
if [ $rc != 0 ] || ! grep -q '^OK   red US-1.AC1' <<<"$out" || ! grep -q '^OK   green HEAD' <<<"$out"; then
  printf 'FAIL piped verify, red then green: exit %s (want 0, OK red and OK green)\n%s\n' $rc "$out"; fail=1
fi
fx_commit "$d/p1" 'refactor: breaks it' app.txt 3 >/dev/null
out=$("$s/check-red-green.sh" "$d/p1" "$base" "$pipe_verify"); rc=$?
if [ $rc != 1 ] || ! grep -q '^FAIL green HEAD' <<<"$out" || ! grep -q '^OK   red US-1.AC1' <<<"$out"; then
  printf 'FAIL piped verify failing at HEAD: exit %s (want 1, FAIL green and OK red)\n%s\n' $rc "$out"; fail=1
fi
fx_repo "$d/p2"; fx_commit "$d/p2" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails'; echo '```diff'; patch_of "$d/p2" app.txt 3; echo '```'; } > "$d/pb"
mkguard "$d/p2" "$d/pb"
out=$("$s/check-red-green.sh" "$d/p2" "$base" "$pipe_verify"); rc=$?
if [ $rc != 0 ] || ! grep -q "^OK   guard US-1.AC1 ${sha:0:8}: " <<<"$out" || grep -q 'tests still pass' <<<"$out"; then
  printf 'FAIL piped verify with the Mutation patch applied: exit %s (want 0, OK guard, no "tests still pass")\n%s\n' $rc "$out"; fail=1
fi
# every FAIL or ERROR line the script can print names its fix (global CLAUDE.md: checks print how to fix)
nofix=$(grep -nE 'echo "(FAIL|ERROR|WARN)' "$s/check-red-green.sh" | grep -vF ' Fix: ')
[ -z "$nofix" ] || { printf 'FAIL check-red-green.sh lines with no " Fix: ":\n%s\n' "$nofix"; fail=1; }
[ $fail = 0 ] && echo "OK check-red-green-test"; exit $fail
