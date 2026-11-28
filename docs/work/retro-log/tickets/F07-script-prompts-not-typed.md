# F07 Prompts from script-run sessions are not typed messages

Spec: docs/work/retro-log/spec.md
Blocked by: F06
Fixes: review.md, Behaviour 2 (US-1.AC7)

## Delivers

- US-1.AC7: Given a feature's main session where the owner typed `go` and then `/clear`, and a session started by `claude -p` (every row has `entrypoint` `sdk-cli`) holding the slash command `/final-review docs/work/x/spec.md AFK` and the plain prompt `yes, approve as written`, when the script runs, then the typed-messages section lists exactly `go` and `/clear`, in that order.

## Files

- modify: skills/retro/scripts/retro-log
- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC7
File: skills/retro/scripts/test/retro-log-test.sh
```bash
fresh
sdk=99999999-2222-3333-4444-555555555555
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "go"
typed "$main/$sid.jsonl" 2026-01-01T00:00:02Z "<command-name>/clear</command-name><command-args></command-args>"
s() { printf '{"type":"user","entrypoint":"sdk-cli","turnOrigin":"sdk","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' "$2" "$3" >> "$1"; }
s "$main/$sdk.jsonl" 2026-01-01T00:00:03Z "<command-name>/final-review</command-name><command-args>docs/work/x/spec.md AFK</command-args>"
s "$main/$sdk.jsonl" 2026-01-01T00:00:04Z "yes, approve as written"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "script-run prompts skipped" "$msgs" "go
/clear"
```
Fails on current code: both sdk-cli prompts print (measured by probe BUG C and on this worktree's real logs).

## Approach

In `typed()`, return None early for rows with `entrypoint` `sdk-cli` (Fable tried this on a scratch copy: prints only `go`, keeps `/clear`). Scheduled `/loop` fires (`turnOrigin: "scheduled"`, `entrypoint: "cli"`) are a review note, not this ticket.
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.

## Constraints

- Checks print a `Fix:` line saying how to repair what they flag (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Scheduled `/loop` fires; filtering on `turnOrigin`; any other row kind.
