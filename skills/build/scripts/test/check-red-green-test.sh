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
# every FAIL or ERROR line the script can print names its fix (global CLAUDE.md: checks print how to fix)
nofix=$(grep -nE 'echo "(FAIL|ERROR|WARN)' "$s/check-red-green.sh" | grep -vF ' Fix: ')
[ -z "$nofix" ] || { printf 'FAIL check-red-green.sh lines with no " Fix: ":\n%s\n' "$nofix"; fail=1; }
[ $fail = 0 ] && echo "OK check-red-green-test"; exit $fail
