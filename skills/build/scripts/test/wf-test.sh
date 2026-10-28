#!/usr/bin/env bash
# wf-test.sh: runs wf against small index fixtures. Prints FAIL lines, exit 1 on any.
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0

index() { # index <name> <rows...>: write a minimal index.md with those table rows
  local f=$d/$1.md; shift
  { printf '# X: build index\n\nBranch: b\nBase: origin/staging\nTest command: `true`\n\n'
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

# get-tech-stack shape: T05 heads a new chain because its blockers sit in two chains
index split '| T01 | a | none | todo |' '| T02 | b | T01 | todo |' '| T03 | c | none | todo |' \
  '| T04 | d | T03 | todo |' '| T05 | e | T02, T04 | todo |' '| T06 | f | T05 | todo |' '| F01 | g | none | todo |'
expect "chains split at a join" 0 $'Chain: T01 > T02\nChain: T03 > T04\nChain: T05 > T06' chains "$d/split.md"

# mcp-research-tools shape: T01 feeds two tickets so it stays out; T05/T06 have two blockers, both in the chain
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
  printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: b\nBase: origin/staging\nTest command: `true`\n\n| Ticket | Title | Blocked by | Status |\n|---|---|---|---|\n| T01 | a | none | todo |\n| T02 | b | T01 | todo |\n\n## Rulings\n' > "$1/index.md"
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
plan "$d/nofile"; rm "$d/nofile/tickets/T02-t.md"
expect "row without ticket file" 1 "$d/nofile/index.md:11: T02 has no ticket file tickets/T02-*.md
$d/nofile/spec.md:4: MISSING: AC in no ticket's Delivers" check-plan "$d/nofile/index.md"

# check-spec: a clean spec, then one broken copy per rule
spec() { # spec <name> [sed script]
  printf '# X\n\nStatus: approved\nBranch: b\nBase: origin/staging\nDate: 2026-10-26\n\n## User stories\n\n### US-1 One\n\n- US-1.AC1: Given a, when b, then c.\n- US-1.AC1b: Given a, when b, then d.\n- US-1.AC2: Given a, when b, then e.\n\n### US-2 Two\n\n- US-2.AC1: Given a, when b, then the docs/work index updates.\n\n## Out of Scope\n\n- y (later)\n\n## Manual check\n\n1. z\n' > "$d/$1.md"
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

[ $fail = 0 ] && echo "OK wf-test"
exit $fail
