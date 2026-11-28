# F03 Messages typed mid-turn are typed messages

Spec: docs/work/retro-log/spec.md
Blocked by: F02
Fixes: review.md, Behaviour, finding 2 (queued messages typed mid-turn missing)

## Delivers

- US-1.AC5: Given a feature's main session where the owner typed `start`, then, while the agent was working, `do the manual check via a subagent` (a queued command from a human), then `ship it`, and where a helper's hand-back (a queued command from a peer) and a task notification (a queued command from a task notification) were queued the same way, when the script runs, then the typed-messages section lists exactly `start`, `do the manual check via a subagent` and `ship it`, in that order.

## Files

- modify: skills/retro/scripts/retro-log
- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC5
File: skills/retro/scripts/test/retro-log-test.sh
```bash
fresh
q() { printf '{"type":"attachment","timestamp":"%s","attachment":{"type":"queued_command","prompt":"%s","origin":{"kind":"%s"}}}\n' "$2" "$3" "$4" >> "$1"; }
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "start"
q "$main/$sid.jsonl" 2026-01-01T00:00:02Z "do the manual check via a subagent" human
q "$main/$sid.jsonl" 2026-01-01T00:00:03Z "helper hand-back report" peer
q "$main/$sid.jsonl" 2026-01-01T00:00:04Z "task finished" task-notification
typed "$main/$sid.jsonl" 2026-01-01T00:00:05Z "ship it"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "queued human message in time order" "$msgs" "start
do the manual check via a subagent
ship it"
```
Fails today: the queued human message is missing.

## Approach

Read `type:"attachment"` rows whose `attachment.type` is `queued_command` and `attachment.origin.kind` is `human`; the text is `attachment.prompt`, the time the row's `timestamp`. Measured on real logs: origins are human, peer, and task-notification. Blocked by F02 only because both edit `typed()`.
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.
Chained after F02 so the index Test command is green first (F04) and edits to the shared test file do not conflict.

## Constraints

- No implicit state machines; checks print a `Fix:` line (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- A harness note that carries origin human ("Here is a note offered by a side agent"): left as known noise (Fable ruling).
