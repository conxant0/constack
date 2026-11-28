# F08 Scheduled wakeups are not typed messages

Spec: docs/work/retro-log/spec.md
Blocked by: none
Fixes: review.md, Behaviour 1 (US-1.AC8)

## Delivers

- US-1.AC8: Given a feature's main session where the owner typed `/steward 483`, and the scheduler later sent `/steward --tend 483` three times and the plain prompt `check the deploy` once (rows with `turnOrigin` `scheduled`), when the script runs, then the typed-messages section lists exactly `/steward 483`.

## Files

- modify: skills/retro/scripts/retro-log
- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC8
File: skills/retro/scripts/test/retro-log-test.sh
```bash
fresh
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "<command-name>/steward</command-name><command-args>483</command-args>"
w() { printf '{"type":"user","entrypoint":"cli","turnOrigin":"scheduled","wakeupSource":"loop_wakeup","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' "$2" "$3" >> "$1"; }
for i in 2 3 4; do w "$main/$sid.jsonl" 2026-01-01T00:00:0${i}Z "<command-name>/steward</command-name><command-args>--tend 483</command-args>"; done
w "$main/$sid.jsonl" 2026-01-01T00:00:05Z "check the deploy"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "scheduled wakeups skipped" "$msgs" "/steward 483"
```
Fails on current code: prints `/steward 483`, `3x /steward --tend 483`, `check the deploy` (measured by the review's probe-loop.sh).

## Approach

In `typed()`, return None early for rows with `turnOrigin` `scheduled` (all 10 real scheduled rows on this machine carry it; keying on a missing `origin` would drop real typed rows and break the existing fixtures, which write no `origin`).
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.

## Constraints

- Checks print a `Fix:` line saying how to repair what they flag (CLAUDE.md, Code rules).
- Run suites as `PYTEST_PYTHON=<python with pytest> <Test command>`; never commit the path.

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Malformed-row crashes (review note); any other row kind.
