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

[ $fail = 0 ] && echo "OK guard-patch-safety-test"; exit $fail
