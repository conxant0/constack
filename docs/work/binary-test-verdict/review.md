# Final review grades each test yes or no, on proof: final review

Verdict: FAIL
Spec: docs/work/binary-test-verdict/spec.md
Range: origin/main...56a8695634cd7224206467bc3f6823a73f712661
Mode: full
Date: 2026-11-27

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 01add98 | yes | |
| US-1.AC2 | 58bafc0 | no | Mutation: mutations/US-1.AC2.diff; bash skills/build/scripts/test/binary-verdict-test.sh && bash skills/build/scripts/test/wf-test.sh python3 |
| US-1.AC3 | 2907c9d | yes | |
| US-1.AC4 | 0833d7f | no | Mutation: mutations/US-1.AC4.diff; bash skills/build/scripts/test/check-mutation-test.sh python3 |
| US-1.AC5 | 118d4ea | yes | |

Each row was judged by changing a copy of the branch in the scratchpad and running the AC's test scripts: 21 changes, 18 caught, 3 not.

- US-1.AC2: with the patch, a "no" row with an empty Note exits 0. A second change the tests also miss: dropping the `^` so "Mutation:" anywhere in the Note is accepted. The tests only use Notes "tests look thin" and "Waived ...".
- US-1.AC4: with the patch, a wording-only change that deletes the text between two f-string placeholders (`f"{GREETING} Welcome, {name}."` to `f"{GREETING}{name}"`) is taken as logic: unpatched check-mutation exits 1 "changes only wording", patched exits 0. The test's wording patch keeps the same number of text pieces.

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass

LANE full: PASS start=1795753951 end=1795754051
LANE clean: PASS start=1795753951 end=1795754053 unset=VENDOR_TOKEN,PUBLIC_BASE_URL
LANE wording: PASS start=1795753951 end=1795753952

The lanes printed no body lines.

## Out of Scope

none.

`wf scope` lists all 9 changed files outside docs/work because a direct build has no tickets: DECISIONS.md, install.sh, skills/build/references/decide.md, skills/build/scripts/check-mutation, skills/build/scripts/test/binary-verdict-test.sh, skills/build/scripts/test/check-mutation-test.sh, skills/build/scripts/test/wf-test.sh, skills/build/scripts/wf, skills/final-review/SKILL.md. Each diff was read; none builds anything the four Out of Scope lines exclude.

## Structure

`wf size`: none
none.

## Security

none.

Files covered: all 11 in `git diff --name-only origin/main...HEAD`. Caller spot-checked: skills/build/scripts/afk-loop:86 calls `"$wf" check-review "$dir/review.md"` and stops on a non-zero exit, as the report says.

Safe because: check-mutation refuses a patch that names a path outside the repo and leaves the working tree as it found it after a missed patch, a caught patch and a TERM sent mid-run. Proof: `<scratchpad>/sec/proof.sh "$PWD/skills/build/scripts/check-mutation"` ->

```
escape patch: exit 2, outside file exists: no, tree: []
missed patch: exit 0, tree: []
caught patch: exit 1, tree: []
mid-run: calc.py is LIMIT = 4
TERM mid-run: exit 143, tree: [], calc.py is LIMIT = 3
```

## Behaviour

none.

### Notes

- skills/build/scripts/check-mutation:54: a "no" row whose whole Note is in backticks is skipped with exit 0, and step 7 does not re-run check-mutation after check-review has the Note rewritten: neither
- skills/build/scripts/check-mutation:13: when the test command rewrites a patched file, or the run gets SIGKILL, the patch stays in the tree; the first case still exits 0, and the re-run says "commit or stash" the leftover: neither
- skills/build/scripts/check-mutation:33: a patch path in backticks is reported as a missing patch, and an empty patch file is reported as uncommitted changes in the review folder: neither
- skills/build/scripts/check-mutation:52: a test command containing `|` is cut at the first `|` because rows are split on it; `a || b` then exits 2 "the test command fails before the patch is applied": neither
- skills/build/scripts/wf:481: a grade cell written `partly.`, `**partly**` or `**no**` passes check-review: older

## Verify

not run: no verify skill

## Check warnings

none.

## Fix tickets

F01 guard an empty Note and a late "Mutation:": fixes US-1.AC2
F02 guard text deleted between f-string placeholders: fixes US-1.AC4

## OPEN

none.
