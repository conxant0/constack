# F06 Messages that start with a paste are typed messages

Spec: docs/work/retro-log/spec.md
Blocked by: F05
Fixes: review.md, Behaviour 1 (US-1.AC6)

## Delivers

- US-1.AC6: Given a feature's main session where the owner typed `start`, then sent a message made of a pasted block holding `Sam: can you send me the setup page?` followed by the typed text `do the manual check via a subagent`, then sent a message made only of a pasted block holding `set up the mount`, then typed `ship it`, when the script runs, then the typed-messages section lists exactly four messages in that order: `start`, the first paste message as stored (its `<pasted_content …>` block, then `do the manual check via a subagent`), the second paste message as stored, and `ship it`.

## Files

- modify: skills/retro/scripts/retro-log
- test: skills/retro/scripts/test/retro-log-test.sh

## Interfaces

- Consumes: `retro-log [worktree path]` from skills/retro/scripts/retro-log

## Tests

### US-1.AC6
File: skills/retro/scripts/test/retro-log-test.sh
```bash
# Claude Code stores a paste as "\n\n<pasted_content id=..>TEXT</pasted_content id=..>\n\n<typed>"; the closing tag carries the id.
fresh
p1='\n\n<pasted_content id=\"7ee0\">Sam: can you send me the setup page?</pasted_content id=\"7ee0\">\n\ndo the manual check via a subagent'
p2='\n\n<pasted_content id=\"8ff1\">set up the mount</pasted_content id=\"8ff1\">'
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "start"
typed "$main/$sid.jsonl" 2026-01-01T00:00:02Z "$p1"
typed "$main/$sid.jsonl" 2026-01-01T00:00:03Z "$p2"
typed "$main/$sid.jsonl" 2026-01-01T00:00:04Z "ship it"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "paste-led messages printed as stored" "$msgs" 'start
<pasted_content id="7ee0">Sam: can you send me the setup page?</pasted_content id="7ee0">

do the manual check via a subagent
<pasted_content id="8ff1">set up the mount</pasted_content id="8ff1">
ship it'
```
Fails on current code: `typed()` returns None for any text starting with `<` without a command tag, so only `start` and `ship it` print (measured by probe BUG A). The `typed` helper writes `%s` into a JSON string, so `\n` and `\"` above are JSON escapes; the expected text assumes the script's `.strip()` drops the leading blank lines.

## Approach

In `typed()`, let text starting with `<pasted_content` fall through to `return t or None` instead of the `<` harness-row branch (Fable tried `if t.startswith("<") and not t.startswith("<pasted_content"):` on a scratch copy: it prints both messages as stored).
Ruling 2026-11-28 (final-review): skills/retro/scripts/test/retro-log-test.sh may change: new cases appended only; no existing assertion is edited.

## Constraints

- Checks print a `Fix:` line saying how to repair what they flag (CLAUDE.md, Code rules).
- No implicit state machines (CLAUDE.md, Code rules).

## Verify

`bash skills/retro/scripts/test/retro-log-test.sh`

## Out of scope

- Truncating long pastes; stripping the paste tags; queued-command pastes (already print as stored).
