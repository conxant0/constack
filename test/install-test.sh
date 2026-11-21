#!/usr/bin/env bash
# install-test.sh: runs install.sh against throwaway HOME folders, never the real one. Prints FAIL lines, exit 1 on any.
set -u
repo=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
f() { echo "FAIL $*"; fail=1; }
run() { out=$(HOME=$1 "$repo/install.sh" ${2:-} 2>&1); rc=$?; }

# fresh home: every skill, hook and the status line linked; CLAUDE.md imports ours; settings copied
h=$d/fresh; mkdir -p "$h"; run "$h"
[ $rc = 0 ] || f "fresh: exit $rc: $out"
for s in "$repo"/skills/*/; do n=$(basename "$s")
  [ "$(readlink "$h/.claude/skills/$n")" = "$repo/skills/$n" ] || f "fresh: skills/$n not linked"; done
[ "$(readlink "$h/.claude/statusline.js")" = "$repo/statusline.js" ] || f "fresh: statusline.js not linked"
[ "$(readlink "$h/.claude/hooks/prune-merged-worktrees.sh")" = "$repo/hooks/prune-merged-worktrees.sh" ] || f "fresh: hook not linked"
[ "$(cat "$h/.claude/CLAUDE.md")" = "@$repo/CLAUDE.md" ] || f "fresh: CLAUDE.md is not the import line"
cmp -s "$h/.claude/settings.json" "$repo/settings.example.json" || f "fresh: settings.json not copied"

# second run changes nothing and passes
run "$h"; [ $rc = 0 ] || f "rerun: exit $rc: $out"
grep -q '^linked\|^moved\|^added' <<<"$out" && f "rerun: changed something: $out"

# your own CLAUDE.md and settings.json are never touched
h=$d/own; mkdir -p "$h/.claude"; echo "# mine" > "$h/.claude/CLAUDE.md"; echo '{"model":"x"}' > "$h/.claude/settings.json"; run "$h"
[ "$(cat "$h/.claude/CLAUDE.md")" = "# mine" ] || f "own: CLAUDE.md changed"
[ "$(cat "$h/.claude/settings.json")" = '{"model":"x"}' ] || f "own: settings.json changed"
grep -qF "add this line at the top so it loads constack's rules: @$repo/CLAUDE.md" <<<"$out" || f "own: no import instruction: $out"

# an existing skill folder is left alone, reported, exit 1 with a Fix
h=$d/conflict; mkdir -p "$h/.claude/skills/spec"; echo old > "$h/.claude/skills/spec/SKILL.md"; run "$h"
[ $rc = 1 ] || f "conflict: exit $rc, want 1"
grep -qF "Fix: re-run as ./install.sh --replace" <<<"$out" || f "conflict: no Fix line: $out"
[ "$(cat "$h/.claude/skills/spec/SKILL.md")" = old ] || f "conflict: existing skill touched"

# --replace backs it up, then links
run "$h" --replace; [ $rc = 0 ] || f "replace: exit $rc: $out"
[ "$(readlink "$h/.claude/skills/spec")" = "$repo/skills/spec" ] || f "replace: spec not linked"
ls "$h"/.claude/backups/constack-*/skills/spec/SKILL.md >/dev/null 2>&1 || f "replace: no backup of the old skill"

[ $fail = 0 ] && echo "OK install-test"; exit $fail
