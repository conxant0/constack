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

for conf in "$d/missing.conf" "$d/other.conf"; do
  printf 'wording=block\n' > "$d/other.conf"
  out=$(CHECKS_CONF=$conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
  [ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC12 [$conf] delivers did not block (exit $rc): $out"
done
for c in wording guard-patch; do
  [ "$(CHECKS_CONF=$d/missing.conf "$s/wf" mode $c)" = warn ] || bad "AC12 $c default is not warn (no file)"
  [ "$(CHECKS_CONF=$d/other.conf "$s/wf" mode $c)" = "$([ $c = wording ] && echo block || echo warn)" ] || bad "AC12 $c with other.conf"
done
[ "$(CHECKS_CONF=$d/missing.conf "$s/wf" mode delivers)" = block ] || bad "AC12 delivers default is not block"

printf 'delivers=maybe\n' > "$d/bad.conf"
out=$(CHECKS_CONF=$d/bad.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 2 ] || bad "AC13 exit $rc, want 2"
grep -qxF "ERROR $d/bad.conf: delivers=maybe is not warn or block. Fix: set delivers=warn or delivers=block in $d/bad.conf." <<<"$out" || bad "AC13 line: $out"
! grep -q '^FAIL delivers' <<<"$out" || bad "AC13 still ran the check: $out"
for c in wording guard-patch; do
  printf '%s=maybe\n' "$c" > "$d/bad-$c.conf"
  out=$(CHECKS_CONF=$d/bad-$c.conf "$s/wf" mode $c 2>&1); rc=$?
  [ $rc = 2 ] && [ "$out" = "ERROR $d/bad-$c.conf: $c=maybe is not warn or block. Fix: set $c=warn or $c=block in $d/bad-$c.conf." ] || bad "AC13 $c (exit $rc): $out"
  out=$(CHECKS_CONF=$d/bad-$c.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
  [ $rc = 2 ] || bad "AC13 $c through the check: exit $rc, want 2"
  [ "$out" = "ERROR $d/bad-$c.conf: $c=maybe is not warn or block. Fix: set $c=warn or $c=block in $d/bad-$c.conf." ] || bad "AC13 $c through the check printed: $out"
done
for args in foo '' 'delivers extra'; do
  out=$("$s/wf" mode $args 2>&1); rc=$?
  [ $rc = 2 ] && [ "$out" = "usage: wf mode delivers|wording|guard-patch" ] || bad "AC13 usage [wf mode $args] (exit $rc): $out"
done

[ $fail = 0 ] && echo "OK modes-test"; exit $fail
