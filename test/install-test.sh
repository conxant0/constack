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
[ "$(HOME=$h git config --global --get core.hooksPath)" = "$repo/git-hooks" ] || f "fresh: core.hooksPath not set to git-hooks/"

# a different core.hooksPath is left alone and reported; --replace backs it up and sets ours
h=$d/hookspath; mkdir -p "$h"; HOME=$h git config --global core.hooksPath /elsewhere; run "$h"
[ $rc = 1 ] || f "hookspath: exit $rc, want 1"
[ "$(HOME=$h git config --global --get core.hooksPath)" = /elsewhere ] || f "hookspath: changed without --replace"
grep -qF "Fix: re-run as ./install.sh --replace" <<<"$out" || f "hookspath: no Fix line: $out"
run "$h" --replace
[ "$(HOME=$h git config --global --get core.hooksPath)" = "$repo/git-hooks" ] || f "hookspath: --replace did not set ours"
grep -qx /elsewhere "$h"/.claude/backups/constack-*/core.hooksPath 2>/dev/null || f "hookspath: old value not backed up"

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

h=$d/prune; mkdir -p "$h/.claude/skills" "$h/.claude/hooks"
ln -s "$repo/skills/no-such-skill" "$h/.claude/skills/no-such-skill"
ln -s "$repo/hooks/no-such-hook" "$h/.claude/hooks/no-such-hook"
run "$h"
[ $rc = 0 ] || f "prune: exit $rc: $out"
for p in "$h/.claude/skills/no-such-skill" "$h/.claude/hooks/no-such-hook"; do
  [ -L "$p" ] && f "prune: $p still there"
  [ "$(grep -cxF "pruned $p" <<<"$out")" = 1 ] || f "prune: want one 'pruned $p' line: $out"; done

h=$d/keep; mkdir -p "$h/.claude/skills/mine"
ln -s "$repo-2/skills/gone" "$h/.claude/skills/outside"
ln -s "../no-such-skill" "$h/.claude/skills/relative"
run "$h"
[ -L "$h/.claude/skills/outside" ] || f "keep: outside link removed"
[ -L "$h/.claude/skills/relative" ] || f "keep: relative link removed"
[ -d "$h/.claude/skills/mine" ] && [ ! -L "$h/.claude/skills/mine" ] || f "keep: real folder removed"
grep -q '^pruned' <<<"$out" && f "keep: pruned something: $out"

[ $fail = 0 ] && echo "OK install-test"; exit $fail
