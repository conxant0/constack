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

[ $fail = 0 ] && echo "OK warn-log-test"; exit $fail
