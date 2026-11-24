# F02 check-review accepts a real warning already fixed in /build

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Behaviour finding 1 (a warning fixed in the build fix round stays in check-warnings.log; check-review accepts only an F ticket or a false `false alarm`; probes /tmp/fr-beh/p9-stale-wording.sh, /tmp/fr-beh/p8-stale-warning.sh)

## Delivers

- US-6.AC14: Given a review.md whose Verdict is PASS and whose Fix tickets section is none, and a warning log line that the Check warnings section repeats followed by `real: <reason> (fixed in <ticket id>)`, where the index beside the spec records that ticket done, when `wf check-review` runs, then it prints nothing about that row and exits 0.
- US-6.AC15: Given the same row naming a ticket id the index has no row for, or a row not recorded done, when `wf check-review` runs, then it prints a line naming that log line, with a `Fix:` line.

## Files

- modify: skills/build/scripts/wf
- modify: skills/final-review/SKILL.md (steps 7 and 8: the `(fixed in <ticket id>)` grade)
- modify: skills/final-review/assets/review-template.md (Check warnings placeholder)
- test: skills/build/scripts/test/check-review-warnings-test.sh

## Interfaces

- Consumes: `check_review <review.md> [<head>]` in skills/build/scripts/wf (the awk grading loop over `lg[]` and `cw[]`, ~lines 491-494); the index is `index.md` in the review's folder, rows `| <id> | <title> | <blocked by> | done <sha> |`
- Produces: a `real: <reason> (fixed in <id>)` row is accepted when that id's index row status starts `done`; otherwise `<review.md>:<row line>: check warning fixed-in names no done ticket: <log line>. Fix: name a ticket the index records done, or grade it real: <reason> (F<nn>) with a fix ticket.`

## Tests

The fixture (check-review-warnings-test.sh `review()`) gains an index beside review.md: `printf '| T03 | x | none | done abc12345 |\n| T05 | y | none | todo |\n' > "$R/docs/work/f/index.md"`, and a PASS variant of `review` (Verdict PASS, Fix tickets none, OPEN none, an AC table row for US-1.AC1).

### US-6.AC14
File: skills/build/scripts/test/check-review-warnings-test.sh
```bash
printf '%s\n' "$L1" > "$R/docs/work/f/check-warnings.log"
review_pass "- $L1 real: states the length rule US-3.AC1 carries (fixed in T03)"
out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
[ $rc = 0 ] || bad "AC14 exit $rc, want 0: $out"
! grep -qi 'check warning' <<<"$out" || bad "AC14 flagged a fixed-in row: $out"
```

### US-6.AC15
File: skills/build/scripts/test/check-review-warnings-test.sh
```bash
for t in T09 T05; do
  review_pass "- $L1 real: states the length rule US-3.AC1 carries (fixed in $t)"
  out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
  [ $rc = 1 ] || bad "AC15 [$t] exit $rc, want 1"
  grep -qF "check warning fixed-in names no done ticket: $L1. Fix: name a ticket the index records done, or grade it real: <reason> (F<nn>) with a fix ticket." <<<"$out" || bad "AC15 [$t] line: $out"
done
```

## Approach

- Ruling 2026-11-24 (final-review): `skills/build/scripts/test/check-review-warnings-test.sh` may change: add an index.md to the fixture and a PASS variant of `review()`; every existing assertion stays as it is.
- Pass the index (if readable) to the awk as one more input; collect `done` ids from it.
- Keep the two existing Fix texts (`check warning not graded` and `graded real names no fix ticket`) exactly: lines 26 and 53 of the test assert them.

## Constraints

- Spec Decisions: a fixed `real` row changes nothing and is not a false alarm.
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.

## Verify

`bash skills/build/scripts/test/check-review-warnings-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Removing lines from check-warnings.log.
- Proving the fix happened (the reason text carries that, as for `false alarm`).
