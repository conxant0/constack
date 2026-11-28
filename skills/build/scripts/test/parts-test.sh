#!/usr/bin/env bash
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
plan() {
  local p=$d/$1 n=$2 i; shift 2; mkdir -p "$p"
  { printf '# X\n\nStatus: approved\n\n### US-1 x\n\n'; for ((i = 1; i <= n; i++)); do printf -- '- US-1.AC%d: Given a, when b, then c.\n' $i; done; } > "$p/spec.md"
  { printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: b\nBase: origin/main\nTest command: `true`\n\n'
    printf '| Part | Title | Blocked by | Status |\n|---|---|---|---|\n'
    while [ "$1" != -- ]; do printf '%s\n' "$1"; shift; done; shift
    printf '\n## Open questions\n\nnone\n\n## Parts\n\n'; printf '%s\n' "$@"; printf '\n## Rulings\n'; } > "$p/index.md"
}
expect() {
  local name=$1 want_rc=$2 want=$3 out rc; shift 3
  out=$("$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}

plan miss 3 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1; files: a.sh' '- P2: US-1.AC3; files: b.sh'
expect "US-3.AC1 AC in no part" 1 "$d/miss/spec.md:8: US-1.AC2 is in no part. Fix: add it to exactly one part's line under \"## Parts\" in $d/miss/index.md." parts "$d/miss/index.md"
plan ok 3 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1, US-1.AC2; files: a.sh' '- P2: US-1.AC3; files: b.sh, a.sh'
expect "every AC in one part" 0 "" parts "$d/ok/index.md"
plan rows 1 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1; files: a.sh' '- P3: none; files: c.sh'
expect "row and line mismatch" 1 "$d/rows/index.md:11: P2 has a row but no line under \"## Parts\". Fix: add \"- P2: <AC ids>; files: <paths it owns>\", or delete its row.
$d/rows/index.md:20: P3 has a line under \"## Parts\" but no row. Fix: add its row to the table, or delete the line." parts "$d/rows/index.md"

plan dup 2 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1, US-1.AC2; files: a.sh' '- P2: US-1.AC1; files: b.sh'
expect "US-3.AC2 AC under two parts" 1 "$d/dup/index.md:20: US-1.AC1 is listed under P1 and P2. Fix: leave it in one of them." parts "$d/dup/index.md"

acs() { local i l=US-1.AC$1; for ((i = $1 + 1; i <= $2; i++)); do l="$l, US-1.AC$i"; done; printf '%s' "$l"; }
plan big 15 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- "- P1: $(acs 1 14); files: a.sh" '- P2: US-1.AC15; files: b.sh'
expect "US-3.AC3 part with 14 ACs" 1 "$d/big/index.md:19: P1 lists 14 ACs. Fix: split it so no part has more than 13." parts "$d/big/index.md"
plan max 15 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- "- P1: $(acs 1 13); files: a.sh" "- P2: $(acs 14 15); files: b.sh"
expect "part with 13 ACs" 0 "" parts "$d/max/index.md"

plan share 3 '| P1 | a | none | todo |' '| P2 | b | none | todo |' '| P3 | c | P2 | todo |' -- '- P1: US-1.AC1; files: src/a.py, tests/test_a.py' '- P2: US-1.AC2; files: `src/b.py`, src/a.py' '- P3: US-1.AC3; files: src/c.py'
expect "US-3.AC4 shared file, no path" 1 "$d/share/index.md:21: P1 and P2 both list src/a.py, and neither is blocked by the other. Fix: give the file to one part, or order the two (one blocked by the other)." parts "$d/share/index.md"
plan chain 3 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' '| P3 | c | P2 | todo |' -- '- P1: US-1.AC1; files: src/a.py' '- P2: US-1.AC2; files: src/b.py' '- P3: US-1.AC3; files: src/a.py'
expect "shared file on a blocked-by path" 0 "" parts "$d/chain/index.md"

plan next 2 '| P1 | a | none | done abc12345 |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1; files: a.sh' '- P2: US-1.AC2; files: b.sh'
[ ! -e "$d/next/tickets" ] || { echo "FAIL US-3.AC5 fixture has a tickets folder"; fail=1; }
expect "US-3.AC5 frontier on parts" 0 "P2" frontier "$d/next/index.md"
[ $fail = 0 ] && echo "OK parts-test"; exit $fail
