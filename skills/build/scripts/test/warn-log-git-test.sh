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

f=$L/docs/work/f
"$wf" warn-log "$f" delivers T01 "US-1.AC2: one"
"$wf" warn-log "$f" wording T02 "a.py:X: SURVIVED two"
git -C "$L" checkout -q -b t1; echo 2 > "$L/app.txt"; git -C "$L" commit -qam change
git -C "$L" checkout -q feature/x; git -C "$L" merge -q --no-ff t1 -m "merge T01"
git -C "$L" reset -q --hard HEAD^1
[ "$(cat "$f/check-warnings.log")" = $'delivers T01 US-1.AC2: one\nwording T02 a.py:X: SURVIVED two' ] || bad "AC8 log after reset: $(cat "$f/check-warnings.log" 2>&1)"
[ -z "$(git -C "$L" ls-files "$f/check-warnings.log")" ] || bad "AC8 the log is tracked"

out=$("$wf" gate "$L/docs/work/f/index.md"); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || bad "AC9 gate with a warn-log written log (exit $rc): $out"
[ -z "$(git -C "$L" status --porcelain)" ] || bad "AC9 git status still shows the log: $(git -C "$L" status --porcelain)"
[ "$(grep -cxF check-warnings.log "$(git -C "$L" rev-parse --path-format=absolute --git-common-dir)/info/exclude")" = 1 ] || bad "AC9 ignore entry not exactly once"
M=$d/lead2; git init -q -b feature/x "$M"; git -C "$M" config user.email t@t; git -C "$M" config user.name t
mkdir -p "$M/docs/work/f"; printf 'Branch: feature/x\nBase: main\n' > "$M/docs/work/f/index.md"; git -C "$M" add -A; git -C "$M" commit -qm init
printf 'delivers T01 US-1.AC2: x\n' > "$M/docs/work/f/check-warnings.log"
out=$("$wf" gate "$M/docs/work/f/index.md"); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || bad "AC9 gate with a hand-written log (exit $rc): $out"
echo x > "$M/other.txt"
out=$("$wf" gate "$M/docs/work/f/index.md"); rc=$?
[ $rc = 1 ] && grep -qF "uncommitted changes" <<<"$out" || bad "AC9 gate ignored other.txt (exit $rc): $out"
N=$d/lead3; git init -q -b feature/x "$N"; mkdir -p "$N/docs/work/f"
gN=$(git -C "$N" rev-parse --path-format=absolute --git-common-dir); rm -rf "$gN/info"
"$wf" warn-log "$N/docs/work/f" delivers T01 "US-1.AC2: three"
grep -qxF check-warnings.log "$gN/info/exclude" 2>/dev/null || bad "AC9 no ignore entry when info/ was missing"
[ "$(cat "$N/docs/work/f/check-warnings.log" 2>&1)" = "delivers T01 US-1.AC2: three" ] || bad "AC9 log not written when info/ was missing: $(cat "$N/docs/work/f/check-warnings.log" 2>&1)"

[ $fail = 0 ] && echo "OK warn-log-git-test"; exit $fail
