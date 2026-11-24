# Shared fixtures for the build scripts' tests: a throwaway git repo, commits, a ticket file.
FX_VERIFY='for t in tests/*.sh; do bash "$t" || exit 1; done'

fx_repo() { # <dir>: a repo with app.txt (1) and tests/base.sh, one commit "init"
  mkdir -p "$1/tests"
  git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name t
  echo 1 > "$1/app.txt"
  echo 'test -f app.txt' > "$1/tests/base.sh"
  git -C "$1" add -A
  git -C "$1" commit -qm init
}

fx_commit() { # <dir> <subject> [<path> <content>]...: prints the new sha
  local dir=$1 subj=$2; shift 2
  while [ $# -ge 2 ]; do
    mkdir -p "$(dirname "$dir/$1")"
    printf '%s\n' "$2" > "$dir/$1"
    shift 2
  done
  git -C "$dir" add -A
  git -C "$dir" commit -qm "$subj"
  git -C "$dir" rev-parse HEAD
}

fx_ticket() { # <path> <delivers line>...: a ticket whose ## Delivers holds the given lines
  local path=$1 id; shift
  id=$(basename "$path"); id=${id%%-*}
  mkdir -p "$(dirname "$path")"
  { printf '# %s x\n## Delivers\n\n' "$id"; printf '%s\n' "$@"; printf '## Files\n- test: tests/x.sh\n'; } > "$path"
}
