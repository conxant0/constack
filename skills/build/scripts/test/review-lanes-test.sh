#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL review-lanes-test: $*"; fail=1; }
s=$(cd "$(dirname "$0")/.." && pwd)
export TMPDIR=$d/tmp; mkdir -p "$TMPDIR"
export HOME=$d/home; mkdir -p "$HOME"

mkrepo() {
  local r=$1 env=$2
  mkdir -p "$r/tests" "$r/docs/work/f"
  git -C "$r" init -q
  git -C "$r" config user.email t@t; git -C "$r" config user.name t
  echo 'sleep 2; f=0; for t in tests/*.sh; do bash "$t" || { echo "FAILED $t"; f=1; }; done; exit $f' > "$r/run.sh"
  echo true > "$r/tests/ok.sh"
  echo 'Test command: `bash run.sh`' > "$r/docs/work/f/index.md"
  if [ "$env" = yes ]; then
    echo .env > "$r/.gitignore"
    echo .env > "$r/.worktreeinclude"
    echo NEEDED=1 > "$r/.env"
    echo '[ -f .env ] && . ./.env; [ "${NEEDED:-}" = 1 ]' > "$r/tests/env.sh"
  fi
  git -C "$r" add -A; git -C "$r" commit -qm init
}

field() { grep "^LANE $2: " <<<"$1" | tr ' ' '\n' | sed -n "s/^$3=//p"; }

# US-1.AC1
mkrepo "$d/a" yes; base=$(git -C "$d/a" rev-parse HEAD)
out=$(NEEDED=1 "$s/review-lanes" "$d/a/docs/work/f/index.md" "$base"); rc=$?
[ $rc = 1 ] || bad "AC1 exit $rc, want 1 (clean lane fails)"
grep -q '^LANE full: PASS start=[0-9]* end=[0-9]*$' <<<"$out" || bad "AC1 full header: $out"
grep -q '^LANE clean: FAIL start=[0-9]* end=[0-9]* unset=NEEDED$' <<<"$out" || bad "AC1 clean header: $out"
grep -qx '  FAILED tests/env.sh' <<<"$out" || bad "AC1 failing test not named: $out"
fs=$(field "$out" full start) fe=$(field "$out" full end) cs=$(field "$out" clean start) ce=$(field "$out" clean end)
[ "$fs" -lt "$ce" ] && [ "$cs" -lt "$fe" ] || bad "AC1 windows do not overlap: full $fs-$fe, clean $cs-$ce"
# the full lane records its failing test names too
mkrepo "$d/f" no; echo false > "$d/f/tests/bad.sh"; git -C "$d/f" add -A; git -C "$d/f" commit -qm bad
out2=$("$s/review-lanes" "$d/f/docs/work/f/index.md" "$(git -C "$d/f" rev-parse HEAD)"); rc=$?
[ $rc = 1 ] && grep -q '^LANE full: FAIL ' <<<"$out2" || bad "AC1 full lane FAIL not recorded (exit $rc): $out2"
for l in full clean; do
  awk -v l="$l:" '/^LANE /{on=($2==l)} on' <<<"$out2" | grep -qx '  FAILED tests/bad.sh' || bad "AC1 $l lane did not name tests/bad.sh: $out2"
done

# US-1.AC3
# NEEDED=1 is exported by the caller, so only the lane's env -u makes the test fail; the full lane reads .env and passes
grep -q '^LANE clean: FAIL .* unset=NEEDED$' <<<"$out" && grep -qx '  FAILED tests/env.sh' <<<"$out" || bad "AC3 test or variable not named: $out"
! grep -q 'NEEDED=1' <<<"$out" || bad "AC3 printed the value"
grep -q '^LANE full: PASS ' <<<"$out" || bad "AC3 full lane did not pass with the env file"

# US-1.AC4
# after the failing run above
[ "$(git -C "$d/a" worktree list | wc -l | tr -d ' ')" = 1 ] || bad "AC4 fail run left worktrees: $(git -C "$d/a" worktree list)"
[ -z "$(ls "$TMPDIR" | grep '^review-lanes\.')" ] || bad "AC4 fail run left temp dirs"
# and after a passing run
mkrepo "$d/b" no; base=$(git -C "$d/b" rev-parse HEAD)
out=$("$s/review-lanes" "$d/b/docs/work/f/index.md" "$base"); rc=$?
[ $rc = 0 ] && grep -q '^LANE clean: PASS ' <<<"$out" || bad "AC4 pass run (exit $rc): $out"
[ "$(git -C "$d/b" worktree list | wc -l | tr -d ' ')" = 1 ] || bad "AC4 pass run left worktrees: $(git -C "$d/b" worktree list)"
[ -z "$(ls "$TMPDIR" | grep '^review-lanes\.')" ] || bad "AC4 pass run left temp dirs"

[ $fail = 0 ] && echo "OK review-lanes-test"; exit $fail
