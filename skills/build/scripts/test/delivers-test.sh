#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL delivers-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
r=$d/r1; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
head=$(fx_commit "$r" 'feat: green' app.txt 2)
fx_ticket "$d/feat/tickets/T01-x.md" '- US-1.AC1: Given a, when b, then c' '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] || bad "AC1 exit $rc, want 1"
grep -qxF "FAIL delivers US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${base:0:8}..${head:0:8}. Fix: add the red commit for US-1.AC2 (or a guard with a Mutation patch if the code already does it); a prefactor's Delivers says none." <<<"$out" || bad "AC1 line missing: $out"
fl=$(grep -n '^FAIL delivers US-1.AC2: ' <<<"$out" | cut -d: -f1); gl=$(grep -n '^OK   green ' <<<"$out" | cut -d: -f1)
[ -n "$fl" ] && [ -n "$gl" ] && [ "$fl" -lt "$gl" ] || bad "AC1 delivers line not before the green line: $out"
! grep -q 'delivers US-1.AC1' <<<"$out" || bad "AC1 flagged the delivered US-1.AC1"
# an AC named outside ## Delivers is not a promise
printf '\n## Out of scope\n\n- US-9.AC9: Given a, when b, then c\n' >> "$d/feat/tickets/T01-x.md"
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md")
! grep -q 'delivers US-9.AC9' <<<"$out" || bad "AC1 read an AC outside ## Delivers: $out"
# a guard commit satisfies a delivered AC too
r=$d/r1g; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
printf 'grep -qx 2 app.txt\n' > "$r/tests/g2.sh"; git -C "$r" add -A
git -C "$r" commit -qm 'test(US-1.AC2): guard' -m 'Mutation: app.txt: 2 -> 3 -> tests/g2.sh fails'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-1.AC2' <<<"$out" || bad "AC1 guard commit not accepted (exit $rc): $out"
r=$d/r1; base=$(git -C "$r" rev-list --max-parents=0 HEAD)   # the AC2 block reuses r1

for line in 'none' 'none (prefactor: no behaviour change, existing tests stay green)'; do
  fx_ticket "$d/feat2/tickets/T00-p.md" "$line"
  out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat2/tickets/T00-p.md"); rc=$?
  [ $rc = 0 ] || bad "AC2 [$line] exit $rc, want 0"
  ! grep -q ' delivers ' <<<"$out" || bad "AC2 [$line] printed a delivers line: $out"
done

r=$d/r3; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-2.AC7b): red' tests/ac7b.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
fx_ticket "$d/feat3/tickets/T02-l.md" '- US-2.AC7b: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat3/tickets/T02-l.md"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-2.AC7b' <<<"$out" || bad "AC3 lettered red not matched (exit $rc): $out"
# an unlettered red does not stand in for the lettered AC
r=$d/r3b; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-2.AC7): red' tests/ac7.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat3/tickets/T02-l.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-2.AC7b: ' <<<"$out" || bad "AC3 AC7 red accepted for AC7b (exit $rc): $out"

r=$d/r4; fx_repo "$r"; start=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC2): red' tests/ac2.sh 'grep -qx 2 app.txt' >/dev/null
reviewed=$(fx_commit "$r" 'feat: green' app.txt 2)
fx_commit "$r" 'refactor: review fix' other.txt x >/dev/null
fx_ticket "$d/feat4/tickets/T01-f.md" '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$reviewed" "$FX_VERIFY" "$d/feat4/tickets/T01-f.md" "$start"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-1.AC2' <<<"$out" || bad "AC4 with start (exit $rc): $out"
# without the start, the range is reviewed..HEAD and holds no red commit
out=$("$s/check-red-green.sh" "$r" "$reviewed" "$FX_VERIFY" "$d/feat4/tickets/T01-f.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC4 start default is not base (exit $rc): $out"

[ $fail = 0 ] && echo "OK delivers-test"; exit $fail
