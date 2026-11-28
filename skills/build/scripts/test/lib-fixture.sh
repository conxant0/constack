FX_VERIFY='for t in tests/*.sh; do bash "$t" || exit 1; done'

fx_repo() {
  mkdir -p "$1/tests"
  git -C "$1" init -q
  git -C "$1" config user.email t@example.com
  git -C "$1" config user.name t
  echo 1 > "$1/app.txt"
  echo 'test -f app.txt' > "$1/tests/base.sh"
  git -C "$1" add -A
  git -C "$1" commit -qm init
}

fx_commit() {
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

fx_ticket() {
  local path=$1 id; shift
  id=$(basename "$path"); id=${id%%-*}
  mkdir -p "$(dirname "$path")"
  { printf '# %s x\n## Delivers\n\n' "$id"; printf '%s\n' "$@"; printf '## Files\n- test: tests/x.sh\n'; } > "$path"
}

fx_guard() {
  local dir=$1
  mkdir -p "$(dirname "$dir/$3")"
  printf '%s\n' "$4" > "$dir/$3"
  git -C "$dir" add -A
  { printf 'test(%s): guard\n\n' "$2"; cat "$5"; } | git -C "$dir" commit -q --cleanup=verbatim -F -
  git -C "$dir" rev-parse HEAD
}

mkguard() {
  [ -d "$1/.git" ] || { fx_repo "$1"; fx_commit "$1" 'chore: other' other.txt a >/dev/null; }
  base=$(git -C "$1" rev-parse HEAD)
  sha=$(fx_guard "$1" US-1.AC1 tests/g1.sh 'grep -qx 1 app.txt' "$2")
}

patch_of() {
  printf '%s\n' "$3" > "$1/$2"
  git -C "$1" diff -- "$2"
  git -C "$1" checkout -- "$2"
}

sedi() { # sedi <sed script> <file>...: in-place edit; `sed -i.bak` reads the same on BSD and GNU sed, `sed -i ''` is BSD only
  local script=$1 f; shift
  sed -i.bak "$script" "$@" || return
  for f in "$@"; do rm -f "$f.bak"; done
}
