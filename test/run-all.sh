#!/usr/bin/env bash
# run-all.sh <python with pytest>: runs the portability lint and every test script, one line each.
# A script fails on a non-zero exit or any line starting FAIL or SKIP. Exit 1 on any failure.
set -u
py=${1:-python3}
case $py in */*) py=$(cd "$(dirname "$py")" && pwd)/$(basename "$py") ;; esac # absolute before the cd below
cd "$(dirname "$0")/.." || exit 1
"$py" -c 'import pytest' 2>/dev/null || { echo "FAIL run-all: $py has no pytest. Fix: pass a python that has pytest as the first argument, e.g. test/run-all.sh <venv>/bin/python3."; exit 1; }
to=; command -v timeout >/dev/null && to="timeout 600" # stock macOS has no timeout
fail=0
for t in test/lint-portable.sh skills/*/scripts/test/*-test.sh test/*-test.sh; do
  [ -f "$t" ] || continue
  cmd=(bash "$t"); [ "$t" = test/lint-portable.sh ] || cmd+=("$py")
  out=$($to "${cmd[@]}" 2>&1); rc=$?
  first=$(grep -m1 -E '^(FAIL|SKIP)' <<<"$out")
  if [ $rc = 0 ] && [ -z "$first" ]; then echo "ok   $t"; continue; fi
  echo "FAIL $t: exit $rc: ${first:-$(tail -n 1 <<<"$out")}. Fix: run ${cmd[*]} and repair what it prints."
  fail=1
done
exit $fail
