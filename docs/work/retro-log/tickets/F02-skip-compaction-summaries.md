# F02 Compaction summaries are not typed messages

Spec: docs/work/retro-log/spec.md
Blocked by: F01
Fixes: review.md, Behaviour, finding 1 (compaction summary listed as typed)

## Delivers

- US-1.AC4: Given a feature's main session holding the typed message `go` and a compaction summary row (a user row marked `isCompactSummary`), when the script runs, then the typed-messages section lists exactly `go`.

## Files

- modify: skills/retro/scripts/retro-log
- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC4
File: skills/retro/scripts/test/retro-log-test.sh
```bash
fresh
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "go"
printf '{"type":"user","timestamp":"2026-01-01T00:00:02Z","isCompactSummary":true,"isVisibleInTranscriptOnly":true,"message":{"role":"user","content":"This session is being continued from a previous conversation."}}\n' >> "$main/$sid.jsonl"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "compaction summary skipped" "$msgs" "go"
```
Fails today: the summary line prints under Typed messages (probe in review.md, Behaviour).

## Approach

Key on the `isCompactSummary` marker, not the summary's text (Fable ruling: the text is harness wording that can change).
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.
Chained after F01 so the index Test command is green first (F04) and edits to the shared test file do not conflict.

## Constraints

- Checks print a `Fix:` line (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Queued commands (F03), the no-logs test (F01).
