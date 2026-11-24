#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL guard-patch-safety-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf

printf 'no mutation here\n' > "$d/b5"
mkguard "$d/r5" "$d/b5"
out=$("$s/check-red-green.sh" "$d/r5" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 1 ] || bad "AC5 exit $rc, want 1"
grep -qxF "FAIL guard US-1.AC1 ${sha:0:8}: no \"Mutation: \" line in the commit body. Fix: break the code the way the AC forbids, see the test fail, restore, and add \"Mutation: <change> -> <failure>\" to the guard commit body." <<<"$out" || bad "AC5 line: $out"
! grep -q 'guard-patch' <<<"$out" || bad "AC5 also printed a guard-patch line: $out"

fx_repo "$d/r6"; fx_commit "$d/r6" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 1 -> 3 -> fails'; echo '```diff'; patch_of "$d/r6" app.txt 3; echo '```'; } > "$d/k"
echo x > "$d/r6/new.txt"; git -C "$d/r6" add -N new.txt
{ echo 'Mutation: new.txt: added -> nothing'; echo '```diff'; git -C "$d/r6" diff -- new.txt; echo '```'; } > "$d/n"
git -C "$d/r6" rm -q --cached new.txt; rm "$d/r6/new.txt"
sed 's/^-1$/-7/' "$d/k" > "$d/x"
for b in k n x; do
  mkguard "$d/r6-$b" "$d/$b"; br=$(git -C "$d/r6-$b" symbolic-ref --short HEAD)
  "$s/check-red-green.sh" "$d/r6-$b" "$base" "$FX_VERIFY" >/dev/null
  [ -z "$(git -C "$d/r6-$b" status --porcelain)" ] || bad "AC6 [$b] left changes: $(git -C "$d/r6-$b" status --porcelain)"
  [ "$(git -C "$d/r6-$b" symbolic-ref -q --short HEAD)" = "$br" ] || bad "AC6 [$b] not back on $br"
done

fx_repo "$d/r7"; fx_commit "$d/r7" 'chore: other' other.txt a >/dev/null
mkdir -p "$d/r7/tests"; printf 'grep -qx 1 app.txt\n' > "$d/r7/tests/g1.sh"; git -C "$d/r7" add tests/g1.sh
{ echo 'Mutation: tests/g1.sh: 1 -> 9 -> fails'; echo '```diff'; printf 'grep -qx 9 app.txt\n' > "$d/r7/tests/g1.sh"; git -C "$d/r7" diff -- tests/g1.sh; echo '```'; } > "$d/b7"
git -C "$d/r7" rm -q -f --cached tests/g1.sh; rm "$d/r7/tests/g1.sh"
mkguard "$d/r7" "$d/b7"
out=$("$s/check-red-green.sh" "$d/r7" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC7 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation patch changes a test file (tests/g1.sh). Fix: the patch must change production code only; break the code, not the test." <<<"$out" || bad "AC7 line: $out"
! grep -q 'tests still pass\|does not apply' <<<"$out" || bad "AC7 applied the test patch: $out"

[ $fail = 0 ] && echo "OK guard-patch-safety-test"; exit $fail
