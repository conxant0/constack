#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL guard-patch-test: $*"; fail=1; }

. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf

# US-4.AC1
fx_repo "$d/r1"; fx_commit "$d/r1" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails'; echo '```diff'; patch_of "$d/r1" app.txt 3; echo '```'; } > "$d/b1"
mkguard "$d/r1" "$d/b1"   # mkguard re-runs fx_repo only when the repo is missing
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC1 exit $rc, want 0: $out"
grep -qxF "OK   guard US-1.AC1 ${sha:0:8}: Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails" <<<"$out" || bad "AC1 OK line: $out"
! grep -q 'guard-patch' <<<"$out" || bad "AC1 printed a guard-patch finding: $out"

# US-4.AC2
fx_repo "$d/r2"; fx_commit "$d/r2" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: other.txt: a -> b -> nothing'; echo '```diff'; patch_of "$d/r2" other.txt b; echo '```'; } > "$d/b2"
mkguard "$d/r2" "$d/b2"
out=$("$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC2 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: tests still pass with the Mutation patch applied. Fix: strengthen the test until this patch makes it fail, or pick the break the AC forbids." <<<"$out" || bad "AC2 line: $out"
grep -q "^OK   guard US-1.AC1 ${sha:0:8}: " <<<"$out" || bad "AC2 OK guard line gone: $out"

# US-4.AC3
fx_repo "$d/r3"; fx_commit "$d/r3" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 7 -> 3 -> tests/g1.sh fails'; echo '```diff'; patch_of "$d/r3" app.txt 3 | sed 's/^-1$/-7/'; echo '```'; } > "$d/b3"
mkguard "$d/r3" "$d/b3"
out=$("$s/check-red-green.sh" "$d/r3" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC3 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation patch does not apply at the guard commit. Fix: regenerate it with git diff at that commit and commit with --cleanup=verbatim (the default cleanup strips blank lines and trailing spaces)." <<<"$out" || bad "AC3 line: $out"
[ "$(cat "$d/r3/app.txt")" = 1 ] || bad "AC3 app.txt changed"

# US-4.AC4
fx_repo "$d/r4"; fx_commit "$d/r4" 'chore: other' other.txt a >/dev/null
echo 'Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails' > "$d/b4"
mkguard "$d/r4" "$d/b4"
out=$("$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC4 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation has no patch. Fix: re-do the break, save git diff -- <file>, and put it in the guard commit body in a diff fence under the Mutation: line (git commit --amend --cleanup=verbatim -F <file>)." <<<"$out" || bad "AC4 line: $out"
grep -q "^OK   guard US-1.AC1 ${sha:0:8}: Mutation: app.txt" <<<"$out" || bad "AC4 OK guard line gone: $out"
# with a ticket, the warning is logged (US-6.AC3 for this check)
fx_ticket "$d/gp/tickets/T05-g.md" '- US-1.AC1: Given a, when b, then c'
"$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY" "$d/gp/tickets/T05-g.md" >/dev/null
grep -qxF "guard-patch T05 US-1.AC1 ${sha:0:8}: Mutation has no patch" "$d/gp/check-warnings.log" || bad "guard-patch WARN not logged: $(cat "$d/gp/check-warnings.log" 2>&1)"
# block mode turns it into FAIL and exit 1 (US-6.AC2 for this check)
printf 'guard-patch=block\n' > "$d/gb.conf"
out=$(CHECKS_CONF=$d/gb.conf "$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 1 ] && grep -q "^FAIL guard-patch US-1.AC1 ${sha:0:8}: Mutation has no patch\. Fix: " <<<"$out" || bad "guard-patch block (exit $rc): $out"

[ $fail = 0 ] && echo "OK guard-patch-test"; exit $fail
