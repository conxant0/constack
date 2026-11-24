#!/usr/bin/env bash
# check-affected-test.sh: runs check-affected against small PR body fixtures. Prints FAIL lines, exit 1 on any.
set -u
c=$(cd "$(dirname "$0")/.." && pwd)/check-affected
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
OPEN='**Open PRs:** #469, #473 into staging: no conflicts (`git merge-tree --write-tree` each).'

body() { # body <name> <review ask> <open line> <rows...>: a PR body whose Other features affected table holds those rows
  local f=$d/$1.md ask=$2 open=$3; shift 3
  { printf '## Summary\nx\n\n**Review ask:** %s\n\n## Merge danger\n**Door:** Two-way.\n**Other features affected:**\n\n' "$ask"
    printf '| Feature | What changes for it | Proof |\n|---|---|---|\n'
    printf '%s\n' "$@"; printf '\n%s\n**Touches:** none.\n' "$open"; } > "$f"
}
expect() { # expect <name> <exit> <output> <body file>
  local name=$1 want_rc=$2 want=$3 out rc
  out=$("$c" "$4" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}

body clean 'is the Step 3 quote change right? Open `quote.py` first.' "$OPEN" \
  '| CSV export | nothing | reads `lead.score` (`export.py:40`); `pytest tests/test_export.py`: 12 passed |' \
  '| Step 3 quote | side effect: one more credit quoted per dropped verdict | `test_quote.py::test_dropped` snapshot diff |' \
  '| MCP `score_leads` | intended: returns the new score field | `test_tools.py`: 8 passed |' \
  '| Slack digest | unknown: no test, needs a Slack token | read `digest.py:88`; `rg x \| wc -l` stays in one cell |'
expect "clean table" 0 "" "$d/clean.md"

body nobody 'naming.' "$OPEN" \
  '| No other features | nothing | `git grep -nw decode_cursor`: 0 outside the diff; 1 on base |'
expect "no other features row" 0 "" "$d/nobody.md"

printf '## Summary\nx\n\n## Merge danger\n**Door:** Two-way.\n%s\n' "$OPEN" > "$d/none.md"
expect "missing section" 1 "$d/none.md: no \"**Other features affected:**\" table. Fix: run /pr step 2's Other features affected pass and put its table under Merge danger." "$d/none.md"

body empty 'x' "$OPEN"
expect "header only" 1 "$d/empty.md: the Other features affected table has no rows. Fix: run /pr step 2's Other features affected pass; every feature outside the spec that uses changed code gets a row, or one No other features row showing the search." "$d/empty.md"

body bad 'x' "$OPEN" '| A | nothing | |' '| B | nothing |' '| C | fine | ran it |' \
  '| D | intended: | ran it |' '| No other features | nothing | read the code |' '| No other features | intended: x | `git grep -nw x`: 0 |'
expect "bad rows" 1 "$d/bad.md:12: \"A\" has no proof. Fix: name the test run, search or snapshot comparison, with its result.
$d/bad.md:13: row needs 3 cells (Feature | What changes for it | Proof), got 2. Fix: write it as | <feature> | <what changes> | <proof> |, escaping a pipe inside a cell as \\|.
$d/bad.md:14: \"fine\" is not one of: nothing, intended: <change>, side effect: <change>, unknown: <why>. Fix: use one of those.
$d/bad.md:15: \"intended:\" says nothing after the colon. Fix: say what changes for the feature, or why it is unknown.
$d/bad.md:16: \"No other features\" without the search that found 0. Fix: put the git grep command and its 0 hits in Proof, and run the same search on the base to show it finds the definition.
$d/bad.md:17: \"No other features\" must say nothing in What changes for it. Fix: write nothing, or replace this row with one row per affected feature." "$d/bad.md"

body ask 'naming.' "$OPEN" '| Step 3 quote | side effect: one more credit | snapshot diff |'
expect "side effect missing from review ask" 1 "$d/ask.md: side effect on \"Step 3 quote\" is not in the Review ask. Fix: name Step 3 quote and its side effect in the **Review ask:** line." "$d/ask.md"

body noopen 'x' '' '| A | nothing | ran it |'
expect "no open PRs line" 1 "$d/noopen.md: no \"**Open PRs:**\" line. Fix: run /pr step 2's open-PR pass and write its result on an **Open PRs:** line under Merge danger." "$d/noopen.md"

body blankopen 'x' '**Open PRs:**' '| A | nothing | ran it |'
expect "blank open PRs line" 1 "$d/blankopen.md: the **Open PRs:** line is empty. Fix: write no conflicts, conflicts: <files> per PR, or none open with the empty gh pr list." "$d/blankopen.md"

# rows past the top six sit in a <details> fold and are checked the same way
body fold 'x' "$OPEN" '| A | nothing | ran it |'
printf '<details><summary>Other features affected: 1 more</summary>\n\n| Feature | What changes for it | Proof |\n|---|---|---|\n| Z | maybe | ran it |\n\n</details>\n' >> "$d/fold.md"
expect "folded rows checked" 1 "$d/fold.md:20: \"maybe\" is not one of: nothing, intended: <change>, side effect: <change>, unknown: <why>. Fix: use one of those." "$d/fold.md"

expect "unreadable" 2 "$d/missing.md: cannot read" "$d/missing.md"

[ $fail = 0 ] && echo "OK check-affected-test"; exit $fail
