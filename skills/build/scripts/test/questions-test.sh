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

# an empty section counts as missing
index empty '## Open questions' '' '## Parts'
expect "empty section" 1 "$d/empty.md:12: no \"## Open questions\" section. Fix: list every choice the spec leaves open or contradicts as \"- Q<n>: <question> Answer: <answer>\", send each to the decision agent (skills/build/references/decide.md), and write \"none\" when there are none." questions "$d/empty.md"

# US-2.AC2: a question with no answer
index open '## Open questions' '' '- Q1: which count does the summary show?' '- Q2: which order? Answer: newest first (fable)'
expect "US-2.AC2 unanswered" 1 "$d/open.md:14: Q1 has no answer. Fix: send Q1 to the decision agent (skills/build/references/decide.md) and record its answer on that line as \"Answer: <answer>\"." questions "$d/open.md"

# US-2.AC3: "none", or every question answered
index none '## Open questions' '' 'none' '' '## Parts'
expect "US-2.AC3 none" 0 "" questions "$d/none.md"
index answered '## Open questions' '' '- Q1: which count does the summary show? Answer: the unread count (fable)' '- Q2: which order? Answer: newest first (fable)'
expect "US-2.AC3 all answered" 0 "" questions "$d/answered.md"

[ $fail = 0 ] && echo "OK questions-test"; exit $fail
