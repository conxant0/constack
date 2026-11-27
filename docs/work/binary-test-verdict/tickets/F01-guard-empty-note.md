# F01 guard an empty Note and a late "Mutation:"

Spec: docs/work/binary-test-verdict/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria, row US-1.AC2 (mutations/US-1.AC2.diff)

## Delivers

- US-1.AC2: Given a review whose AC table has a row graded "no" and a Note that does not start with "Mutation:", when the review check runs, then it exits 1, names that row, and its Fix line says to start the Note with "Mutation:", the production change that makes the AC false and the test command that still passed, or to grade the row yes.

## Files

- test: skills/build/scripts/test/binary-verdict-test.sh

## Interfaces

- Consumes: `wf check-review <review.md> [head]` from skills/build/scripts/wf

## Tests

### US-1.AC2
File: skills/build/scripts/test/binary-verdict-test.sh
Add these two lines right after the line `review FAIL no 'Mutation: mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: no with Mutation under FAIL" 0 ""`:
```bash
review FAIL no ''; expect "AC2: no with an empty Note under FAIL" 1 "$NOTE"
review FAIL no 'see Mutation: mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: Mutation: not at the start of the Note" 1 "$NOTE"
```
The code is already right, so both pass on arrival. The first fails when `cell[5] !~ /^ *Mutation:/` in skills/build/scripts/wf becomes `cell[5] !~ /^ *(Mutation:|$)/` (docs/work/binary-test-verdict/mutations/US-1.AC2.diff); the second fails when it becomes `cell[5] !~ /Mutation:/`.

## Approach

none.
Ruling 2026-11-27 (final-review): skills/build/scripts/test/binary-verdict-test.sh may change: two cases are added, no existing line changes.

## Constraints

- Every check prints a `Fix:` and the check's own test asserts the `Fix:` text (CLAUDE.md, Code rules): both cases compare the whole line against `$NOTE`.

## Verify

`bash skills/build/scripts/test/binary-verdict-test.sh`

## Out of scope

- Any change to skills/build/scripts/wf or to another test file.
