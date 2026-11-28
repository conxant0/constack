#!/usr/bin/env bash
# run-all-test.sh: run-all.sh prints one line per script and fails on a non-zero exit or a SKIP line; a python with no pytest stops it and each pytest test with one FAIL line and its Fix. Exit 1 on any FAIL.
set -u
repo=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
printf '#!/bin/sh\nexit 1\n' > "$d/nopy"; chmod +x "$d/nopy"
out=$("$repo/test/run-all.sh" "$d/nopy" 2>&1); rc=$?
want="FAIL run-all: $d/nopy has no pytest. Fix: pass a python that has pytest as the first argument, e.g. test/run-all.sh <venv>/bin/python3."
[ $rc = 1 ] && [ "$out" = "$want" ] || { printf 'FAIL run-all no pytest: exit %s, got:\n%s\nwant:\n%s\n' "$rc" "$out" "$want"; fail=1; }
for t in wording review-lanes-wording check-red-green shipped-modes; do
  out=$(bash "$repo/skills/build/scripts/test/$t-test.sh" "$d/nopy" 2>&1); rc=$?
  py=$d/nopy; [ $t = check-red-green ] && py=python # it puts the argument on PATH as python
  want="FAIL $t-test: $py has no pytest. Fix: pass a python that has pytest as the first argument, e.g. bash $t-test.sh <venv>/bin/python3."
  [ $rc = 1 ] && [ "$out" = "$want" ] || { printf 'FAIL %s no pytest: exit %s, got:\n%s\nwant:\n%s\n' "$t" "$rc" "$out" "$want"; fail=1; }
done
# one line per script: a non-zero exit and a SKIP line both fail the run, each with its Fix
r=$d/r; mkdir -p "$r/test"; cp "$repo/test/run-all.sh" "$repo/test/lint-portable.sh" "$r/test/"
printf '#!/bin/sh\nexit 0\n' > "$d/py"; chmod +x "$d/py"
printf 'echo "FAIL thing broke"; exit 1\n' > "$r/test/a-test.sh"
printf 'echo "SKIP no tool"\n' > "$r/test/b-test.sh"
printf 'echo "OK $1"\n' > "$r/test/c-test.sh"
git -C "$r" init -q; git -C "$r" add -A
out=$("$r/test/run-all.sh" "$d/py" 2>&1); rc=$?
want="ok   test/lint-portable.sh
FAIL test/a-test.sh: exit 1: FAIL thing broke. Fix: run bash test/a-test.sh $d/py and repair what it prints.
FAIL test/b-test.sh: exit 0: SKIP no tool. Fix: run bash test/b-test.sh $d/py and repair what it prints.
ok   test/c-test.sh"
[ $rc = 1 ] && [ "$out" = "$want" ] || { printf 'FAIL run-all lines: exit %s, got:\n%s\nwant:\n%s\n' "$rc" "$out" "$want"; fail=1; }
rm "$r/test/a-test.sh" "$r/test/b-test.sh"
out=$("$r/test/run-all.sh" "$d/py" 2>&1); rc=$?
[ $rc = 0 ] || { printf 'FAIL run-all clean: exit %s\n%s\n' "$rc" "$out"; fail=1; }
[ $fail = 0 ] && echo "OK run-all-test"; exit $fail
