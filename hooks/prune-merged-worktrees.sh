#!/bin/bash
# SessionStart: remove worktrees whose branch has a PR merged into the repo's base (wf base:
# git config constack.base, else origin/HEAD).
# `git worktree remove` without --force refuses a worktree with uncommitted or
# untracked files, so unsaved work is never deleted; those are reported instead.
# DRY_RUN=1 lists what would go without removing anything.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git remote get-url origin 2>/dev/null | grep -q github.com || exit 0

base=$(~/.claude/skills/build/scripts/wf base 2>/dev/null) || exit 0
merged=$(gh pr list --base "${base#origin/}" --state merged --limit 300 \
  --json headRefName --jq '.[].headRefName' 2>/dev/null) || exit 0
[ -n "$merged" ] || exit 0

main=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
here=$(git rev-parse --show-toplevel)
removed=() kept=()

while IFS=$'\t' read -r path branch; do
  [ "$path" = "$main" ] || [ "$path" = "$here" ] && continue
  grep -qxF "$branch" <<<"$merged" || continue
  if [ -n "$DRY_RUN" ]; then removed+=("$branch"); continue; fi
  if git worktree remove "$path" 2>/dev/null; then removed+=("$branch")
  else kept+=("$branch"); fi
done < <(git worktree list --porcelain | awk '
  /^worktree /{p=substr($0,10)}
  /^branch /{sub("refs/heads/","",$2); print p"\t"$2}')

msg=""
[ ${#removed[@]} -gt 0 ] && msg="Removed merged worktrees: ${removed[*]}."
[ ${#kept[@]} -gt 0 ] && msg="$msg Kept (uncommitted or untracked files): ${kept[*]}."
[ -n "$msg" ] && jq -nc --arg m "${DRY_RUN:+[dry run] }$msg" '{systemMessage: $m}'
exit 0
