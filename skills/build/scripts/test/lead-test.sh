#!/usr/bin/env bash
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
expect() {
  local name=$1 want_rc=$2 want=$3 out rc; shift 3
  out=$("$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}
repo() {
  r=$d/$1; mkdir -p "$r"; git -C "$r" init -q -b main; git -C "$r" config user.email t@t; git -C "$r" config user.name t
  echo a > "$r/app.txt"; git -C "$r" add -A; git -C "$r" commit -qm base
  git -C "$r" checkout -qb feature/x; mkdir -p "$r/docs/work/x"
  printf '# X: build index\n\nBranch: feature/x\nBase: main\n\n| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | todo |\n' > "$r/docs/work/x/index.md"
  git -C "$r" add -A; git -C "$r" commit -qm 'docs(direct): x index'
}
lines() {
  seq "$3" >> "$1/$2"; git -C "$1" add -A; git -C "$1" commit -qm "$4"
}

repo own; lines "$r" app.txt 2 'feat(US-1.AC1): green'
sha=$(git -C "$r" rev-parse --short=8 HEAD)
expect "US-4.AC1 lead AC commit" 1 "$r/docs/work/x/index.md:1: commit $sha \"feat(US-1.AC1): green\" is the lead's own AC commit. Fix: hand AC work to a helper and merge the helper's branch with a merge commit (git merge --no-ff)." lead "$r/docs/work/x/index.md"

repo big; lines "$r" glue.sh 30 'chore: wire parts'; lines "$r" app.txt 11 'fix: glue'; lines "$r" docs/work/x/notes.md 50 'docs(direct): notes'
expect "US-4.AC2 41 lines" 1 "$r/docs/work/x/index.md:1: the lead's own commits change 41 lines outside docs/work/x/, limit 40. Fix: hand the work to a helper and merge its branch with a merge commit (git merge --no-ff)." lead "$r/docs/work/x/index.md"

repo edge; lines "$r" glue.sh 40 'chore: wire parts'
expect "lead 40 lines is within the limit" 0 "" lead "$r/docs/work/x/index.md"

repo merged; git -C "$r" checkout -qb helper
lines "$r" ac1-test.sh 60 'test(US-1.AC1): red'; lines "$r" app.txt 60 'feat(US-1.AC1): green'
git -C "$r" checkout -q feature/x; git -C "$r" merge -q --no-ff helper -m 'merge P1: a'
lines "$r" glue.sh 10 'chore: glue'; lines "$r" docs/work/x/notes.md 200 'docs(direct): notes'
expect "US-4.AC3 merged AC work, small glue" 0 "" lead "$r/docs/work/x/index.md"

repo mergesubj; git -C "$r" checkout -qb helper
lines "$r" app.txt 5 'feat(US-1.AC1): green'
git -C "$r" checkout -q feature/x; git -C "$r" merge -q --no-ff helper -m 'feat(US-1.AC1): merge helper'
expect "lead merge commit with an AC subject is not the lead's own" 0 "" lead "$r/docs/work/x/index.md"

[ $fail = 0 ] && echo "OK lead-test"; exit $fail
