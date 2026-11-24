#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
. "$(cd "$(dirname "$0")" && pwd)/lib-lead.sh"
bad() { echo "FAIL earlier-tests-block-test: $*"; fail=1; }
printf 'earlier-tests=warn\n' > "$d/w.conf"; printf 'earlier-tests=block\n' > "$d/b.conf"

lead "$d/a"; merge_ticket "$d/a" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/a" t2 'feat: T2 code' tests/new.sh 'true')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/a/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/new.sh' <<<"$out" || bad "AC4 warned on a brand-new file: $out"

for kind in rewrite delete; do
  lead "$d/b-$kind"; merge_ticket "$d/b-$kind" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
  git -C "$d/b-$kind" checkout -q -b t2
  if [ $kind = rewrite ]; then printf 'test -f app.txt\nfalse\n' > "$d/b-$kind/tests/t1.sh"; else git -C "$d/b-$kind" rm -q tests/t1.sh; fi
  git -C "$d/b-$kind" add -A; git -C "$d/b-$kind" commit -qm 'test(US-1.AC2): red'; c=$(git -C "$d/b-$kind" rev-parse HEAD)
  git -C "$d/b-$kind" checkout -q main; git -C "$d/b-$kind" merge -q --no-ff t2 -m "merge t2"; m=$(git -C "$d/b-$kind" rev-parse HEAD)
  out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/b-$kind/docs/work/f/index.md" T02 "$m")
  grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} (red or guard) removed or rewrote lines. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC6 [$kind] line: $out"
done

lead "$d/c"; merge_ticket "$d/c" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/c" t2 'test(US-1.AC2): red' tests/t1.sh $'test -f app.txt\ntrue\ntest -s app.txt')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/c/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/t1.sh' <<<"$out" || bad "AC7 warned on an add-only red edit: $out"

lead "$d/e"; merge_ticket "$d/e" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/e" t2 'feat: T2 code' tests/t1.sh 'true'); c=$(git -C "$d/e" rev-parse "$m^2")
idx=$d/e/docs/work/f/index.md
out=$(CHECKS_CONF=$d/b.conf "$wf" done "$idx" T02 "$m"); rc=$?
[ $rc = 1 ] || bad "AC8 exit $rc, want 1"
grep -qxF "FAIL earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: undo the merge (git reset --hard ${m:0:8}^1), wf set $idx T02 \"blocked: earlier tests: tests/t1.sh\", and send this line to the implementer." <<<"$out" || bad "AC8 line: $out"
grep -q '^| T02 | b | T01 | todo |' "$idx" || bad "AC8 recorded done: $(grep '^| T02' "$idx")"
[ "$(git -C "$d/e" rev-parse HEAD)" = "$m" ] || bad "AC8 committed after FAIL"
[ ! -s "$d/e/docs/work/f/check-warnings.log" ] || bad "AC8 logged a FAIL"

lead "$d/g"; merge_ticket "$d/g" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' 'test(US-1.AC2): red' tests/t1b.sh 'test -r app.txt' >/dev/null
m=$(merge_ticket "$d/g" t2 'feat: T2 code' tests/t1.sh 'true' 'feat: T2 more' tests/t1b.sh 'true')
idx=$d/g/docs/work/f/index.md
out=$(CHECKS_CONF=$d/b.conf "$wf" done "$idx" T02 "$m"); rc=$?
[ $rc = 1 ] || bad "AC8 two findings: exit $rc, want 1"
for f in tests/t1.sh tests/t1b.sh; do
  grep -q "^FAIL earlier-tests $f: " <<<"$out" || bad "AC8 two findings: no FAIL line for $f: $out"
done
grep -q '^| T02 | b | T01 | todo |' "$idx" || bad "AC8 two findings: recorded done: $(grep '^| T02' "$idx")"

for where in base t1; do
  lead "$d/h-$where"
  if [ $where = base ]; then f=tests/base.sh; else f=tests/t1.sh; merge_ticket "$d/h-$where" t1 'test(US-1.AC1): red' $f 'test -f app.txt' >/dev/null; fi
  old=$(cat "$d/h-$where/$f")
  m=$(merge_ticket "$d/h-$where" t2 'test(US-2.AC1): red' $f "$old"$'\nA=1; test -r app.txt' 'test(US-2.AC2): red' $f "$old"$'\nA=2; test -r app.txt\ntest -s app.txt')
  out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/h-$where/docs/work/f/index.md" T02 "$m")
  ! grep -q "earlier-tests $f" <<<"$out" || bad "AC9 [$where] warned on a rewrite of T2's own line: $out"
done

lead "$d/dup"
t1=$'t_a() {\n  run a\n  [ "$out" = ok ] || bad\n}\nt_b() {\n  run b\n  [ "$out" = ok ] || bad\n}'
merge_ticket "$d/dup" t1 'test(US-1.AC1): red' tests/t1.sh "$t1" >/dev/null
t2=$'t_a() {\n  run a\n  [ "$out" = ok ] || bad\n}\nt_b() {\n  run b\n}\nt_c() {\n  run c\n}'
m=$(merge_ticket "$d/dup" t2 'test(US-2.AC1): red' tests/t1.sh "$t2")
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/dup/docs/work/f/index.md" T02 "$m")
c=$(git -C "$d/dup" rev-parse "$m^2")
grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} (red or guard) removed or rewrote lines. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC6 [repeated line] removal of one of two identical lines not flagged: $out"

[ $fail = 0 ] && echo "OK earlier-tests-block-test"; exit $fail
