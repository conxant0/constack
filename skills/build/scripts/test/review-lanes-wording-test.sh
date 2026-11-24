#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL review-lanes-wording-test: $*"; fail=1; }
s=$(cd "$(dirname "$0")/.." && pwd)
py=${1:-python3}
"$py" -c 'import pytest' 2>/dev/null || { echo "SKIP review-lanes-wording-test: no python with pytest"; exit 0; }
export TMPDIR=$d/tmp PYTHONDONTWRITEBYTECODE=1; mkdir -p "$TMPDIR"
export HOME=$d/home; mkdir -p "$HOME"

pyrepo() {
  local r=$1 extra=$2
  mkdir -p "$r/tests" "$r/docs/work/f"
  git -C "$r" init -q
  git -C "$r" config user.email t@t; git -C "$r" config user.name t
  echo 'MSG = "Old sentence."' > "$r/mod.py"
  printf '%s\n' 'import os, sys; sys.path.insert(0, os.getcwd()); import mod' '' 'def test_msg():' \
    '    assert "short" in mod.MSG.lower() or "old" in mod.MSG.lower()' "$extra" > "$r/tests/test_mod.py"
  cat > "$r/run.sh" <<EOF
for i in 1 2 3 4; do echo "\$(pwd -P) [\$(git status --porcelain --untracked-files=no | tr '\n' ';')]" >> "\$STATUS_LOG"; sleep 0.5; done; $py -m pytest -q -p no:cacheprovider tests
EOF
  echo 'Test command: `bash run.sh`' > "$r/docs/work/f/index.md"
  git -C "$r" add -A; git -C "$r" commit -qm init
  base=$(git -C "$r" rev-parse HEAD)
  echo 'MSG = "Keep it short."' > "$r/mod.py"
  git -C "$r" commit -qam 'feat: wording'
}

# US-1.AC2
pyrepo "$d/a" '    pass'; root=$(cd "$d/a" && pwd -P)
export STATUS_LOG=$d/status.log
out=$("$s/review-lanes" "$d/a/docs/work/f/index.md" "$base"); rc=$?
grep -q '^LANE wording: \(PASS\|SURVIVED\) ' <<<"$out" || bad "AC2 wording lane did not run: $out"
grep -q '1 sentences: ' <<<"$out" || bad "AC2 wording lane checked no sentence (copy not at HEAD?): $out"
mine=$(grep -F "$root [" "$STATUS_LOG")
[ "$(wc -l <<<"$mine" | tr -d ' ')" -ge 4 ] || bad "AC2 full lane sampled too little: $mine"
! grep -vxF "$root []" <<<"$mine" | grep -q . || bad "AC2 review tree had changed tracked files: $mine"
grep -q "/wording \[" "$STATUS_LOG" || bad "AC2 wording lane did not run in its own copy: $(cat "$STATUS_LOG")"
# the full lane's result matches a plain run of the Test command
(cd "$d/a" && bash run.sh >/dev/null 2>&1); plain=$([ $? = 0 ] && echo PASS || echo FAIL)
grep -q "^LANE full: $plain " <<<"$out" || bad "AC2 full lane differs from a plain run ($plain): $out"
[ -z "$(git -C "$d/a" status --porcelain --untracked-files=no)" ] || bad "AC2 review tree left changed"

[ $fail = 0 ] && echo "OK review-lanes-wording-test"; exit $fail
