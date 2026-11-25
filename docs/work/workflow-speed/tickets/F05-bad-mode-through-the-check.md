# F05 A bad mode for wording or guard-patch stops the check with exit 2

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria row US-6.AC13 (partly: modes-test.sh runs the check only for `delivers=maybe`; with check-red-green.sh:85 and :88 changed to fall back to `warn` on a bad value, the whole suite still passes)

## Delivers

- US-6.AC13: Given a settings value other than `warn` or `block`, when that check runs, then it prints an ERROR line naming the value, with a `Fix:` line, and exits 2.

## Files

- test: skills/build/scripts/test/modes-test.sh

## Interfaces

- Consumes: `check-red-green.sh <worktree> <base-sha> "<verify command>" [<ticket.md> [<ticket-start-sha>]]` in skills/build/scripts/check-red-green.sh (lines 85-88 print the ERROR line of `wf mode` and exit 2); `fx_repo`, `fx_commit`, `fx_ticket`, `FX_VERIFY` from skills/build/scripts/test/lib-fixture.sh
- Produces: none

## Tests

### US-6.AC13 (guard)
File: skills/build/scripts/test/modes-test.sh (inside the existing `for c in wording guard-patch` loop under AC13, after the `wf mode` assertion; `$r`, `$base`, `$t` are the fixture the file already builds)
```bash
  out=$(CHECKS_CONF=$d/bad-$c.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
  [ $rc = 2 ] || bad "AC13 $c through the check: exit $rc, want 2"
  [ "$out" = "ERROR $d/bad-$c.conf: $c=maybe is not warn or block. Fix: set $c=warn or $c=block in $d/bad-$c.conf." ] || bad "AC13 $c through the check printed: $out"
```
The code already does this, so the commit is `test(US-6.AC13): guard`. Its Mutation patch is one of the two fallbacks the review used, as a diff of skills/build/scripts/check-red-green.sh: line 85 `|| { echo "$guard_patch_mode"; exit 2; }` -> `|| guard_patch_mode=warn`, or line 88 the same for `wording_mode`. Each must make its own loop pass fail; put the one you commit in the diff fence and name the other in the prose line.

## Approach

- Ruling 2026-11-25 (final-review): skills/build/scripts/test/modes-test.sh may change: three assertion lines added inside the AC13 loop; no existing assertion changed or removed.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text (the exact-line comparison above does).
- No production file changes: a test that fails on arrival means the code is wrong, stop and report.

## Verify

`bash skills/build/scripts/test/modes-test.sh python3`

## Out of scope

- Any change to check-red-green.sh or wf.
- The `delivers` case, which modes-test.sh already runs through the check.
