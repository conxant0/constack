# F04 Merge origin/main and run the suite with run-all.sh

Spec: docs/work/retro-log/spec.md
Blocked by: none
Fixes: review.md, Full suite (LANE full and LANE clean FAIL on afk-loop-test.sh, check-mutation-test.sh, wf-test.sh)

## Delivers

none (test isolation)

## Files

- modify: docs/work/retro-log/index.md (the `Test command:` line)
- modify: TODOS.md (drop the stale "Test fixtures on Linux" entry once the merge makes it pass)

## Interfaces

none

## Tests

none: the index Test command itself is the test. It fails today (three FAIL lines, exit 1) and must exit 0 after this ticket.

## Approach

1. `git merge --no-ff origin/main` into feature/self-improve (PR #10 fixed the three tests; measured: they pass at origin/main 2dedb13; Fable measured the merge has no conflicts).
2. Set the index `Test command:` to `test/run-all.sh <python with pytest>` (or another absolute python with pytest). Measured by Fable: the old command stays red after the merge (four pytest tests now FAIL instead of SKIP with /usr/bin/python3); run-all.sh with that python prints 34 ok, exit 0. The new runner is stricter (fails on SKIP, adds the portability lint), so no check is loosened.
3. Remove the TODOS.md "Test fixtures on Linux" entry if the merged suite passes.

## Constraints

- Merges are merge commits (CLAUDE.md workflow).

## Verify

`test/run-all.sh <python with pytest>`

## Out of scope

- Any change to skills/retro or to the build tests themselves.
