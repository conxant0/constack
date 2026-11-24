#!/usr/bin/env bash
set -u
fail=0
bad() { echo "FAIL ac-covered-test: $*"; fail=1; }
. "$(dirname "$0")/../ac-covered.sh"
spec=$'intro\n- US-1.AC1: a\n- US-1.AC2: b\n- US-2.AC7b: c\n  - US-3.AC1: nested, not an AC line\n- US-4.AC1: d'
subjects=$'test(US-1.AC1): guard\ntest(US-1.AC2): red\ntest(US-4.AC1): red later\nfeat: US-4.AC1'

out=$(ac_uncovered "$subjects" - <<<"$spec"); rc=$?
[ "$out" = $'4 US-2.AC7b\n6 US-4.AC1' ] || bad "prints \"<line> <id>\" only for ACs with no exact red or guard subject, from stdin with -; got: $out
Fix: ac_uncovered must print FNR and id for each '- US-n.ACm:' line lacking an exact 'test(<id>): red' or 'test(<id>): guard' subject."
[ $rc = 1 ] || bad "exit $rc when it printed uncovered ACs, want 1
Fix: ac_uncovered must exit 1 when it printed any line."

all=$'test(US-1.AC1): red\ntest(US-1.AC2): red\ntest(US-2.AC7b): red\ntest(US-4.AC1): guard'
f=$(mktemp); trap 'rm -f "$f"' EXIT; printf '%s\n' "$spec" > "$f"
out=$(ac_uncovered "$all" "$f"); rc=$?
[ -z "$out" ] && [ $rc = 0 ] || bad "fully covered file: exit $rc, output: $out, want exit 0 and no output
Fix: ac_uncovered must exit 0 and print nothing when every AC has a red or guard subject."

[ $fail = 0 ] && echo "PASS ac-covered-test"
exit $fail
