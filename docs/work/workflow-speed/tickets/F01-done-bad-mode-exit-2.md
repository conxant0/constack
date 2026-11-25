# F01 wf done exits 2 on a bad earlier-tests mode

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria row US-6.AC13 (partly: `wf done` with `earlier-tests=blok` prints the ERROR and Fix but exits 1; probe /tmp/fr-beh/p4-done-badmode.sh)

## Delivers

- US-6.AC13: Given a settings value other than `warn` or `block`, when that check runs, then it prints an ERROR line naming the value, with a `Fix:` line, and exits 2.

## Files

- modify: skills/build/scripts/earlier-tests.sh
- modify: skills/build/scripts/wf
- test: skills/build/scripts/test/modes-test.sh

## Interfaces

- Consumes: `mode <check>` in skills/build/scripts/wf (prints the ERROR line, exits 2); `earlier_tests <index> <id> <sha>` in skills/build/scripts/earlier-tests.sh; `lead`, `merge_ticket` from skills/build/scripts/test/lib-lead.sh
- Produces: `earlier_tests` returns 2 when `mode earlier-tests` fails (after echoing its ERROR line), 1 on a block finding as today; `wf done` exits with 2 for the first and 1 for the second, and records nothing done in either case.

## Tests

### US-6.AC13
File: skills/build/scripts/test/modes-test.sh (append before the final line; source lib-lead.sh at the top)
```bash
. "$(dirname "$0")/lib-lead.sh"
lead "$d/done"; m=$(merge_ticket "$d/done" t2 'feat: x' app.txt 2)
printf 'earlier-tests=blok\n' > "$d/et.conf"
out=$(CHECKS_CONF=$d/et.conf "$s/wf" done "$d/done/docs/work/f/index.md" T02 "$m"); rc=$?
[ $rc = 2 ] || bad "AC13 wf done exit $rc, want 2"
[ "$out" = "ERROR $d/et.conf: earlier-tests=blok is not warn or block. Fix: set earlier-tests=warn or earlier-tests=block in $d/et.conf." ] || bad "AC13 wf done line: $out"
grep -q '^| T02 | b | T01 | todo |' "$d/done/docs/work/f/index.md" || bad "AC13 wf done recorded done on a bad mode"
```

## Approach

- earlier-tests.sh:17 `return 1` -> `return 2` on the mode failure; wf `done` keeps the callee's status (`earlier_tests ... || exit $?`).

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Existing tests stay as they are (earlier-tests-block-test.sh AC8 still wants exit 1 on a block finding).

## Verify

`bash skills/build/scripts/test/modes-test.sh && bash skills/build/scripts/test/earlier-tests-block-test.sh && bash skills/build/scripts/test/earlier-tests-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Any other exit code of `wf done`.
