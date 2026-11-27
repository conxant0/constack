#!/usr/bin/env bash
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
mkdir -p "$d/docs/work/x" "$d/src"; git -C "$d" init -q -b main; git -C "$d" config user.email t@t; git -C "$d" config user.name t
printf '# X\n\nStatus: approved\nBranch: b\nBase: main\nDate: 2026-11-27\n\n## User stories\n\n### US-1 One\n\n- US-1.AC1: Given a, when b, then c.\n- US-1.AC2: Given a, when b, then d.\n\n## Out of Scope\n\n- y\n\n## Manual check\n\n1. z\n' > "$d/docs/work/x/spec.md"
echo a > "$d/src/a.py"; git -C "$d" add -A; git -C "$d" commit -qm base; end=$(git -C "$d" rev-parse HEAD)
R=$d/docs/work/x/review.md
review() {
  local tk=none; [ "$1" = FAIL ] && tk='F01 a: fixes US-1.AC2'
  printf '# X: final review\n\nVerdict: %s\nSpec: docs/work/x/spec.md\nRange: main...%s\nMode: full\nDate: 2026-11-27\n\n## Acceptance criteria\n\n| AC | Red commit | Test checks the AC | Note |\n|---|---|---|---|\n| US-1.AC1 | abc | yes | |\n| US-1.AC2 | def | %s | %s |\n\n## Fix tickets\n\n%s\n\n## OPEN\n\nnone.\n' "$1" "$end" "$2" "$3" "$tk" > "$R"
}
expect() {
  local out rc; out=$("$wf" check-review "$R" 2>&1); rc=$?
  if [ "$rc" != "$2" ] || [ "$out" != "$3" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$1" "$rc" "$out" "$2" "$3"; fail=1
  fi
}

PARTLY="$R:14: US-1.AC2 says \"partly\" under Test checks the AC. Fix: grade the row yes or no (step 4): no when a production change makes the AC false and its tests still pass, else yes."
review PASS partly ''; expect "AC1: partly under PASS" 1 "$PARTLY"
review FAIL partly ''; expect "AC1: partly under FAIL" 1 "$PARTLY"

NOTE="$R:14: US-1.AC2 says \"no\" under Test checks the AC, but its Note does not start with \"Mutation:\". Fix: start the Note with \"Mutation: <patch file beside this review>; <the test command that still passed>\", or grade the row yes."
review FAIL no 'tests look thin'; expect "AC2: no without Mutation under FAIL" 1 "$NOTE"
review PASS no 'tests look thin'; out=$("$wf" check-review "$R" 2>&1); rc=$?
[ $rc = 1 ] && grep -qFx "$NOTE" <<<"$out" || { printf 'FAIL AC2: no without Mutation under PASS: exit %s, got:\n%s\n' "$rc" "$out"; fail=1; }
review FAIL no 'Mutation: mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: no with Mutation under FAIL" 0 ""
review FAIL no ''; expect "AC2: no with an empty Note under FAIL" 1 "$NOTE"
review FAIL no 'see Mutation: mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: Mutation: not at the start of the Note" 1 "$NOTE"
review FAIL no 'Mutation mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC2: Mutation without its colon" 1 "$NOTE"

PASSNO="$R:14: US-1.AC2 says \"no\" under Test checks the AC, but Verdict is PASS. Fix: set Verdict: FAIL and write an F ticket for it (step 8)."
review PASS no 'Waived 2026-11-02 (owner): flaky'; expect "AC3: a waived no under PASS" 1 "$PASSNO
$NOTE"
review PASS no 'Mutation: mutations/US-1.AC2.diff; python3 -m unittest'; expect "AC3: a no with Mutation under PASS" 1 "$PASSNO"
out=$("$wf" check-review "$R" 2>&1); ! grep -qi 'waive' <<<"$out" || { printf 'FAIL AC3: output mentions a waiver:\n%s\n' "$out"; fail=1; }

[ $fail = 0 ] && echo "OK binary-verdict-test"
exit $fail
