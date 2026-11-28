# F05 Repeated errors print by count

Spec: docs/work/retro-log/spec.md
Blocked by: none
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
# six repeated errors, the most frequent one logged last
fresh
for w in alpha beta gamma delta epsilon zeta; do
  err "$main/$sid.jsonl" 2026-01-01T00:00:01Z "$w broke"; err "$main/$sid.jsonl" 2026-01-01T00:00:02Z "$w broke"
done
err "$main/$sid.jsonl" 2026-01-01T00:00:03Z "zeta broke"
rep=$(section "$("$here/retro-log" "$wt" 2>&1)" "Repeated errors")
check "top five by count, most frequent logged last" "$(head -1 <<<"$rep")" "3x zeta broke"
```
Fails on mutations/US-1.AC1.diff (`errors.most_common()` -> `errors.items()`), which prints `2x alpha broke` first and drops `3x zeta broke`.

## Approach

Append the case; keep the existing top-five case. The AC is already true, so the test passes on current code: prove it by `git apply docs/work/retro-log/mutations/US-1.AC1.diff`, seeing it fail, then reverting. Commit it as `test(US-1.AC1): guard` with that patch as a fenced diff under `Mutation:` in the commit body.
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.

## Constraints

- Checks print a `Fix:` line saying how to repair what they flag (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Any change to skills/retro/scripts/retro-log.
