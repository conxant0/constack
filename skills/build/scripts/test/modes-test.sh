#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL modes-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
r=$d/r; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
t=$d/feat/tickets/T01-x.md
fx_ticket "$t" '- US-1.AC1: Given a, when b, then c' '- US-1.AC2: Given a, when b, then c'

fix=' Fix: add the red commit for US-1.AC2 (or a guard with a Mutation patch if the code already does it); a prefactor'"'"'s Delivers says none.'
printf 'delivers=block\n' > "$d/block.conf"
out=$(CHECKS_CONF=$d/block.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 1 ] || bad "AC2 block exit $rc, want 1"
grep -q "^FAIL delivers US-1.AC2: .*\.$fix\$" <<<"$out" || bad "AC2 block line: $out"
! grep -q '^WARN' <<<"$out" || bad "AC2 block printed a WARN: $out"
printf '# comment\n\ndelivers=warn\n' > "$d/warn.conf"
out=$(CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 0 ] || bad "AC2 warn exit $rc, want 0"
grep -q "^WARN delivers US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in .*\.$fix\$" <<<"$out" || bad "AC2 warn line: $out"
! grep -q '^FAIL' <<<"$out" || bad "AC2 warn printed a FAIL: $out"

[ $fail = 0 ] && echo "OK modes-test"; exit $fail
