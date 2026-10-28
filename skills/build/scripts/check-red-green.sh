#!/usr/bin/env bash
# check-red-green.sh <worktree> <base-sha> "<verify command>"
#   RED:    every `test(US-n.ACm): red` commit in base..HEAD fails the verify command
#   GUARD:  every `test(US-n.ACm): guard` commit passes it and names a `Mutation:` in its body
#   GREEN:  HEAD passes the verify command
#   FROZEN: no later non-red/guard commit touches a file a red or guard commit touched
# One line per check. Exit 0 all OK, 1 any FAIL, 2 could not run.
set -u
wt=$1 base=$2 verify=$3
red_re='^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$'

cd "$wt" || { echo "ERROR cannot cd to $wt"; exit 2; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "ERROR worktree has uncommitted changes"; exit 2; }
head=$(git rev-parse HEAD)
branch=$(git symbolic-ref -q --short HEAD || echo "$head")
trap 'git checkout -q "$branch" 2>/dev/null' EXIT

last_line() { # most telling line of a test run's output
  local l
  l=$(printf '%s\n' "$1" | grep -E 'Error|FAIL|assert|[Ee]xpected' | tail -n 1)
  [ -n "$l" ] || l=$(printf '%s\n' "$1" | tail -n 1)
  printf '%s' "$l" | cut -c1-200
}

fail=0
reds=$(git log --reverse --format='%H %s' "$base..$head" | grep -E "^[0-9a-f]+ ${red_re#^}" | cut -d' ' -f1)
[ -n "$reds" ] || echo "INFO no red commits in $base..$head"

for r in $reds; do
  ac=$(git log -1 --format=%s "$r" | sed -E 's/^test\((.*)\): (red|guard)$/\1/')
  kind=$(git log -1 --format=%s "$r" | sed -E 's/.*: //')
  git checkout -q --detach "$r"
  if [ "$kind" = guard ]; then
    mut=$(git log -1 --format=%b "$r" | grep -m1 '^Mutation: ' | cut -c1-200)
    if ! out=$(bash -c "$verify" 2>&1); then
      echo "FAIL guard $ac ${r:0:8}: verify failed at the guard commit: $(last_line "$out")"; fail=1
    elif [ -z "$mut" ]; then
      echo "FAIL guard $ac ${r:0:8}: no \"Mutation: \" line in the commit body"; fail=1
    else
      echo "OK   guard $ac ${r:0:8}: $mut"
    fi
  elif out=$(bash -c "$verify" 2>&1); then
    echo "FAIL red $ac ${r:0:8}: verify passed at the red commit"; fail=1
  else
    echo "OK   red $ac ${r:0:8}: $(last_line "$out")"
  fi
  files=$(git diff-tree --no-commit-id --name-only -r "$r")
  for c in $(git rev-list --reverse "$r..$head"); do
    subj=$(git log -1 --format=%s "$c")
    printf '%s\n' "$subj" | grep -qE "$red_re" && continue
    touched=$(git diff-tree --no-commit-id --name-only -r "$c")
    for f in $files; do
      if printf '%s\n' "$touched" | grep -qFx -- "$f"; then
        echo "FAIL frozen $ac: ${c:0:8} \"$subj\" changed $f after its red commit"; fail=1
      fi
    done
  done
done

git checkout -q "$branch"
if out=$(bash -c "$verify" 2>&1); then
  echo "OK   green HEAD ${head:0:8}"
else
  echo "FAIL green HEAD ${head:0:8}: $(last_line "$out")"; fail=1
fi
exit $fail
