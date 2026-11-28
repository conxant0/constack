# F01 No-logs check holds when other features have logs

Spec: docs/work/retro-log/spec.md
Blocked by: F04
Fixes: review.md, Acceptance criteria, US-1.AC1 (Mutation: mutations/US-1.AC1.diff)

## Delivers

- US-1.AC1: Given a feature's log folder where a main session holds the tool error `worktree agent-a1c refused, exit 1`, a helper subagent log holds `worktree agent-b2d refused, exit 2`, a scratch run started from that session's scratchpad holds `worktree agent-e5f refused, exit 3`, a different feature's log folder holds the same error, and another error appears once, when the script runs for that feature's worktree path, then the repeated-errors section shows exactly one line, that error with its id and numbers stripped and the count 3, and not the single error; given six different repeated errors it shows only the five most frequent; given a worktree path with no log folder it prints exactly `no logs on this machine` and exits 0.

## Files

- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC1
File: skills/retro/scripts/test/retro-log-test.sh
```bash
# no-logs case while the projects folder exists and holds another feature's logs
fresh   # creates $proj with the feat folder; other features exist beside it
out=$("$here/retro-log" "$d/work/none" 2>&1); rc=$?
check "no logs beside other features" "$rc $out" "0 no logs on this machine"
```
Fails on mutations/US-1.AC1.diff (`if not projects.is_dir():`), which prints the two empty section headers instead.

## Approach

Add the case; keep the existing no-config-dir case. The test is test-first against a mutation, so it passes on current code: prove it by applying `git apply docs/work/retro-log/mutations/US-1.AC1.diff`, seeing it fail, then reverting. Commit it as `test(US-1.AC1): guard` with that patch as a fenced diff under `Mutation:` in the commit body.
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.
Chained after F04 so the index Test command is green first (F04) and edits to the shared test file do not conflict.

## Constraints

- Checks print a `Fix:` line saying how to repair what they flag (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Any change to skills/retro/scripts/retro-log.
