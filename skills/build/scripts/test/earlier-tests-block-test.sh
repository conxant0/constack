#!/usr/bin/env bash
# wf done's earlier-tests check: red-commit rewrites, brand-new files, and block mode.
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
. "$(cd "$(dirname "$0")" && pwd)/lib-lead.sh"
bad() { echo "FAIL earlier-tests-block-test: $*"; fail=1; }
printf 'earlier-tests=warn\n' > "$d/w.conf"; printf 'earlier-tests=block\n' > "$d/b.conf"

# US-5.AC4 (guard)
lead "$d/a"; merge_ticket "$d/a" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/a" t2 'feat: T2 code' tests/new.sh 'true')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/a/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/new.sh' <<<"$out" || bad "AC4 warned on a brand-new file: $out"

[ $fail = 0 ] && echo "OK earlier-tests-block-test"; exit $fail
