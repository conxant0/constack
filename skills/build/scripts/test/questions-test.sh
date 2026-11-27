#!/usr/bin/env bash
# questions-test.sh: runs wf questions against small index fixtures. Prints FAIL lines, exit 1 on any.
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
index() { # index <name> <lines after the table...>
  local f=$d/$1.md; shift
  { printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: b\nBase: origin/main\nTest command: `true`\n\n'
    printf '| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | todo |\n\n'
    printf '%s\n' "$@"; printf '\n## Rulings\n'; } > "$f"
}
expect() { # expect <name> <exit> <output> <wf args...>
  local name=$1 want_rc=$2 want=$3 out rc; shift 3
  out=$("$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}

# US-2.AC1: no Open questions section
index nosec '## Parts' '' '- P1: US-1.AC1 | files: a.sh'
expect "US-2.AC1 no section" 1 "$d/nosec.md:1: no \"## Open questions\" section. Fix: list every choice the spec leaves open or contradicts as \"- Q<n>: <question> Answer: <answer>\", send each to the decision agent (skills/build/references/decide.md), and write \"none\" when there are none." questions "$d/nosec.md"
[ $fail = 0 ] && echo "OK questions-test"; exit $fail
