# F03 guard "Mutation" without its colon

Spec: docs/work/binary-test-verdict/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria, row US-1.AC2 (mutations/US-1.AC2-colon.diff)

## Delivers

- US-1.AC2: Given a review whose AC table has a row graded "no" and a Note that does not start with "Mutation:", when the review check runs, then it exits 1, names that row, and its Fix line says to start the Note with "Mutation:", the production change that makes the AC false and the test command that still passed, or to grade the row yes.

## Files

- test: skills/build/scripts/test/binary-verdict-test.sh

## Interfaces

- Consumes: `wf check-review <review.md> [head]` from skills/build/scripts/wf

## Tests

### US-1.AC2
File: skills/build/scripts/test/binary-verdict-test.sh
Add this line right after the line that starts `review FAIL no 'see Mutation: mutations/US-1.AC2.diff; python3 -m unittest'`:
```bash
review FAIL no 'Mutation mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: Mutation without its colon" 1 "$NOTE"
```
The code is already right, so the case passes on arrival. It fails (exit 0, no output) when `cell[5] !~ /^ *Mutation:/` in skills/build/scripts/wf becomes `cell[5] !~ /^ *Mutation/` (docs/work/binary-test-verdict/mutations/US-1.AC2-colon.diff).

## Approach

none.
Ruling 2026-11-27 (final-review): skills/build/scripts/test/binary-verdict-test.sh may change: one case is added, no existing line changes.

## Constraints

- Every check prints a `Fix:` and the check's own test asserts the `Fix:` text (CLAUDE.md, Code rules): the case compares the whole line against `$NOTE`.

## Verify

`bash skills/build/scripts/test/binary-verdict-test.sh`

## Out of scope

- Any change to skills/build/scripts/wf or to another test file.
