# F02 guard text deleted between f-string placeholders

Spec: docs/work/binary-test-verdict/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria, row US-1.AC4 (mutations/US-1.AC4.diff)

## Delivers

- US-1.AC4: Given a "no" row whose patch changes only the words inside a text string, when the mutation check runs, then it exits 1, names the row, and its Fix line says wording is the wording check's job and to grade the row yes.

## Files

- test: skills/build/scripts/test/check-mutation-test.sh

## Interfaces

- Consumes: `check-mutation <review.md>` from skills/build/scripts/check-mutation

## Tests

### US-1.AC4
File: skills/build/scripts/test/check-mutation-test.sh
Add these two lines right after the line `review nocmd "Mutation: mutations/wording.diff"` (before `git add -A && git commit -qm fixture`):
```bash
mkpatch fpiece 's/{GREETING} Welcome, {name}\./{GREETING}{name}/'
review fpiece "Mutation: mutations/fpiece.diff; $TESTS"
```
Add this line right before the line that starts `expect "missing patch" 2`:
```bash
expect "AC4: text between two f-string placeholders deleted" 1 "$(at fpiece): the patch mutations/fpiece.diff changes only wording. Fix: wording is the wording check's job (mutate-copy); grade the row yes." fpiece
```
The code is already right, so the case passes on arrival. It fails (exit 0, no output) when the `ast.JoinedStr` line in skills/build/scripts/check-mutation becomes `if 0: pass` (docs/work/binary-test-verdict/mutations/US-1.AC4.diff).

## Approach

none.
Ruling 2026-11-27 (final-review): skills/build/scripts/test/check-mutation-test.sh may change: one fixture and one case are added, no existing line changes.

## Constraints

- Every check prints a `Fix:` and the check's own test asserts the `Fix:` text (CLAUDE.md, Code rules): the case compares the whole line.

## Verify

`bash skills/build/scripts/test/check-mutation-test.sh python3`

## Out of scope

- Any change to skills/build/scripts/check-mutation or to another test file.
