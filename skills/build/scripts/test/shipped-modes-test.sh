#!/usr/bin/env bash
# The shipped checks.conf: delivers blocks; wording, guard-patch and earlier-tests warn.
set -u
unset CHECKS_CONF
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL shipped-modes-test: $*"; fail=1; }
. "$(dirname "$0")/lib-fixture.sh"; . "$(dirname "$0")/lib-py.sh"; . "$(dirname "$0")/lib-lead.sh"
s=$(cd "$(dirname "$0")/.." && pwd)
py=${1:-python3}

# US-6.AC1 (guard)
# delivers blocks
fx_repo "$d/r1"; base=$(git -C "$d/r1" rev-parse HEAD)
fx_commit "$d/r1" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null; fx_commit "$d/r1" 'feat: green' app.txt 2 >/dev/null
fx_ticket "$d/f1/tickets/T01-x.md" '- US-1.AC1: Given a, when b, then c' '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/f1/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "delivers does not block (exit $rc): $out"
# guard patch warns
fx_repo "$d/r2"; base=$(git -C "$d/r2" rev-parse HEAD)
echo 'Mutation: app.txt: 1 -> 3 -> fails' > "$d/b2"; fx_guard "$d/r2" US-1.AC1 tests/g1.sh 'grep -qx 1 app.txt' "$d/b2" >/dev/null
out=$("$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] && grep -q '^WARN guard-patch US-1.AC1 .*: Mutation has no patch\. Fix: ' <<<"$out" || bad "guard-patch does not warn (exit $rc): $out"
# wording warns
if "$py" -c 'import pytest' 2>/dev/null; then
  pyrepo "$d/r3" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
  fx_ticket "$d/f3/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$("$s/check-red-green.sh" "$d/r3" "$base" "cd pkg && $py -m pytest -q -p no:cacheprovider" "$d/f3/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] && grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED ' <<<"$out" || bad "wording does not warn (exit $rc): $out"
else echo "SKIP shipped-modes-test wording: no python with pytest"; fi
# earlier tests warn, and the ticket is recorded done
lead "$d/r4"; merge_ticket "$d/r4" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/r4" t2 'feat: T2 code' tests/t1.sh 'true')
out=$("$s/wf" done "$d/r4/docs/work/f/index.md" T02 "$m"); rc=$?
[ $rc = 0 ] && grep -q '^WARN earlier-tests tests/t1.sh: T02 ' <<<"$out" || bad "earlier-tests does not warn (exit $rc): $out"

[ $fail = 0 ] && echo "OK shipped-modes-test"; exit $fail
