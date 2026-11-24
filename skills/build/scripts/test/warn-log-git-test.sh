#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL warn-log-git-test: $*"; fail=1; }
wf=$(cd "$(dirname "$0")/.." && pwd)/wf

L=$d/lead
git init -q -b feature/x "$L"; git -C "$L" config user.email t@t; git -C "$L" config user.name t
mkdir -p "$L/docs/work/f"; printf 'Branch: feature/x\nBase: main\n' > "$L/docs/work/f/index.md"; echo 1 > "$L/app.txt"
git -C "$L" add -A; git -C "$L" commit -qm init

# US-6.AC8
f=$L/docs/work/f
"$wf" warn-log "$f" delivers T01 "US-1.AC2: one"
"$wf" warn-log "$f" wording T02 "a.py:X: SURVIVED two"
git -C "$L" checkout -q -b t1; echo 2 > "$L/app.txt"; git -C "$L" commit -qam change
git -C "$L" checkout -q feature/x; git -C "$L" merge -q --no-ff t1 -m "merge T01"
git -C "$L" reset -q --hard HEAD^1
[ "$(cat "$f/check-warnings.log")" = $'delivers T01 US-1.AC2: one\nwording T02 a.py:X: SURVIVED two' ] || bad "AC8 log after reset: $(cat "$f/check-warnings.log" 2>&1)"
[ -z "$(git -C "$L" ls-files "$f/check-warnings.log")" ] || bad "AC8 the log is tracked"

[ $fail = 0 ] && echo "OK warn-log-git-test"; exit $fail
