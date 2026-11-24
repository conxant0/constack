#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL warn-log-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
printf 'delivers=warn\n' > "$d/warn.conf"; printf 'delivers=block\n' > "$d/block.conf"

mkcase() { # <repo> <ticket path> <AC delivered> <AC missing>: sets base and head
  fx_repo "$1"; base=$(git -C "$1" rev-parse HEAD)
  fx_commit "$1" "test($3): red" tests/ac.sh 'grep -qx 2 app.txt' >/dev/null
  head=$(fx_commit "$1" 'feat: green' app.txt 2)
  fx_ticket "$2" "- $3: Given a, when b, then c" "- $4: Given a, when b, then c"
}

# US-6.AC3
mkcase "$d/r1" "$d/feat/tickets/T01-x.md" US-1.AC1 US-1.AC2
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md" >/dev/null
[ "$(cat "$d/feat/check-warnings.log")" = "delivers T01 US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${base:0:8}..${head:0:8}" ] \
  || bad "AC3 log: $(cat "$d/feat/check-warnings.log" 2>&1)"

# US-6.AC4
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md" >/dev/null
[ "$(wc -l < "$d/feat/check-warnings.log" | tr -d ' ')" = 1 ] || bad "AC4 re-run duplicated: $(cat "$d/feat/check-warnings.log")"
# dedupe is by the exact line: a different warning from the same check and ticket still lands
"$s/wf" warn-log "$d/feat" delivers T01 "US-1.AC3: another warning"
[ "$(wc -l < "$d/feat/check-warnings.log" | tr -d ' ')" = 2 ] || bad "AC4 a different line from the same ticket was dropped: $(cat "$d/feat/check-warnings.log")"

# US-6.AC5
mkcase "$d/r2" "$d/featb/tickets/T01-x.md" US-1.AC1 US-1.AC2
out=$(CHECKS_CONF=$d/block.conf "$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY" "$d/featb/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC5 block run did not FAIL (exit $rc): $out"
[ ! -s "$d/featb/check-warnings.log" ] || bad "AC5 block mode wrote the log: $(cat "$d/featb/check-warnings.log")"

# US-6.AC10
mkcase "$d/r3" "$d/featc/tickets/T01-a.md" US-1.AC1 US-1.AC2; b3=$base h3=$head
mkcase "$d/r4" "$d/featc/tickets/T02-b.md" US-2.AC1 US-2.AC5; b4=$base h4=$head
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r3" "$b3" "$FX_VERIFY" "$d/featc/tickets/T01-a.md" >/dev/null &
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r4" "$b4" "$FX_VERIFY" "$d/featc/tickets/T02-b.md" >/dev/null &
wait
log=$d/featc/check-warnings.log
grep -qxF "delivers T01 US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${b3:0:8}..${h3:0:8}" "$log" || bad "AC10 T01 line missing: $(cat "$log")"
grep -qxF "delivers T02 US-2.AC5: no \"test(US-2.AC5): red\" or guard commit in ${b4:0:8}..${h4:0:8}" "$log" || bad "AC10 T02 line missing: $(cat "$log")"
[ "$(wc -l < "$log" | tr -d ' ')" = 2 ] || bad "AC10 want 2 lines: $(cat "$log")"
# many writers at once, each a different line: every line lands whole
mkdir -p "$d/featd"
for i in $(seq 1 40); do "$s/wf" warn-log "$d/featd" wording "T$i" "x.py:A: line $i" & done; wait
[ "$(wc -l < "$d/featd/check-warnings.log" | tr -d ' ')" = 40 ] || bad "AC10 40 writers: $(wc -l < "$d/featd/check-warnings.log") lines, want 40"
[ "$(sort -u "$d/featd/check-warnings.log" | wc -l | tr -d ' ')" = 40 ] || bad "AC10 40 writers: broken or duplicate lines"
[ "$(grep -c '^wording T[0-9]* x.py:A: line [0-9]*$' "$d/featd/check-warnings.log")" = 40 ] || bad "AC10 40 writers: malformed lines"

[ $fail = 0 ] && echo "OK warn-log-test"; exit $fail
