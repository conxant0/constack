# T05 check-review grades every logged warning

Spec: docs/work/workflow-speed/spec.md
Blocked by: T04, T12

## Delivers

- US-6.AC6: Given a warning log line that review.md's `Check warnings` section does not repeat with `real: <reason>` or `false alarm: <reason>` after it, when `wf check-review` runs, then it prints a line naming that log line, with a `Fix:` line.
- US-6.AC7: Given a feature folder with no warning log, or an empty one, when `wf check-review` runs, then it prints nothing about check warnings.
- US-6.AC11: Given a `Check warnings` line marked `real` that names no fix ticket id after its reason, when `wf check-review` runs, then it prints a line naming it, with a `Fix:` line.

## Files

- modify: skills/build/scripts/wf
- modify: skills/final-review/assets/review-template.md
- modify: skills/final-review/SKILL.md
- test: skills/build/scripts/test/check-review-warnings-test.sh

## Interfaces

- Consumes: the log path `<feature folder>/check-warnings.log` and log line shape `<check> <ticket-id> <subject>: <text>` from T03
- Consumes: `wf check-review <review.md> [head]` from skills/build/scripts/wf (`check_review()`)
- Produces: `check_review()` reads `<dir of review.md>/check-warnings.log`. Rows under `## Check warnings` are `- <log line> real: <reason> (F<nn>)` or `- <log line> false alarm: <reason>`. A row grades a log line when the row minus `- ` starts with that exact log line and the rest matches `^ (real|false alarm): .+`.
- Produces: line `<review.md>:<n>: check warning not graded: <log line>. Fix: add "- <log line> real: <reason> (F<nn>)" or "- <log line> false alarm: <reason>" under ## Check warnings.` where `<n>` is the `## Check warnings` heading's line, or 1 when the section is missing.
- Produces: line `<review.md>:<n>: check warning graded real names no fix ticket: <log line>. Fix: end the row with (F<nn>), the fix ticket step 8 writes for it.` where `<n>` is that row's line; a `real` row needs `(F<digits>)` after its reason.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL check-review-warnings-test: $*"; fail=1; }`, `wf=$(cd "$(dirname "$0")/.." && pwd)/wf`. Setup: a git repo `R=$d/r` with a committed `docs/work/f/spec.md` holding one AC line `- US-1.AC1: Given a, when b, then c`, and a helper `review <rows...>` that writes `docs/work/f/review.md` with `Verdict: FAIL`, `Spec: docs/work/f/spec.md`, `Range: <head>...<head>` (head = `git rev-parse HEAD`), `## Fix tickets` with `F01 x: fixes US-1.AC1`, `## OPEN` with `none`, and `## Check warnings` followed by the given rows. Two log lines: `L1='wording T03 a.py:MSG: SURVIVED Keep it short.'` and `L2='guard-patch T05 US-2.AC1 1a2b3c4d: Mutation has no patch'`. Ends `[ $fail = 0 ] && echo "OK check-review-warnings-test"; exit $fail`.

### US-6.AC6
File: skills/build/scripts/test/check-review-warnings-test.sh
```bash
printf '%s\n%s\n' "$L1" "$L2" > "$R/docs/work/f/check-warnings.log"
fixL2="Fix: add \"- $L2 real: <reason> (F<nn>)\" or \"- $L2 false alarm: <reason>\" under ## Check warnings."
review "- $L1 false alarm: describes, states no rule"
out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
[ $rc = 1 ] || bad "AC6 exit $rc, want 1"
grep -qF "check warning not graded: $L2. $fixL2" <<<"$out" || bad "AC6 L2 not named: $out"
! grep -qF "check warning not graded: $L1" <<<"$out" || bad "AC6 flagged the graded L1: $out"
# a row with no grade after the log line does not count
review "- $L1" "- $L2 false alarm: x"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 bare row accepted: $out"
# a row for a different log line does not grade this one
review "- wording T03 a.py:OTHER: SURVIVED x. false alarm: y" "- $L2 false alarm: x"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 other row accepted: $out"
# a graded row outside ## Check warnings does not count
review "- $L2 false alarm: x"; f=$R/docs/work/f/review.md
awk -v r="- $L1 false alarm: x" '{print} /^## OPEN/{print r}' "$f" > "$f.t" && mv "$f.t" "$f"
out=$("$wf" check-review "$f")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 row outside ## Check warnings accepted: $out"
```

### US-6.AC7 (guard)
File: skills/build/scripts/test/check-review-warnings-test.sh
```bash
rm -f "$R/docs/work/f/check-warnings.log"; review
out=$("$wf" check-review "$R/docs/work/f/review.md")
! grep -qi 'check warning' <<<"$out" || bad "AC7 no log: $out"
: > "$R/docs/work/f/check-warnings.log"
out=$("$wf" check-review "$R/docs/work/f/review.md")
! grep -qi 'check warning' <<<"$out" || bad "AC7 empty log: $out"
```
Mutation to prove it: treat a missing or empty log as one empty log line, so `check warning not graded:` prints; the test fails on the grep.

### US-6.AC11
File: skills/build/scripts/test/check-review-warnings-test.sh
```bash
printf '%s\n%s\n' "$L1" "$L2" > "$R/docs/work/f/check-warnings.log"
review "- $L1 real: states the length rule US-3.AC1 carries" "- $L2 real: guard proves nothing (F02)"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning graded real names no fix ticket: $L1. Fix: end the row with (F<nn>), the fix ticket step 8 writes for it." <<<"$out" || bad "AC11 L1 not named: $out"
! grep -qF "names no fix ticket: $L2" <<<"$out" || bad "AC11 flagged L2 that names F02: $out"
! grep -qF 'check warning not graded' <<<"$out" || bad "AC11 real rows counted as ungraded: $out"
```

## Approach

- Read the log in the shell and pass it to the existing awk as an extra input file (or a `-v` list); keep `check_review()`'s other rules and messages unchanged.
- review-template.md: add a `## Check warnings` section after `## Verify`: "<Each line of check-warnings.log, then `real: <reason> (F<nn>)` or `false alarm: <reason>`. "none" if the log is missing or empty.>".
- skills/final-review/SKILL.md:
  - Step 4: the guard's mutation is a fenced diff under `Mutation:` in the guard commit body; judge the guard by that patch.
  - Step 7: grade every `check-warnings.log` line in `## Check warnings`. A SURVIVED sentence that states a rule a delivered AC carries is `real`; any other is `false alarm`. A `real` line fails the verdict.
  - Step 8: every `real` line gets a fix ticket in that round, and its id goes in the row.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Spec Decisions: a warning graded `real` fails the verdict and gets a fix ticket in that review round; `false alarm` changes nothing.
- Prose edits follow the writing-for-agents skill.

## Verify

`bash skills/build/scripts/test/check-review-warnings-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Making a `real` row flip the Verdict in `wf check-review` (prose only, step 7).
- The script lanes text in final-review SKILL.md (T11, T12).
