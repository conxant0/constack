#!/usr/bin/env bash
set -u
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
bad() { echo "FAIL check-review-warnings-test: $*"; fail=1; }
wf=$(cd "$(dirname "$0")/.." && pwd)/wf

R=$d/r
mkdir -p "$R/docs/work/f"
git -C "$R" init -q
git -C "$R" config user.email t@t; git -C "$R" config user.name t
echo '- US-1.AC1: Given a, when b, then c' > "$R/docs/work/f/spec.md"
git -C "$R" add -A; git -C "$R" commit -q -m init
head=$(git -C "$R" rev-parse HEAD)
printf '| T03 | x | none | done abc12345 |\n| T04 | z | none | done def67890 |\n| T05 | y | none | todo |\n' > "$R/docs/work/f/index.md"
review() {
  { echo 'Verdict: FAIL'; echo 'Spec: docs/work/f/spec.md'; echo "Range: $head...$head"
    echo; echo '## Fix tickets'; echo 'F01 x: fixes US-1.AC1'
    echo; echo '## OPEN'; echo 'none'
    echo; echo '## Check warnings'; for r in "$@"; do echo "$r"; done
  } > "$R/docs/work/f/review.md"
}
review_pass() {
  { echo 'Verdict: PASS'; echo 'Spec: docs/work/f/spec.md'; echo "Range: $head...$head"
    echo; echo '## Acceptance criteria'; echo '| AC | Test | Test checks the AC | Note |'; echo '| US-1.AC1 | t | yes | |'
    echo; echo '## Fix tickets'; echo 'none'
    echo; echo '## OPEN'; echo 'none'
    echo; echo '## Check warnings'; for r in "$@"; do echo "$r"; done
  } > "$R/docs/work/f/review.md"
}
L1='wording T03 a.py:MSG: SURVIVED Keep it short.'
L2='guard-patch T05 US-2.AC1 1a2b3c4d: Mutation has no patch'

printf '%s\n%s\n' "$L1" "$L2" > "$R/docs/work/f/check-warnings.log"
fixL2="Fix: add \"- $L2 real: <reason> (F<nn>)\" or \"- $L2 false alarm: <reason>\" under ## Check warnings."
review "- $L1 false alarm: describes, states no rule"
out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
[ $rc = 1 ] || bad "AC6 exit $rc, want 1"
grep -qF "check warning not graded: $L2. $fixL2" <<<"$out" || bad "AC6 L2 not named: $out"
! grep -qF "check warning not graded: $L1" <<<"$out" || bad "AC6 flagged the graded L1: $out"
review "- $L1" "- $L2 false alarm: x"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 bare row accepted: $out"
review "- wording T03 a.py:OTHER: SURVIVED x. false alarm: y" "- $L2 false alarm: x"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 other row accepted: $out"
review "- $L2 false alarm: x"; f=$R/docs/work/f/review.md
awk -v r="- $L1 false alarm: x" '{print} /^## OPEN/{print r}' "$f" > "$f.t" && mv "$f.t" "$f"
out=$("$wf" check-review "$f")
grep -qF "check warning not graded: $L1. " <<<"$out" || bad "AC6 row outside ## Check warnings accepted: $out"

rm -f "$R/docs/work/f/check-warnings.log"; review
out=$("$wf" check-review "$R/docs/work/f/review.md")
! grep -qi 'check warning' <<<"$out" || bad "AC7 no log: $out"
: > "$R/docs/work/f/check-warnings.log"
out=$("$wf" check-review "$R/docs/work/f/review.md")
! grep -qi 'check warning' <<<"$out" || bad "AC7 empty log: $out"

printf '%s\n%s\n' "$L1" "$L2" > "$R/docs/work/f/check-warnings.log"
review "- $L1 real: states the length rule US-3.AC1 carries" "- $L2 real: guard proves nothing (F02)"
out=$("$wf" check-review "$R/docs/work/f/review.md")
grep -qF "check warning graded real names no fix ticket: $L1. Fix: end the row with (F<nn>), the fix ticket step 8 writes for it." <<<"$out" || bad "AC11 L1 not named: $out"
! grep -qF "names no fix ticket: $L2" <<<"$out" || bad "AC11 flagged L2 that names F02: $out"
! grep -qF 'check warning not graded' <<<"$out" || bad "AC11 real rows counted as ungraded: $out"

printf '%s\n' "$L1" > "$R/docs/work/f/check-warnings.log"
review_pass "- $L1 real: states the length rule US-3.AC1 carries (fixed in T03)"
out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
[ $rc = 0 ] || bad "AC14 exit $rc, want 0: $out"
! grep -qi 'check warning' <<<"$out" || bad "AC14 flagged a fixed-in row: $out"

for t in T09 T05; do
  review_pass "- $L1 real: states the length rule US-3.AC1 carries (fixed in $t)"
  out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
  [ $rc = 1 ] || bad "AC15 [$t] exit $rc, want 1"
  grep -qF "check warning fixed-in names no done ticket: $L1. Fix: name a ticket the index records done, or grade it real: <reason> (F<nn>) with a fix ticket." <<<"$out" || bad "AC15 [$t] line: $out"
done

mv "$R/docs/work/f/index.md" "$d/index.md"
review_pass "- $L1 real: states the length rule US-3.AC1 carries (fixed in T03)"
out=$("$wf" check-review "$R/docs/work/f/review.md"); rc=$?
[ $rc = 1 ] || bad "AC15 [no index] exit $rc, want 1"
grep -qF "check warning fixed-in names no done ticket: $L1. Fix: name a ticket the index records done, or grade it real: <reason> (F<nn>) with a fix ticket." <<<"$out" || bad "AC15 [no index] line: $out"
mv "$d/index.md" "$R/docs/work/f/index.md"

[ $fail = 0 ] && echo "OK check-review-warnings-test"; exit $fail
