#!/usr/bin/env bash
# parts-test.sh: runs wf parts and wf frontier on /direct indexes (parts, no tickets folder). Prints FAIL lines, exit 1 on any.
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
plan() { # plan <name> <spec AC count> <table rows...> -- <## Parts lines...>: write <name>/spec.md and <name>/index.md
  local p=$d/$1 n=$2 i; shift 2; mkdir -p "$p"
  { printf '# X\n\nStatus: approved\n\n### US-1 x\n\n'; for ((i = 1; i <= n; i++)); do printf -- '- US-1.AC%d: Given a, when b, then c.\n' $i; done; } > "$p/spec.md"
  { printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: b\nBase: origin/main\nTest command: `true`\n\n'
    printf '| Part | Title | Blocked by | Status |\n|---|---|---|---|\n'
    while [ "$1" != -- ]; do printf '%s\n' "$1"; shift; done; shift
    printf '\n## Open questions\n\nnone\n\n## Parts\n\n'; printf '%s\n' "$@"; printf '\n## Rulings\n'; } > "$p/index.md"
}
expect() { # expect <name> <exit> <output> <wf args...>
  local name=$1 want_rc=$2 want=$3 out rc; shift 3
  out=$("$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}

# US-3.AC1: an AC in no part
plan miss 3 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1; files: a.sh' '- P2: US-1.AC3; files: b.sh'
expect "US-3.AC1 AC in no part" 1 "$d/miss/spec.md:8: US-1.AC2 is in no part. Fix: add it to exactly one part's line under \"## Parts\" in $d/miss/index.md." parts "$d/miss/index.md"
plan ok 3 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1, US-1.AC2; files: a.sh' '- P2: US-1.AC3; files: b.sh, a.sh'
expect "every AC in one part" 0 "" parts "$d/ok/index.md"
plan rows 1 '| P1 | a | none | todo |' '| P2 | b | P1 | todo |' -- '- P1: US-1.AC1; files: a.sh' '- P3: none; files: c.sh'
expect "row and line mismatch" 1 "$d/rows/index.md:11: P2 has a row but no line under \"## Parts\". Fix: add \"- P2: <AC ids>; files: <paths it owns>\", or delete its row.
$d/rows/index.md:20: P3 has a line under \"## Parts\" but no row. Fix: add its row to the table, or delete the line." parts "$d/rows/index.md"
[ $fail = 0 ] && echo "OK parts-test"; exit $fail
