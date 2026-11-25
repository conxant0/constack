# F03 earlier-tests ignores a ticket rewriting its own added lines

Spec: docs/work/workflow-speed/spec.md
Blocked by: F01
Fixes: review.md Behaviour finding 2 (earlier-tests warns "removed or rewrote lines" when T2's second red commit edits a line its first red commit added; probe /tmp/fr-beh/p6b-import-line.sh)

## Delivers

- US-5.AC9: Given a test file that existed at Base or that T1's red commit touched, T2's first red commit only adds lines to it, and T2's second red commit rewrites a line the first one added and leaves every line the file had when T2 started, with no matching `may change:` line, when `wf done` runs for T2, then it prints no warning for that file.

## Files

- modify: skills/build/scripts/earlier-tests.sh
- test: skills/build/scripts/test/earlier-tests-block-test.sh

## Interfaces

- Consumes: `earlier_tests <index> <id> <sha>` in skills/build/scripts/earlier-tests.sh (its `s` = the ticket's start, `p` = protected files); `lead`, `merge_ticket` from skills/build/scripts/test/lib-lead.sh
- Produces: a red or guard commit on a file in `p` warns only when some line the file had at `s` is missing from the file after that commit (a deleted file counts as all lines missing). Warn text and Fix unchanged.

## Tests

### US-5.AC9
File: skills/build/scripts/test/earlier-tests-block-test.sh (append before the final line)
```bash
for where in base t1; do
  lead "$d/h-$where"
  if [ $where = base ]; then f=tests/base.sh; else f=tests/t1.sh; merge_ticket "$d/h-$where" t1 'test(US-1.AC1): red' $f 'test -f app.txt' >/dev/null; fi
  old=$(cat "$d/h-$where/$f")
  m=$(merge_ticket "$d/h-$where" t2 'test(US-2.AC1): red' $f "$old"$'\nA=1; test -r app.txt' 'test(US-2.AC2): red' $f "$old"$'\nA=2; test -r app.txt\ntest -s app.txt')
  out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/h-$where/docs/work/f/index.md" T02 "$m")
  ! grep -q "earlier-tests $f" <<<"$out" || bad "AC9 [$where] warned on a rewrite of T2's own line: $out"
done
```

## Approach

- Only the red/guard branch of the check changes; the `other` branch (any non-red edit warns) stays.
- Compare each red/guard commit's file against `git show <s>:<file>` lines (e.g. `comm`/`grep -vxFf` on sorted copies); a file absent at `s` that is in `p` cannot happen for a red edit, keep today's behaviour there.
- Existing AC6 (rewrite and delete of T1's line) and AC7 (add-only) cases must stay green unchanged.

## Constraints

- Spec Decisions: a ruling line `... <path> may change:` still exempts the file.
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.

## Verify

`bash skills/build/scripts/test/earlier-tests-block-test.sh && bash skills/build/scripts/test/earlier-tests-test.sh && bash skills/build/scripts/test/shipped-modes-test.sh`

## Out of scope

- A later red in one ticket weakening that ticket's own earlier test (US-5 is about later tickets).
