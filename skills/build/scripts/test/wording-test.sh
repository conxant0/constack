#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL wording-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; . "$(dirname "$0")/lib-py.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
py=${1:-python3}
"$py" -c 'import pytest' 2>/dev/null || { echo "SKIP wording-test: no python with pytest"; exit 0; }
export PYTHONDONTWRITEBYTECODE=1
printf 'wording=warn\ndelivers=block\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf
V="cd pkg && $py -m pytest -q -p no:cacheprovider"

# US-2.AC5: no ticket, no delivers or wording line, no log
pyrepo "$d/r0" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
out=$("$s/check-red-green.sh" "$d/r0" "$base" "$V"); rc=$?
[ $rc = 0 ] || bad "AC5 exit $rc, want 0: $out"
[ "$(wc -l <<<"$out" | tr -d ' ')" = 2 ] || bad "AC5 want exactly 2 lines: $out"
grep -q "^OK   red US-1.AC1 " <<<"$out" && grep -qxF "OK   green HEAD ${head:0:8}" <<<"$out" || bad "AC5 lines: $out"
! grep -qE ' (delivers|wording) ' <<<"$out" || bad "AC5 printed a delivers or wording line: $out"
[ -z "$(find "$d" -name check-warnings.log)" ] || bad "AC5 wrote a warning log"

[ $fail = 0 ] && echo "OK wording-test"; exit $fail
