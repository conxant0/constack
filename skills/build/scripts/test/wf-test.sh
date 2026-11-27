#!/usr/bin/env bash
# wf-test.sh: runs wf against small index fixtures. Prints FAIL lines, exit 1 on any.
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0

index() { # index <name> <rows...>: write a minimal index.md with those table rows
  local f=$d/$1.md; shift
  { printf '# X: build index\n\nBranch: b\nBase: origin/main\nTest command: `true`\n\n'
    printf '| Ticket | Title | Blocked by | Status |\n|---|---|---|---|\n'
    printf '%s\n' "$@"; printf '\n## Rulings\n'; } > "$f"
}
expect() { # expect <name> <exit> <output> <wf args...>
  local name=$1 want_rc=$2 want=$3 out rc; shift 3
  out=$("$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}

index mixed '| T01 | a | none | done abc123 |' '| T02 | b | T01 | todo |' \
  '| T03 | c | T01, T02 | todo |' '| T04 | d `x` | none | todo |' '| F01 | e | none | doing |'
expect "runnable after done blockers" 0 $'T02\nT04' frontier "$d/mixed.md"

index alldone '| T01 | a | none | done abc |' '| T02 | b | T01 | done def |'
expect "all done" 0 "all done" frontier "$d/alldone.md"

index stuck '| T01 | a | none | blocked: review |' '| T02 | b | T01 | todo |'
expect "stuck" 1 $'T01 blocked: review\nT02 todo' frontier "$d/stuck.md"

index unknown '| T01 | a | T09 | todo |'
expect "unknown blocker" 2 "$d/unknown.md:9: T01 blocked by unknown ticket T09" frontier "$d/unknown.md"

index empty
expect "no rows" 2 "$d/empty.md: no ticket rows" frontier "$d/empty.md"

# join shape: T05 heads a new chain because its blockers sit in two chains
index split '| T01 | a | none | todo |' '| T02 | b | T01 | todo |' '| T03 | c | none | todo |' \
  '| T04 | d | T03 | todo |' '| T05 | e | T02, T04 | todo |' '| T06 | f | T05 | todo |' '| F01 | g | none | todo |'
expect "chains split at a join" 0 $'Chain: T01 > T02\nChain: T03 > T04\nChain: T05 > T06' chains "$d/split.md"

# fan shape: T01 feeds two tickets so it stays out; T05/T06 have two blockers, both in the chain
index fan '| T01 | a | none | todo |' '| T02 | b | T01 | todo |' '| T03 | c | T02 | todo |' \
  '| T04 | d | T03 | todo |' '| T05 | e | T03, T04 | todo |' '| T06 | f | T04, T05 | todo |' \
  '| T07 | g | T06 | todo |' '| T08 | h | T01 | todo |' '| T09 | i | T08 | todo |' '| T10 | j | T07, T09 | todo |'
expect "chains with in-chain joins" 0 $'Chain: T02 > T03 > T04 > T05 > T06 > T07\nChain: T08 > T09' chains "$d/fan.md"

# a middle ticket with a dependent outside the chain ends it there
index leak '| T01 | a | none | todo |' '| T02 | b | T01 | todo |' '| T03 | c | T02 | todo |' \
  '| T04 | d | T02, T05 | todo |' '| T05 | e | none | todo |'
expect "chain cut at outside dependent" 0 "Chain: T01 > T02" chains "$d/leak.md"

expect "chains unknown blocker" 2 "$d/unknown.md:9: T01 blocked by unknown ticket T09" chains "$d/unknown.md"

# set / done / ruling edit the index and commit only it
r=$d/repo; git init -q "$r"; git -C "$r" config user.email t@t; git -C "$r" config user.name t
index ledger '| T01 | a | none | todo |' '| T02 | b `x|y` | T01 | todo |'
cp "$d/ledger.md" "$r/index.md"; echo dirty > "$r/other"; git -C "$r" add . ; git -C "$r" commit -qm init
echo more >> "$r/other"
check() { # check <name> <want>: compare <want> with the last line of a command's output
  [ "$2" = "$3" ] || { printf 'FAIL %s: got %s, want %s\n' "$1" "$2" "$3"; fail=1; }
}
expect "set doing" 0 "" set "$r/index.md" T01 doing
check "set row" "$(grep '^| T01' "$r/index.md")" "| T01 | a | none | doing |"
check "set commit" "$(git -C "$r" log -1 --format=%s)" "docs(build): T01 doing"
check "other file left alone" "$(git -C "$r" status --porcelain)" " M other"
sha=$(git -C "$r" rev-parse HEAD)
expect "done" 0 "" done "$r/index.md" T02 "$sha"
check "done row (pipe in title)" "$(grep '^| T02' "$r/index.md")" "| T02 | b \`x|y\` | T01 | done ${sha:0:8} |"
check "done commit" "$(git -C "$r" log -1 --format=%s)" "docs(build): T02 done"
expect "ruling" 0 "" ruling "$r/index.md" "T01: kept, because"
check "ruling line" "$(tail -n 1 "$r/index.md")" "- $(date +%F), T01: kept, because"
expect "bad status" 2 "bad status: finished (todo, doing, blocked: <reason>; use wf done for done)" set "$r/index.md" T01 finished
expect "unknown id" 2 "$r/index.md: no ticket T09" set "$r/index.md" T09 doing
expect "bad sha" 2 "not a commit: deadbeef" done "$r/index.md" T01 deadbeef

# check-plan: a clean plan, then one broken copy per rule
plan() { # plan <dir>: spec with 2 ACs; index with T01, T02 (blocked by T01); a ticket file each
  mkdir -p "$1/tickets"
  printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: b\nBase: origin/main\nTest command: `true`\n\n| Ticket | Title | Blocked by | Status |\n|---|---|---|---|\n| T01 | a | none | todo |\n| T02 | b | T01 | todo |\n\n## Rulings\n' > "$1/index.md"
  printf '# Spec\n\n- US-1.AC1: Given a, when b, then c.\n- US-1.AC2b: Given d, when e, then f.\n' > "$1/spec.md"
  ticket "$1/tickets/T01-t.md" none US-1.AC1 'Given a, when b, then c.'
  ticket "$1/tickets/T02-t.md" T01 US-1.AC2b 'Given d, when e, then f.'
}
ticket() { # ticket <file> <blocked by> <ac id> <ac text>
  { printf '# T t\n\nSpec: docs/work/x/spec.md\nBlocked by: %s\n\n' "$2"
    printf '## Delivers\n\n- %s: %s\n\n## Files\n\n- modify: `src/shared.py`\n\n## Interfaces\n\n- x\n\n## Tests\n\n### %s\nFile: t.py\n\n' "$3" "$4" "$3"
    for s in Approach Constraints Verify "Out of scope"; do printf '## %s\n\n- x\n\n' "$s"; done; } > "$1"
}
broken() { # broken <name> <file under the plan> <sed script>: a plan copy with one edit
  plan "$d/$1"; sed -i '' "$3" "$d/$1/$2"
}
plan "$d/good"
expect "check-plan clean" 0 "" check-plan "$d/good/index.md"
broken nobranch index.md '/^Branch:/d'
expect "missing Branch" 1 "$d/nobranch/index.md:1: missing \"Branch:\" line" check-plan "$d/nobranch/index.md"
broken cycle index.md 's/| T01 | a | none |/| T01 | a | T02 |/'
expect "cycle" 1 "$d/cycle/index.md:11: blocked-by cycle through T02 and T01
$d/cycle/tickets/T01-t.md:4: Blocked by none, index says T02" check-plan "$d/cycle/index.md"
broken unknown2 index.md 's/| T02 | b | T01 |/| T02 | b | T01, T07 |/'
expect "unknown blocker (plan)" 1 "$d/unknown2/index.md:11: T02 blocked by unknown ticket T07
$d/unknown2/tickets/T02-t.md:4: Blocked by T01, index says T01,T07" check-plan "$d/unknown2/index.md"
broken dup index.md 's/| T02 | b |/| T01 | b |/'
expect "duplicate id" 1 "$d/dup/index.md:11: ticket T01 listed twice
$d/dup/index.md:11: blocked-by cycle through T01 and T01
$d/dup/tickets/T01-t.md:4: Blocked by none, index says T01
$d/dup/tickets/T02-t.md:12: T02 shares src/shared.py with T01, but neither is blocked by the other
$d/dup/tickets/T02-t.md:1: T02 is not in the index table" check-plan "$d/dup/index.md"
broken nosec tickets/T02-t.md '/^## Approach/d'
expect "missing section" 1 "$d/nosec/tickets/T02-t.md:1: missing section \"## Approach\"" check-plan "$d/nosec/index.md"
broken emptysec tickets/T01-t.md '/^## Verify/{n;n;d;}'
expect "empty section" 1 "$d/emptysec/tickets/T01-t.md:31: section \"## Verify\" is empty" check-plan "$d/emptysec/index.md"
broken nospec tickets/T01-t.md '/^Spec:/d'
expect "ticket missing Spec" 1 "$d/nospec/tickets/T01-t.md:1: missing \"Spec:\" line" check-plan "$d/nospec/index.md"
broken drift tickets/T01-t.md 's/then c\./then C./'
expect "drift and missing" 1 "$d/drift/tickets/T01-t.md:8: DRIFT: AC line not in spec.md word for word
$d/drift/spec.md:3: MISSING: AC in no ticket's Delivers" check-plan "$d/drift/index.md"
broken notest tickets/T02-t.md 's/^### US-1.AC2b$/### US-1.AC2/'
expect "AC without a test heading" 1 "$d/notest/tickets/T02-t.md:8: US-1.AC2b has no ### Tests heading naming it" check-plan "$d/notest/index.md"
broken prefix tickets/T01-t.md 's/^### US-1.AC1$/### US-1.AC10/'
expect "AC10 heading does not cover AC1" 1 "$d/prefix/tickets/T01-t.md:8: US-1.AC1 has no ### Tests heading naming it" check-plan "$d/prefix/index.md"
broken overlap index.md 's/| T02 | b | T01 |/| T02 | b | none |/'; sed -i '' 's/^Blocked by: T01/Blocked by: none/' "$d/overlap/tickets/T02-t.md"
expect "shared file, no edge" 1 "$d/overlap/tickets/T02-t.md:12: T02 shares src/shared.py with T01, but neither is blocked by the other" check-plan "$d/overlap/index.md"
sed -i '' 's/| T01 | a | none | todo |/| T01 | a | none | done abc |/' "$d/overlap/index.md"
expect "shared file with a done ticket" 0 "" check-plan "$d/overlap/index.md"
plan "$d/big"; five=$'- US-1.AC3: Given g, when h, then i.\\\n- US-1.AC4: Given g, when h, then j.\\\n- US-1.AC5: Given g, when h, then k.\\\n- US-1.AC6: Given g, when h, then l.'
sed -i '' "/^- US-1.AC1:/a\\
$five
" "$d/big/tickets/T01-t.md" "$d/big/spec.md"
sed -i '' 's/^### US-1.AC1$/### US-1.AC1, US-1.AC3, US-1.AC4, US-1.AC5, US-1.AC6/' "$d/big/tickets/T01-t.md"
expect "five ACs in one ticket" 1 "$d/big/tickets/T01-t.md:8: T01 delivers 5 ACs, max 4: split it (red-green runs Verify once per AC)" check-plan "$d/big/index.md"
sed -i '' 's/| T01 | a | none | todo |/| T01 | a | none | done abc |/' "$d/big/index.md"
expect "five ACs in a done ticket" 0 "" check-plan "$d/big/index.md"
plan "$d/nofile"; rm "$d/nofile/tickets/T02-t.md"
expect "row without ticket file" 1 "$d/nofile/index.md:11: T02 has no ticket file tickets/T02-*.md
$d/nofile/spec.md:4: MISSING: AC in no ticket's Delivers" check-plan "$d/nofile/index.md"

# every blocked-by edge needs a reason the script can see: Consumes names the blocker, or a shared non-test Files entry
noreason="T02 is blocked by T01 with no stated reason. Fix: name what T02 Consumes from T01 (a ticket that runs last writes '- Consumes: the merged work of T01 (runs last: <why>)'), or add the same '- shares: <table|route|config>:<name>' line to both tickets' Files, or drop T01 from T02's Blocked by (index and ticket)."
broken bare tickets/T02-t.md 's#src/shared.py#src/other.py#'
expect "edge with no reason" 1 "$d/bare/tickets/T02-t.md:4: $noreason" check-plan "$d/bare/index.md"
broken iface tickets/T02-t.md 's#src/shared.py#src/other.py#; s#^- x$#- Consumes: `f() -> int` from T01#'
expect "edge justified by Consumes" 0 "" check-plan "$d/iface/index.md"
broken produces tickets/T02-t.md 's#src/shared.py#src/other.py#; /^## Interfaces/{n;n;s#^- x$#- Consumes: `g()` from src/g.py\
- Produces: `f()`, used later by T01#;}'
expect "a Produces line naming the blocker is no reason" 1 "$d/produces/tickets/T02-t.md:4: $noreason" check-plan "$d/produces/index.md"
broken tenth tickets/T02-t.md 's#src/shared.py#src/other.py#; s#^- x$#- Consumes: `f()` from T010#'
expect "T010 does not name T01" 1 "$d/tenth/tickets/T02-t.md:4: $noreason" check-plan "$d/tenth/index.md"
broken shares tickets/T02-t.md 's#src/shared.py#src/other.py#; /^- modify:/a\
- shares: table:saved_searches'
sed -i '' '/^- modify:/a\
- shares: `table:saved_searches` (rows T02 deletes)' "$d/shares/tickets/T01-t.md"
expect "edge justified by a shares line" 0 "" check-plan "$d/shares/index.md"
expect "waves names a shares edge" 0 "Waves: 2
Longest path: T01 > T02 (shares table:saved_searches)
Wave 1: T01
Wave 2: T02" waves "$d/shares/index.md"
broken testonly tickets/T02-t.md 's#src/shared.py#src/other.py#; /^- modify:/a\
- test: `tests/test_saved.py` (add one test)'
sed -i '' '/^- modify:/a\
- test: `tests/test_saved.py`' "$d/testonly/tickets/T01-t.md"
expect "a shared test file is no reason" 1 "$d/testonly/tickets/T02-t.md:4: T02 is blocked by T01 only because both add tests to tests/test_saved.py. Fix: give T02 its own new test file, then drop T01 from T02's Blocked by (index and ticket)." check-plan "$d/testonly/index.md"
sed -i '' 's#^- test: `tests/test_saved.py`$#- modify: `tests/test_saved.py` (one pin changes)#' "$d/testonly/tickets/T01-t.md"
expect "a test file one ticket modifies is a reason" 0 "" check-plan "$d/testonly/index.md"
broken prose tickets/T02-t.md 's#- modify: `src/shared.py`#- modify, only if a limit is crossed: src/a.py, `src/shared.py` (one line).#'
expect "a path later in a prose Files line is a reason" 0 "" check-plan "$d/prose/index.md"
broken sweep tickets/T02-t.md 's#src/shared.py#src/other.py#; s#^- x$#- Consumes: the merged work of T01 (runs last: full suite and CHANGELOG)#'
expect "a run-last ticket names its blockers in Consumes" 0 "" check-plan "$d/sweep/index.md"
sed -i '' 's/| T01 | a | none | todo |/| T01 | a | none | done abc |/' "$d/bare/index.md"
expect "edge to a done ticket needs no reason" 0 "" check-plan "$d/bare/index.md"
# a Consumes line wf cannot read: the shared file still gives a reason, so only the format line prints
consumesfix="a Consumes line needs a colon right after \"Consumes\", or wf cannot read which ticket it names. Fix: write it as '- Consumes: <signature> from T0n (<path>)'."
broken consfrom tickets/T02-t.md 's#^- x$#- Consumes from T01 (`src/shared.py`): `f() -> int`#'
expect "Consumes without a colon" 1 "$d/consfrom/tickets/T02-t.md:16: $consumesfix" check-plan "$d/consfrom/index.md"
broken consbare tickets/T02-t.md 's#^- x$#- Consumes#'
expect "a bare Consumes" 1 "$d/consbare/tickets/T02-t.md:16: $consumesfix" check-plan "$d/consbare/index.md"
sed -i '' 's/| T02 | b | T01 | todo |/| T02 | b | T01 | done abc |/' "$d/consfrom/index.md"
expect "Consumes format in a done ticket is not checked" 0 "" check-plan "$d/consfrom/index.md"

# waves: count, the longest path with each edge's kind, one line per wave, a note past 5 at once
plan "$d/w"
for t in T03 T04; do ticket "$d/w/tickets/$t-t.md" none US-1.AC1 'Given a, when b, then c.'; done
sed -i '' 's#src/shared.py#src/three.py#' "$d/w/tickets/T03-t.md"
sed -i '' 's#src/shared.py#src/four.py#; s#^Blocked by: none#Blocked by: T02, T03#; s#^- x$#- Consumes: `h()` from T03#' "$d/w/tickets/T04-t.md"
sed -i '' 's/^| T02 | b | T01 | todo |$/&\
| T03 | c | none | todo |\
| T04 | d | T02, T03 | todo |/' "$d/w/index.md"
expect "waves" 0 "Waves: 3
Longest path: T01 > T02 (file src/shared.py) > T04 (no reason)
Wave 1: T01 T03
Wave 2: T02
Wave 3: T04" waves "$d/w/index.md"
index wide '| T01 | a | none | todo |' '| T02 | b | none | todo |' '| T03 | c | none | todo |' \
  '| T04 | d | none | todo |' '| T05 | e | none | todo |' '| T06 | f | none | todo |' '| T07 | g | T01 | todo |'
expect "waves past five at once" 0 "Waves: 2
Longest path: T01 > T07 (no ticket file)
Wave 1: T01 T02 T03 T04 T05 T06
Wave 2: T07
Note: wave 1 has 6 tickets and /build runs at most 5 at once, so 1 waits for a free slot." waves "$d/wide.md"
expect "waves unknown blocker" 2 "$d/unknown.md:9: T01 blocked by unknown ticket T09" waves "$d/unknown.md"
index loop '| T01 | a | T02 | todo |' '| T02 | b | T01 | todo |'
expect "waves cycle" 2 "$d/loop.md: blocked-by cycle through T01. Fix: run wf check-plan and break the cycle." waves "$d/loop.md"

# check-spec: a clean spec, then one broken copy per rule
spec() { # spec <name> [sed script]
  printf '# X\n\nStatus: approved\nBranch: b\nBase: origin/main\nDate: 2026-10-26\n\n## User stories\n\n### US-1 One\n\n- US-1.AC1: Given a, when b, then c.\n- US-1.AC1b: Given a, when b, then d.\n- US-1.AC2: Given a, when b, then e.\n\n### US-2 Two\n\n- US-2.AC1: Given a, when b, then the docs/work index updates.\n\n## Out of Scope\n\n- y (later)\n\n## Manual check\n\n1. z\n' > "$d/$1.md"
  [ -z "${2:-}" ] || sed -i '' "$2" "$d/$1.md"
}
spec sgood
expect "check-spec clean" 0 "" check-spec "$d/sgood.md"
spec snostatus '/^Status:/d'
expect "spec missing Status" 1 "$d/snostatus.md:1: missing \"Status: draft|approved\" line" check-spec "$d/snostatus.md"
spec sorder 's/US-1.AC2:/US-1.AC3:/'
expect "AC out of order" 1 "$d/sorder.md:14: US-1.AC3 out of order, want AC2 here" check-spec "$d/sorder.md"
spec sstory 's/### US-2 Two/### US-3 Two/;s/US-2.AC1/US-3.AC1/'
expect "story out of order" 1 "$d/sstory.md:16: US-3 out of order, want US-2 here" check-spec "$d/sstory.md"
spec sgwt 's/Given a, when b, then e/When b, then e/'
expect "AC not Given/when/then" 1 "$d/sgwt.md:14: US-1.AC2 is not Given / when / then" check-spec "$d/sgwt.md"
spec sopen 's/^- y (later)/- OPEN: which y?/'
expect "OPEN when approved" 1 "$d/sopen.md:22: OPEN: in an approved spec" check-spec "$d/sopen.md"
spec sdraft 's/^- y (later)/- OPEN: which y?/;s/Status: approved/Status: draft/'
expect "OPEN fine in a draft" 0 "" check-spec "$d/sdraft.md"
spec sempty '/^1\. z/d'
expect "empty Manual check" 1 "$d/sempty.md:24: section \"## Manual check\" is empty" check-spec "$d/sempty.md"
spec spath 's/then e\./then src\/app\/main.py changes./'
expect "file path" 1 "$d/spath.md:14: file path (rule 4: no file paths)" check-spec "$d/spath.md"

# gate: branch, clean tree, --build settings and .worktreeinclude, --final all done
g=$d/gate; plan "$g"; sed -i '' 's/^Branch: b/Branch: feature\/x/' "$g/index.md"; printf 'Branch: feature/x\n' >> "$g/spec.md"
git -C "$g" init -q -b feature/x; git -C "$g" config user.email t@t; git -C "$g" config user.name t
mkdir -p "$g/.claude" "$g/venv" && echo x > "$g/venv/x" && printf 'venv/\n' > "$g/.gitignore"
printf '{"permissions":{"allow":["Bash(git:*)","Bash(${CLAUDE_SKILL_DIR}/scripts/check-red-green.sh:*)","Bash(${CLAUDE_SKILL_DIR}/scripts/wf:*)"]}}\n' > "$g/.claude/settings.json"
printf 'venv/\n' > "$g/.worktreeinclude"
git -C "$g" add -A; git -C "$g" commit -qm init
expect "gate clean" 0 "" gate "$g/index.md"
expect "gate --build clean" 0 "" gate "$g/index.md" --build
git -C "$g" checkout -qb other
expect "gate wrong branch" 1 "$g/index.md:4: on branch other, want feature/x" gate "$g/index.md"
git -C "$g" checkout -q feature/x; echo y >> "$g/spec.md"
expect "gate dirty" 1 "$(cd "$g" && pwd -P): uncommitted changes (git status --porcelain is not empty)" gate "$g/spec.md"
git -C "$g" checkout -q -- spec.md
git -C "$g" rm -q .worktreeinclude; sed -i '' 's/,"Bash(${CLAUDE_SKILL_DIR}\/scripts\/wf:\*)"//' "$g/.claude/settings.json"; git -C "$g" commit -qam drop
r_=$(cd "$g" && pwd -P)
expect "gate --build gaps" 1 "$r_/.claude/settings.local.json: missing allow rule \"Bash(\${CLAUDE_SKILL_DIR}/scripts/wf:*)\" (fine in auto or bypass mode)
$r_/.worktreeinclude: add venv/ (ignored, so new worktrees lack it)" gate "$g/index.md" --build
expect "gate --final not done" 1 "$g/index.md:1: not every ticket is done (run /build)" gate "$g/spec.md" --final
sed -i '' 's/| todo |/| done abc |/' "$g/index.md"; git -C "$g" commit -qam done
expect "gate --final all done" 0 "" gate "$g/spec.md" --final

# gate --slice / --direct / --quick: approved, check-spec clean, any AC count for --direct, at most 3 for --quick (lettered ones count)
spec gs 's/^Branch: b/Branch: feature\/x/'; cp "$d/gs.md" "$g/s.md"; git -C "$g" add s.md; git -C "$g" commit -qm spec
expect "gate --slice approved" 0 "" gate "$g/s.md" --slice
expect "gate --direct 4 ACs" 0 "" gate "$g/s.md" --direct
expect "gate --quick 4 ACs" 1 "$g/s.md:1: 4 ACs, /quick takes at most 3. Fix: use the grilled path (/grill-me, /spec, then /direct $g/s.md)." gate "$g/s.md" --quick
sed '/US-1.AC1b:/d' "$g/s.md" > "$g/s3.md"; git -C "$g" add s3.md; git -C "$g" commit -qm three
expect "gate --quick 3 ACs" 0 "" gate "$g/s3.md" --quick
sed -i '' 's/^Status: approved/Status: draft/' "$g/s.md"; git -C "$g" commit -qam draft
expect "gate --quick draft" 1 "$g/s.md:3: Status is draft, /quick needs approved. Fix: answer every OPEN: line, set Status: approved, commit, re-run.
$g/s.md:1: 4 ACs, /quick takes at most 3. Fix: use the grilled path (/grill-me, /spec, then /direct $g/s.md)." gate "$g/s.md" --quick
expect "gate --slice draft" 1 "$g/s.md:3: Status is draft, /slice needs approved. Fix: answer every OPEN: line, set Status: approved, commit, re-run." gate "$g/s.md" --slice
sed -i '' 's/^Status: draft/Status: approved/;s/US-1.AC2:/US-1.AC3:/' "$g/s.md"; git -C "$g" commit -qam order
expect "gate --slice check-spec" 1 "$g/s.md:14: US-1.AC3 out of order, want AC2 here
$g/s.md:1: wf check-spec failed (lines above). Fix: correct each line in the spec, commit, re-run." gate "$g/s.md" --slice
sed -i '' 's/US-1.AC3:/US-1.AC2:/' "$g/s.md"
perl -i -pe 's{^(- US-2\.AC1:.*)$}{$1\n- US-2.AC2: Given a, when b, then f.\n- US-2.AC3: Given a, when b, then g.\n- US-2.AC3b: Given a, when b, then h.}' "$g/s.md"; git -C "$g" commit -qam seven
expect "gate --slice 7 ACs" 0 "" gate "$g/s.md" --slice
expect "gate --direct 7 ACs" 0 "" gate "$g/s.md" --direct
expect "gate bad mode" 2 "usage: wf gate <spec|index.md> [--build|--final|--slice|--direct|--quick]" gate "$g/s.md" --nope

# scope: changed files no ticket lists; the plan folder and dir/ entries are exempt
c=$d/scope; mkdir -p "$c"; git -C "$c" init -q -b main; git -C "$c" config user.email t@t; git -C "$c" config user.name t
echo a > "$c/README"; git -C "$c" add -A; git -C "$c" commit -qm base
plan "$c/docs/work/x"; sed -i '' 's/^Base: .*/Base: main/' "$c/docs/work/x/index.md"
perl -i -pe 's{^(- modify: .src/shared.py.)$}{$1\n- create: lib/}' "$c/docs/work/x/tickets/T02-t.md"
git -C "$c" checkout -qb feature/x; mkdir -p "$c/src" "$c/lib/deep"
echo x > "$c/src/shared.py"; echo x > "$c/lib/deep/m.py"; git -C "$c" add -A; git -C "$c" commit -qm work
expect "scope clean" 0 "" scope "$c/docs/work/x/index.md"
echo x > "$c/src/extra.py"; git -C "$c" add -A; git -C "$c" commit -qm extra
expect "scope extra file" 1 "src/extra.py: changed, but no ticket lists it under Files" scope "$c/docs/work/x/index.md"
expect "scope explicit head" 0 "" scope "$c/docs/work/x/index.md" HEAD~1

# red: every spec AC, lettered ones included, has its exact red commit
e=$d/red; mkdir -p "$e"; git -C "$e" init -q -b main; git -C "$e" config user.email t@t; git -C "$e" config user.name t
git -C "$e" commit -q --allow-empty -m base; spec redspec; sed 's/^Base: .*/Base: main/' "$d/redspec.md" > "$e/spec.md"
git -C "$e" add -A; git -C "$e" commit -qm "docs(spec): x"
git -C "$e" checkout -qb feature/x
for id in US-1.AC1 US-1.AC2 US-2.AC1; do git -C "$e" commit -q --allow-empty -m "test($id): red"; done
expect "red: lettered AC missing" 1 "$e/spec.md:13: US-1.AC1b has no \"test(US-1.AC1b): red\" or guard commit in main..HEAD" red "$e/spec.md"
git -C "$e" commit -q --allow-empty -m "test(US-1.AC1b): guard"
expect "red: guard counts" 0 "" red "$e/spec.md"
expect "red: explicit head" 1 "$e/spec.md:13: US-1.AC1b has no \"test(US-1.AC1b): red\" or guard commit in main..HEAD~1" red "$e/spec.md" HEAD~1
sed -i '' 's/^Base: .*/Base: `main` (abc1234)/' "$e/spec.md" "$c/docs/work/x/index.md"
expect "red: annotated Base" 0 "" red "$e/spec.md"
expect "scope: annotated Base" 1 "src/extra.py: changed, but no ticket lists it under Files" scope "$c/docs/work/x/index.md"

# check-review: a PASS review agrees with itself, the spec and HEAD; a FAIL review names fix tickets or OPEN items
v=$d/rev; mkdir -p "$v/docs/work/x" "$v/src"; git -C "$v" init -q -b main; git -C "$v" config user.email t@t; git -C "$v" config user.name t
spec vspec; cp "$d/vspec.md" "$v/docs/work/x/spec.md"; echo a > "$v/src/a.py"; git -C "$v" add -A; git -C "$v" commit -qm base
echo b > "$v/src/a.py"; git -C "$v" commit -qam work; end=$(git -C "$v" rev-parse HEAD)
review() { # review <sed script or ""> : write review.md for the clean PASS case, then apply the edit
  printf '# X: final review\n\nVerdict: PASS\nSpec: docs/work/x/spec.md\nRange: main...%s\nMode: full\nDate: 2026-11-21\n\n## Acceptance criteria\n\n| AC | Red commit | Test checks the AC | Note |\n|---|---|---|---|\n| US-1.AC1, AC1b | abc | yes | |\n| US-1.AC2 | def (guard) | yes | |\n| US-2.AC1 | none | n/a | manual check |\n\n## Full suite\n\n`true`: pass\n\n## Out of Scope\n\nnone.\n\n## Structure\n\n`wf size`: none\nnone\n\n## Security\n\nnone.\n\nSafe because: x. Proof: `y` -> ok\n\n## Behaviour\n\nnone\n\n### Notes\n\nnone\n\n## Verify\n\nnot run: no verify skill\n\n## Fix tickets\n\nnone\n\n## OPEN\n\nnone.\n' "$end" > "$v/docs/work/x/review.md"
  [ -z "$1" ] || sed -i '' "$1" "$v/docs/work/x/review.md"
}
R=$v/docs/work/x/review.md
review ""; expect "check-review clean PASS" 0 "" check-review "$R"
git -C "$v" add -A; git -C "$v" commit -qm "docs(review): x pass"
expect "check-review: review commit after the range is fine" 0 "" check-review "$R"
review 's/^| US-1.AC2 | def (guard) | yes |/| US-1.AC2 | def | partly |/;s/^| US-2.AC1 .*//'
expect "check-review: missing AC row, weak test" 1 "$R:14: US-1.AC2 says \"partly\" under Test checks the AC. Fix: grade the row yes or no (step 4): no when a production change makes the AC false and its tests still pass, else yes.
$R:9: US-2.AC1 (spec.md:18) has no row in the AC table. Fix: judge it (step 4) and add its row; a PASS needs every AC." check-review "$R"
review 's/^| US-1.AC1, AC1b | abc | yes | |/| US-1.AC1-AC2 | abc | yes | |/'
expect "check-review: hyphen range" 0 "" check-review "$R"
review 's/^| US-1.AC2 | def (guard) | yes | |/| US-1.AC2 | def | no | waived, flaky |/'
expect "check-review: waiver without a date does not count" 1 "$R:14: US-1.AC2 says \"no\" under Test checks the AC, but Verdict is PASS. Fix: set Verdict: FAIL and write an F ticket for it (step 8).
$R:14: US-1.AC2 says \"no\" under Test checks the AC, but its Note does not start with \"Mutation:\". Fix: start the Note with \"Mutation: <patch file beside this review>; <the test command that still passed>\", or grade the row yes." check-review "$R"
review '/^## Fix tickets/,$d'
expect "check-review: older review with no Fix tickets or OPEN section" 0 "" check-review "$R"
review 's/^`true`: pass/`true`: fail (2 baseline)/;/^## Fix tickets/{n;n;s/none/F01 a: fixes US-1.AC2/;}'
expect "check-review: baseline suite fail is not judged; fix tickets are" 1 "$R:50: Fix tickets is not none, but Verdict is PASS. Fix: set Verdict: FAIL (step 8 builds them), or mark a declined structure finding declined and remove its ticket." check-review "$R"
review '/^## OPEN/{n;n;s/none./Should x be y?/;}'
expect "check-review: PASS with OPEN" 1 "$R:54: OPEN is not none, but Verdict is PASS. Fix: set Verdict: FAIL and stop: OPEN items are the user's (step 8)." check-review "$R"
review 's/^Verdict: PASS/Verdict: PASS (overruled by hand: J 2026-11-21)/;/^## OPEN/{n;n;s/none./Should x be y?/;}'
expect "check-review: overruled PASS may keep OPEN" 0 "" check-review "$R"
review 's/^not run: no verify skill/US-1.AC1: fail, got 3/'
expect "check-review: PASS with a verify fail" 1 "$R:46: Verify row says fail, but Verdict is PASS. Fix: set Verdict: FAIL and write an F ticket citing this row (step 8)." check-review "$R"
review ""; git -C "$v" add -A; git -C "$v" commit -q --allow-empty -m "docs(review): again"; echo c > "$v/src/a.py"; git -C "$v" commit -qam later
expect "check-review: stale PASS" 1 "$R:5: src/a.py changed since the Range end ${end:0:9}. Fix: re-run /final-review docs/work/x/spec.md (a delta run covers only these)." check-review "$R"
expect "check-review: explicit head" 0 "" check-review "$R" HEAD~1
review 's/^Verdict: PASS/Verdict: FAIL/;/^## Fix tickets/{n;n;s/none/F01 a: fixes US-1.AC2/;}'
expect "check-review: stale FAIL names the files too" 1 "$R:5: src/a.py changed since the Range end ${end:0:9}. Fix: re-run /final-review docs/work/x/spec.md (a delta run covers only these)." check-review "$R"
review 's/^Range: main\.\.\..*/Range: main...HEAD/'
expect "check-review: Range end HEAD" 1 "$R:5: Range end HEAD is not a commit sha. Fix: write Range: <BASE>...<HEAD sha> with the sha the review ran at." check-review "$R"
git -C "$v" checkout -q -f -b rebased "$end~1"; echo z > "$v/src/z.py"; git -C "$v" add src/z.py; git -C "$v" commit -qm rebased; review ""
expect "check-review: rebased branch" 1 "$R:5: Range end ${end:0:9} is not an ancestor of HEAD. Fix: re-run /final-review docs/work/x/spec.md at this branch." check-review "$R"
git -C "$v" checkout -q -f main
review 's/^Verdict: PASS/Verdict: FAIL/'
expect "check-review: FAIL with nothing to do" 1 "$R:3: Verdict is FAIL, but Fix tickets and OPEN are both none. Fix: list the F tickets step 8 writes, or the OPEN items for the user.
$R:5: src/a.py changed since the Range end ${end:0:9}. Fix: re-run /final-review docs/work/x/spec.md (a delta run covers only these)." check-review "$R"
review 's/^Verdict: PASS/Verdict: FAIL/;/^## Fix tickets/{n;n;s/none/F01 a: fixes US-1.AC2/;}'
expect "check-review: FAIL with a ticket, fresh" 0 "" check-review "$R" HEAD~1

# wf base: constack.base wins, else origin/HEAD, else exit 2 with a Fix
b=$d/base; git init -q -b main "$b"; git -C "$b" commit -q --allow-empty -m x
git -C "$b" update-ref refs/remotes/origin/main HEAD
here=$PWD; cd "$b" || exit 1
expect "base: nothing set" 2 "wf base: no base branch: constack.base is unset and origin/HEAD is missing. Fix: git config constack.base <branch>, or git remote set-head origin --auto" base
git -C "$b" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
expect "base: origin/HEAD" 0 $'origin/main\nwf base: from origin/HEAD (git config constack.base <branch> overrides it)' base
git -C "$b" config constack.base staging
expect "base: constack.base" 0 $'origin/staging\nwf base: from git config constack.base' base
git -C "$b" config constack.base origin/staging
expect "base: constack.base with origin/" 0 $'origin/staging\nwf base: from git config constack.base' base
expect "base: extra arg" 2 "usage: wf base" base x
cd "$here" || exit 1

[ $fail = 0 ] && echo "OK wf-test"
exit $fail
