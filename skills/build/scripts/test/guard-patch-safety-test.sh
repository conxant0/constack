#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL guard-patch-safety-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf

# US-4.AC5
printf 'no mutation here\n' > "$d/b5"
mkguard "$d/r5" "$d/b5"
out=$("$s/check-red-green.sh" "$d/r5" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 1 ] || bad "AC5 exit $rc, want 1"
grep -qxF "FAIL guard US-1.AC1 ${sha:0:8}: no \"Mutation: \" line in the commit body. Fix: break the code the way the AC forbids, see the test fail, restore, and add \"Mutation: <change> -> <failure>\" to the guard commit body." <<<"$out" || bad "AC5 line: $out"
! grep -q 'guard-patch' <<<"$out" || bad "AC5 also printed a guard-patch line: $out"

# US-4.AC6
fx_repo "$d/r6"; fx_commit "$d/r6" 'chore: other' other.txt a >/dev/null
# case kill: the patch makes the test fail
{ echo 'Mutation: app.txt: 1 -> 3 -> fails'; echo '```diff'; patch_of "$d/r6" app.txt 3; echo '```'; } > "$d/k"
# case new file: the patch adds a production file and the tests still pass
echo x > "$d/r6/new.txt"; git -C "$d/r6" add -N new.txt
{ echo 'Mutation: new.txt: added -> nothing'; echo '```diff'; git -C "$d/r6" diff -- new.txt; echo '```'; } > "$d/n"
git -C "$d/r6" rm -q --cached new.txt; rm "$d/r6/new.txt"
# case no apply
sed 's/^-1$/-7/' "$d/k" > "$d/x"
for b in k n x; do
  mkguard "$d/r6-$b" "$d/$b"; br=$(git -C "$d/r6-$b" symbolic-ref --short HEAD)
  "$s/check-red-green.sh" "$d/r6-$b" "$base" "$FX_VERIFY" >/dev/null
  [ -z "$(git -C "$d/r6-$b" status --porcelain)" ] || bad "AC6 [$b] left changes: $(git -C "$d/r6-$b" status --porcelain)"
  [ "$(git -C "$d/r6-$b" symbolic-ref -q --short HEAD)" = "$br" ] || bad "AC6 [$b] not back on $br"
done

[ $fail = 0 ] && echo "OK guard-patch-safety-test"; exit $fail
