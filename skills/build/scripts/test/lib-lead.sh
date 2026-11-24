# Lead-side fixtures for wf done tests: a repo with an index on main, and ticket branches merged into it.

lead() { # <dir>: repo on main with app.txt, tests/base.sh, docs/work/f/index.md (Base: base) and tickets/T02-b.md; tags the commit base
  mkdir -p "$1/tests" "$1/docs/work/f/tickets"
  git -C "$1" init -q -b main
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name t
  echo 1 > "$1/app.txt"
  echo 'test -f app.txt' > "$1/tests/base.sh"
  printf '%s\n' 'Branch: main' 'Base: base' '' '| T01 | a | none | done x |' '| T02 | b | T01 | todo |' '' '## Rulings' > "$1/docs/work/f/index.md"
  printf '%s\n' '# T02 b' '## Approach' '- none' > "$1/docs/work/f/tickets/T02-b.md"
  git -C "$1" add -A
  git -C "$1" commit -qm init
  git -C "$1" tag base
}

merge_ticket() { # <dir> <branch> (<subject> <path> <content>)...: one commit per triple on <branch>, merged --no-ff into main; prints the merge sha
  local dir=$1 branch=$2; shift 2
  git -C "$dir" checkout -q -b "$branch"
  while [ $# -ge 3 ]; do
    mkdir -p "$(dirname "$dir/$2")"
    printf '%s\n' "$3" > "$dir/$2"
    git -C "$dir" add -A
    git -C "$dir" commit -qm "$1"
    shift 3
  done
  git -C "$dir" checkout -q main
  git -C "$dir" merge -q --no-ff "$branch" -m "merge $branch"
  git -C "$dir" rev-parse HEAD
}
