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

# US-5.AC2
for where in ticket index; do
  lead "$d/b-$where"; merge_ticket "$d/b-$where" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
  if [ $where = ticket ]; then echo '- Ruling 2026-11-24 (lead): `tests/t1.sh` may change: one more check' >> "$d/b-$where/docs/work/f/tickets/T02-b.md"
  else "$wf" ruling "$d/b-$where/docs/work/f/index.md" "T02 (lead): tests/t1.sh may change: one more check" >/dev/null; fi
  git -C "$d/b-$where" commit -qam ruling >/dev/null 2>&1
  m=$(merge_ticket "$d/b-$where" t2 'feat: T2 code' tests/t1.sh 'true')
  out=$("$wf" done "$d/b-$where/docs/work/f/index.md" T02 "$m"); rc=$?
  ! grep -q 'earlier-tests tests/t1.sh' <<<"$out" || bad "AC2 [$where] warned despite the ruling: $out"
  [ $rc = 0 ] || bad "AC2 [$where] exit $rc"
  grep -q '^| T02 | b | T01 | done ' "$d/b-$where/docs/work/f/index.md" || bad "AC2 [$where] T02 not done"
done
# a ruling for another path, or for another ticket, does not allow it
lead "$d/b2"; merge_ticket "$d/b2" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
"$wf" ruling "$d/b2/docs/work/f/index.md" "T01 (lead): tests/t1.sh may change: x" >/dev/null
echo '- Ruling 2026-11-24 (lead): tests/t1.sh.bak may change: x' >> "$d/b2/docs/work/f/tickets/T02-b.md"; git -C "$d/b2" commit -qam r
m=$(merge_ticket "$d/b2" t2 'feat: T2 code' tests/t1.sh 'true')
out=$("$wf" done "$d/b2/docs/work/f/index.md" T02 "$m")
grep -q '^WARN earlier-tests tests/t1.sh: T02 ' <<<"$out" || bad "AC2 a non-matching ruling allowed it: $out"

# US-5.AC3
lead "$d/c"
m=$(merge_ticket "$d/c" t2 'feat: T2 code' tests/base.sh 'true')
c=$(git -C "$d/c" rev-parse "$m^2")
out=$("$wf" done "$d/c/docs/work/f/index.md" T02 "$m")
grep -q "^WARN earlier-tests tests/base.sh: T02 commit ${c:0:8} changed it outside a red or guard commit\. Fix: " <<<"$out" || bad "AC3 line: $out"

# US-5.AC5
# the AC1 run above warned; the ticket is still recorded done
grep -q '^| T02 | b | T01 | done ' "$d/a/docs/work/f/index.md" || bad "AC5 T02 not done: $(grep '^| T02' "$d/a/docs/work/f/index.md")"
[ "$(git -C "$d/a" log -1 --format=%s)" = "docs(build): T02 done" ] || bad "AC5 done commit missing"

# US-5.AC1: the ticket's own red or guard commit may change an earlier test file
lead "$d/e"; merge_ticket "$d/e" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/e" t2 'test(US-2.AC1): red' tests/t1.sh 'test -s app.txt' 'test(US-2.AC2): guard' tests/base.sh 'test -r app.txt')
out=$("$wf" done "$d/e/docs/work/f/index.md" T02 "$m")
! grep -q '^WARN earlier-tests' <<<"$out" || bad "AC1 warned on the ticket's own red or guard commit: $out"

# US-5.AC1: two commits changing the same file give one warning and one log line
lead "$d/f"; merge_ticket "$d/f" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/f" t2 'feat: T2 code' tests/t1.sh 'true' 'fix: T2 more' tests/t1.sh 'true; true')
out=$("$wf" done "$d/f/docs/work/f/index.md" T02 "$m")
[ "$(grep -c '^WARN earlier-tests tests/t1.sh: ' <<<"$out")" = 1 ] || bad "AC1 not one warning per file: $out"
[ "$(grep -c '^earlier-tests T02 tests/t1.sh: ' "$d/f/docs/work/f/check-warnings.log")" = 1 ] || bad "AC1 not one log line per file"

# US-5.AC1: a ticket built on main with no merge starts at its "docs(build): T02 doing" commit
lead "$d/g"
git -C "$d/g" checkout -q -b t1; printf 'test -f app.txt\n' > "$d/g/tests/t1.sh"; git -C "$d/g" add -A; git -C "$d/g" commit -qm 'test(US-1.AC1): red'
git -C "$d/g" checkout -q main; git -C "$d/g" merge -q --ff-only t1
"$wf" set "$d/g/docs/work/f/index.md" T02 doing >/dev/null
printf 'true\n' > "$d/g/tests/t1.sh"; git -C "$d/g" commit -qam 'feat: T2 code'
c=$(git -C "$d/g" rev-parse HEAD)
out=$("$wf" done "$d/g/docs/work/f/index.md" T02 "$c")
grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC1 no-merge line: $out"

[ $fail = 0 ] && echo "OK earlier-tests-test"; exit $fail
