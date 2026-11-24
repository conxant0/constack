# pyrepo <dir> <test path> <test body> <new msg.py>: a Python repo with an init, a red and a green commit; sets base and head
pyrepo() {
  local dir=$1
  mkdir -p "$dir/pkg/tests"
  git -C "$dir" init -q
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name t
  echo 'X = 1' > "$dir/pkg/msg.py"
  : > "$dir/pkg/tests/__init__.py"
  git -C "$dir" add -A
  git -C "$dir" commit -qm init
  base=$(git -C "$dir" rev-parse HEAD)
  mkdir -p "$(dirname "$dir/$2")"
  { echo 'import os, sys; sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__)))); import msg'; printf '%s' "$3"; } > "$dir/$2"
  git -C "$dir" add -A
  git -C "$dir" commit -qm 'test(US-1.AC1): red'
  printf '%s' "$4" > "$dir/pkg/msg.py"
  git -C "$dir" add -A
  git -C "$dir" commit -qm 'feat: green'
  head=$(git -C "$dir" rev-parse HEAD)
}
