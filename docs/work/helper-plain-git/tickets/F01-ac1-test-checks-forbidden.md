# F01 AC1 test checks the forms are forbidden

Spec: docs/work/helper-plain-git/spec.md
Blocked by: none
Fixes: review.md, Acceptance criteria, US-1.AC1 (graded no; mutation in mutations/US-1.AC1.diff)

## Delivers

- US-1.AC1: Given the helper prompt and the implementer prompt, when they are read, then each tells the agent to run git in its own worktree with no `cd`, no `git -C`, no `$( )` and no `{ }` group, and to split a refused command into separate plain calls instead of sending it again.

## Files

- test: skills/build/scripts/test/lint-helper-git-test.sh

## Interfaces

- Consumes: none
- Produces: none

## Tests

### US-1.AC1
File: skills/build/scripts/test/lint-helper-git-test.sh
Replace the `rule=` line in the AC1 loop (line 8) so each form must be forbidden, not just named, and the line must say not to send the command again:
```bash
  rule=$(grep -F -- 'no `cd`' "$root/$f" | grep -F -- 'no `git -C`' | grep -F -- 'no `$( )`' | grep -F -- 'no `{ }`' | grep -i 'split' | grep -i 'refused' | grep -i 'instead of sending it again')
```
and the Fix text on line 10 to:
```bash
    "add one rule line to $f that says no \`cd\`, no \`git -C\`, no \`\$( )\` and no \`{ }\`, and tells the agent to split a refused command into separate plain calls instead of sending it again."
```
It passes at HEAD. It fails with mutations/US-1.AC1.diff applied, which drops the word "no" from the helper.md rule.

## Approach

Ruling 2026-11-28 (final-review): skills/build/scripts/test/lint-helper-git-test.sh may change: the AC1 `rule=` grep and its Fix text, as given above.

## Constraints

- Every check prints a `Fix:` (CLAUDE.md, Code rules).
- No `\b` in grep patterns: BSD grep lacks it (lint-helper-git-test.sh:45).

## Verify

`bash skills/build/scripts/test/lint-helper-git-test.sh`

## Out of scope

- Any change to lint-helper-git or to the prompt texts.
- The behaviour notes in review.md.
