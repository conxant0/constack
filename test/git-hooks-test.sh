#!/usr/bin/env bash
# git-hooks-test.sh: runs git-hooks/ against throwaway repos and a throwaway HOME. Prints FAIL lines, exit 1 on any.
set -u
repo=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
f() { echo "FAIL $*"; fail=1; }
export HOME=$d/home GIT_CONFIG_NOSYSTEM=1; mkdir -p "$HOME"
git config --global core.hooksPath "$repo/git-hooks"
git config --global user.name t; git config --global user.email t@t
git config --global init.defaultBranch main

r=$d/r; git init -q "$r"; cd "$r"
commit() { echo x >> f; git add f; out=$(git commit -q -m "$1" 2>&1); rc=$?; }

# a Claude Co-Authored-By line is blocked with a Fix
commit $'subject\n\nCo-Authored-By: Claude <noreply@anthropic.com>'
[ $rc != 0 ] || f "claude trailer: commit went through"
grep -qF "Fix: delete that line from the message and run the same git commit again." <<<"$out" || f "claude trailer: no Fix line: $out"
commit $'subject\n\nco-authored-by: Someone <x@anthropic.com>'
[ $rc != 0 ] || f "lowercase anthropic trailer: commit went through"

# a plain message and a human co-author pass
commit "plain"; [ $rc = 0 ] || f "plain: blocked: $out"
commit $'subject\n\nCo-Authored-By: Pat Doe <pat@example.com>'; [ $rc = 0 ] || f "human co-author: blocked: $out"

# the repo's own .git/hooks still run, with arguments and stdin
printf '#!/bin/sh\necho own-commit-msg >&2\nexit 1\n' > .git/hooks/commit-msg; chmod +x .git/hooks/commit-msg
commit "plain2"; [ $rc != 0 ] && grep -q own-commit-msg <<<"$out" || f "own commit-msg did not run: $out"
rm .git/hooks/commit-msg
printf '#!/bin/sh\necho "args=$1 stdin=$(cat)" > %s/pushed\nexit 0\n' "$d" > .git/hooks/pre-push; chmod +x .git/hooks/pre-push
git init -q --bare "$d/remote.git"; git remote add origin "$d/remote.git"
git push -q origin main 2>/dev/null || f "push failed"
grep -q '^args=origin stdin=refs/heads/main ' "$d/pushed" 2>/dev/null || f "own pre-push did not get args and stdin: $(cat "$d/pushed" 2>&1)"

# inside a worktree, the main repo's hooks are found
git worktree add -q "$d/wt" -b wt; cd "$d/wt"
printf '#!/bin/sh\nexit 1\n' > "$r/.git/hooks/pre-commit"; chmod +x "$r/.git/hooks/pre-commit"
commit "in worktree"; [ $rc != 0 ] || f "worktree: main repo's pre-commit did not run"

# every hook file links to dispatch
for h in "$repo"/git-hooks/*; do n=$(basename "$h"); [ "$n" = dispatch ] && continue
  [ "$(readlink "$h")" = dispatch ] || f "git-hooks/$n is not a link to dispatch"; done

[ $fail = 0 ] && echo "OK git-hooks-test"; exit $fail
