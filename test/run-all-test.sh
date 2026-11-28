#!/usr/bin/env bash
# run-all-test.sh: a python with no pytest stops run-all.sh and each pytest test with one FAIL line and its Fix. Exit 1 on any FAIL.
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
[ $fail = 0 ] && echo "OK run-all-test"; exit $fail
