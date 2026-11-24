# T13 Shipped modes: delivers blocks, the other three warn

Spec: docs/work/workflow-speed/spec.md
Blocked by: T08, T10

## Delivers

- US-6.AC1: Given the shipped settings, when a check runs, then the delivers check (US-2) blocks, and the wording (US-3), guard patch (US-4) and earlier-tests (US-5) checks warn.

## Files

- test: skills/build/scripts/test/shipped-modes-test.sh

## Interfaces

- Consumes: skills/build/checks.conf and `wf mode` from T02; the delivers finding from T01; the wording finding from T08; the guard-patch "Mutation has no patch" finding from T06; the earlier-tests finding from T09
- Consumes: the merged work of T10 (runs last: the earlier-tests check in `wf done` is complete only after T10, and this test runs `wf done`)
- Consumes: `fx_repo`, `fx_commit`, `fx_ticket`, `fx_guard`, `FX_VERIFY` from skills/build/scripts/test/lib-fixture.sh (T01, T06)

## Tests

The test file's header: `set -u`, `unset CHECKS_CONF` (the shipped skills/build/checks.conf is what runs), `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL shipped-modes-test: $*"; fail=1; }`, sources `lib-fixture.sh`, `s=$(cd "$(dirname "$0")/.." && pwd)`, `py=${1:-python3}`. Copy the `pyrepo` helper from wording-test.sh (T08) and the `lead` and `merge_ticket` helpers from earlier-tests-test.sh (T09). Ends `[ $fail = 0 ] && echo "OK shipped-modes-test"; exit $fail`.

### US-6.AC1 (guard)
File: skills/build/scripts/test/shipped-modes-test.sh
```bash
# delivers blocks
fx_repo "$d/r1"; base=$(git -C "$d/r1" rev-parse HEAD)
fx_commit "$d/r1" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null; fx_commit "$d/r1" 'feat: green' app.txt 2 >/dev/null
fx_ticket "$d/f1/tickets/T01-x.md" '- US-1.AC1: Given a, when b, then c' '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/f1/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "delivers does not block (exit $rc): $out"
# guard patch warns
fx_repo "$d/r2"; base=$(git -C "$d/r2" rev-parse HEAD)
echo 'Mutation: app.txt: 1 -> 3 -> fails' > "$d/b2"; fx_guard "$d/r2" US-1.AC1 tests/g1.sh 'grep -qx 1 app.txt' "$d/b2" >/dev/null
out=$("$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] && grep -q '^WARN guard-patch US-1.AC1 .*: Mutation has no patch\. Fix: ' <<<"$out" || bad "guard-patch does not warn (exit $rc): $out"
# wording warns
if "$py" -c 'import pytest' 2>/dev/null; then
  pyrepo "$d/r3" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
  fx_ticket "$d/f3/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$("$s/check-red-green.sh" "$d/r3" "$base" "cd pkg && $py -m pytest -q -p no:cacheprovider" "$d/f3/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] && grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED ' <<<"$out" || bad "wording does not warn (exit $rc): $out"
else echo "SKIP shipped-modes-test wording: no python with pytest"; fi
# earlier tests warn, and the ticket is recorded done
lead "$d/r4"; merge_ticket "$d/r4" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/r4" t2 'feat: T2 code' tests/t1.sh 'true')
out=$("$s/wf" done "$d/r4/docs/work/f/index.md" T02 "$m"); rc=$?
[ $rc = 0 ] && grep -q '^WARN earlier-tests tests/t1.sh: T02 ' <<<"$out" || bad "earlier-tests does not warn (exit $rc): $out"
```
Mutation to prove it: flip any one line of skills/build/checks.conf (e.g. `wording=block`); the matching part fails. Restore it after.

## Approach

none

## Constraints

- Spec Decisions: a check in `warn` mode never stops an AFK run and never blocks a merge.
- Project CLAUDE.md: a check's own test asserts the `Fix:` text (the per-check tests in T01 to T10 hold the full Fix strings; this test pins only the shipped modes).

## Verify

`bash skills/build/scripts/test/shipped-modes-test.sh python3`

## Out of scope

- Changing checks.conf or any check.
