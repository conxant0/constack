#!/usr/bin/env bash
# wf done's earlier-tests check: a ticket that changes an earlier ticket's or Base's test file outside a red or guard commit gets a warning.
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL earlier-tests-test: $*"; fail=1; }
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
printf 'earlier-tests=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf
. "$(cd "$(dirname "$0")" && pwd)/lib-lead.sh"

# US-5.AC1
lead "$d/a"; merge_ticket "$d/a" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/a" t2 'feat: T2 code' tests/t1.sh 'true')
c=$(git -C "$d/a" rev-parse "$m^2")
out=$("$wf" done "$d/a/docs/work/f/index.md" T02 "$m"); rc=$?
[ $rc = 0 ] || bad "AC1 exit $rc"
grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC1 line: $out"
grep -qxF "earlier-tests T02 tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit" "$d/a/docs/work/f/check-warnings.log" || bad "AC1 not logged"

[ $fail = 0 ] && echo "OK earlier-tests-test"; exit $fail
