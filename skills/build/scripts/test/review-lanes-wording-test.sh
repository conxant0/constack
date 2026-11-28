#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL review-lanes-wording-test: $*"; fail=1; }
s=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib-py.sh"; py=${1:-python3}
need_pytest "$py" review-lanes-wording-test
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

pyrepo "$d/a" '    pass'; root=$(cd "$d/a" && pwd -P)
export STATUS_LOG=$d/status.log
out=$("$s/review-lanes" "$d/a/docs/work/f/index.md" "$base"); rc=$?
grep -q '^LANE wording: \(PASS\|SURVIVED\) ' <<<"$out" || bad "AC2 wording lane did not run: $out"
grep -q '1 sentences: ' <<<"$out" || bad "AC2 wording lane checked no sentence (copy not at HEAD?): $out"
mine=$(grep -F "$root [" "$STATUS_LOG")
[ "$(wc -l <<<"$mine" | tr -d ' ')" -ge 4 ] || bad "AC2 full lane sampled too little: $mine"
! grep -vxF "$root []" <<<"$mine" | grep -q . || bad "AC2 review tree had changed tracked files: $mine"
grep -q "/wording \[" "$STATUS_LOG" || bad "AC2 wording lane did not run in its own copy: $(cat "$STATUS_LOG")"
(cd "$d/a" && bash run.sh >/dev/null 2>&1); plain=$([ $? = 0 ] && echo PASS || echo FAIL)
grep -q "^LANE full: $plain " <<<"$out" || bad "AC2 full lane differs from a plain run ($plain): $out"
[ -z "$(git -C "$d/a" status --porcelain --untracked-files=no)" ] || bad "AC2 review tree left changed"

for need in venv env; do
  if [ $need = venv ]; then ign='.venv/'; path=.venv/marker; else ign='.env'; path=.env; fi
  pyrepo "$d/b-$need" "    assert os.path.exists('$path')"
  printf '%s\n' "$ign" > "$d/b-$need/.gitignore"; printf '%s\n' "$ign" > "$d/b-$need/.worktreeinclude"
  git -C "$d/b-$need" add .gitignore .worktreeinclude; git -C "$d/b-$need" commit -qm include
  mkdir -p "$d/b-$need/.venv"; echo x > "$d/b-$need/$path"
  out=$(STATUS_LOG=$d/s2.log "$s/review-lanes" "$d/b-$need/docs/work/f/index.md" "$base" --only wording); rc=$?
  grep -q '^LANE wording: \(PASS\|SURVIVED\) ' <<<"$out" || bad "AC5 [$need] wording lane: $out"
  ! grep -q 'COULD-NOT-RUN' <<<"$out" || bad "AC5 [$need] could not run: $out"
  grep -q '1 sentences: ' <<<"$out" || bad "AC5 [$need] no sentence reported: $out"
done
pyrepo "$d/c-env" "    assert os.path.exists('.env')"; echo x > "$d/c-env/.env"
out=$(STATUS_LOG=$d/s3.log "$s/review-lanes" "$d/c-env/docs/work/f/index.md" "$base" --only wording)
grep -q '^LANE wording: COULD-NOT-RUN ' <<<"$out" && grep -q 'Fix: re-run review-lanes .* --only wording --wording-tests ' <<<"$out" || bad "AC5 control: missing include path did not give COULD-NOT-RUN: $out"
out=$(STATUS_LOG=$d/s4.log "$s/review-lanes" "$d/c-env/docs/work/f/index.md" "$base" --only wording --wording-tests true)
grep -q '^LANE wording: SURVIVED ' <<<"$out" || bad "AC5 --wording-tests not used: $out"
grep -qx '  SURVIVED mod.py:MSG: Keep it short.' <<<"$out" || bad "AC5 SURVIVED sentence not listed: $out"
! grep -q '^LANE \(full\|clean\):' <<<"$out" || bad "AC5 --only wording ran other lanes: $out"

[ $fail = 0 ] && echo "OK review-lanes-wording-test"; exit $fail
