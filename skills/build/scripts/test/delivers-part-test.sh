#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL delivers-part-test: $*"; fail=1; }
. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)

r=$d/r; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
head=$(fx_commit "$r" 'feat(US-1.AC1): green' app.txt 2)
mkdir -p "$d/feat"
printf '# X: build index\n\nBase: origin/main\n\n| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | doing |\n| P2 | b | P1 | todo |\n\n## Parts\n\n- P1: US-1.AC1, US-1.AC2; files: app.txt\n- P2: US-1.AC3; files: other.txt\n' > "$d/feat/index.md"
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/index.md:P1"); rc=$?
[ $rc = 1 ] || bad "US-3.AC6 exit $rc, want 1: $out"
grep -qxF "FAIL delivers US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${base:0:8}..${head:0:8}. Fix: add the red commit for US-1.AC2 (or a guard with a Mutation patch if the code already does it); a prefactor's Delivers says none." <<<"$out" || bad "US-3.AC6 no delivers line for US-1.AC2: $out"
! grep -qE 'delivers US-1.AC(1|3)' <<<"$out" || bad "US-3.AC6 flagged an AC the part delivers or does not own: $out"
[ ! -e "$d/feat/tickets" ] || bad "US-3.AC6 fixture has a tickets folder"

out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/index.md:P9"); rc=$?
[ $rc = 2 ] && [ "$out" = "ERROR no line for P9 under \"## Parts\" in $d/feat/index.md. Fix: pass <index.md>:<part id> for a part the index lists under ## Parts." ] || bad "unknown part (exit $rc): $out"

[ $fail = 0 ] && echo "OK delivers-part-test"; exit $fail
