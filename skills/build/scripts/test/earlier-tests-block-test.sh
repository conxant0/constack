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

# US-5.AC6
for kind in rewrite delete; do
  lead "$d/b-$kind"; merge_ticket "$d/b-$kind" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
  git -C "$d/b-$kind" checkout -q -b t2
  if [ $kind = rewrite ]; then printf 'test -f app.txt\nfalse\n' > "$d/b-$kind/tests/t1.sh"; else git -C "$d/b-$kind" rm -q tests/t1.sh; fi
  git -C "$d/b-$kind" add -A; git -C "$d/b-$kind" commit -qm 'test(US-1.AC2): red'; c=$(git -C "$d/b-$kind" rev-parse HEAD)
  git -C "$d/b-$kind" checkout -q main; git -C "$d/b-$kind" merge -q --no-ff t2 -m "merge t2"; m=$(git -C "$d/b-$kind" rev-parse HEAD)
  out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/b-$kind/docs/work/f/index.md" T02 "$m")
  grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} (red or guard) removed or rewrote lines. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC6 [$kind] line: $out"
done

# US-5.AC7 (guard)
lead "$d/c"; merge_ticket "$d/c" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/c" t2 'test(US-1.AC2): red' tests/t1.sh $'test -f app.txt\ntrue\ntest -s app.txt')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/c/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/t1.sh' <<<"$out" || bad "AC7 warned on an add-only red edit: $out"

# US-5.AC8
lead "$d/e"; merge_ticket "$d/e" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/e" t2 'feat: T2 code' tests/t1.sh 'true'); c=$(git -C "$d/e" rev-parse "$m^2")
idx=$d/e/docs/work/f/index.md
out=$(CHECKS_CONF=$d/b.conf "$wf" done "$idx" T02 "$m"); rc=$?
[ $rc = 1 ] || bad "AC8 exit $rc, want 1"
grep -qxF "FAIL earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: undo the merge (git reset --hard ${m:0:8}^1), wf set $idx T02 \"blocked: earlier tests: tests/t1.sh\", and send this line to the implementer." <<<"$out" || bad "AC8 line: $out"
grep -q '^| T02 | b | T01 | todo |' "$idx" || bad "AC8 recorded done: $(grep '^| T02' "$idx")"
[ "$(git -C "$d/e" rev-parse HEAD)" = "$m" ] || bad "AC8 committed after FAIL"
[ ! -s "$d/e/docs/work/f/check-warnings.log" ] || bad "AC8 logged a FAIL"

[ $fail = 0 ] && echo "OK earlier-tests-block-test"; exit $fail
