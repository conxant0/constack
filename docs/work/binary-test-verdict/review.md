# Final review grades each test yes or no, on proof: final review

Verdict: FAIL
Spec: docs/work/binary-test-verdict/spec.md
Range: origin/main...54bad9c6ad0d08c9639b7dd2104933d39d070761
Mode: delta since 56a8695634cd7224206467bc3f6823a73f712661
Date: 2026-11-27

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 01add98 | yes | |
| US-1.AC2 | 58bafc0, guard 6acbf94 | no | Mutation: mutations/US-1.AC2-colon.diff; bash skills/build/scripts/test/binary-verdict-test.sh && bash skills/build/scripts/test/wf-test.sh python3 |
| US-1.AC3 | 2907c9d | yes | |
| US-1.AC4 | 0833d7f, guard 83a5a4c | yes | |
| US-1.AC5 | 118d4ea | yes | |

No row is carried: the fix work touched both test files (binary-verdict-test.sh holds AC1 to AC3, check-mutation-test.sh holds AC4 and AC5), so all five were re-judged. Each was judged by changing a copy of HEAD in the scratchpad and running the AC's test scripts: 18 changes, 17 caught, 1 not. `PREV..HEAD` changes no production file, so each AC was already true before its guard.

- US-1.AC2: both earlier misses are now caught: the empty Note (mutations/US-1.AC2.diff) fails "AC2: no with an empty Note under FAIL", and dropping the `^` fails "AC2: Mutation: not at the start of the Note". One change still passes: `/^ *Mutation:/` to `/^ *Mutation/`, so a "no" row whose Note is "Mutation mutations/x.diff; cmd" (no colon) exits 0, and check-mutation then skips that row because it wants the colon. No test Note has "Mutation" without its colon.
- US-1.AC4: the earlier miss (mutations/US-1.AC4.diff) now fails "AC4: text between two f-string placeholders deleted". Three more changes (strings not blanked, the wording branch never taken, no exit 1) are caught.
- US-1.AC1, AC3, AC5: 3, 2 and 3 changes, all caught.

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass

LANE full: PASS start=1795755599 end=1795755692
LANE clean: PASS start=1795755599 end=1795755694 unset=VENDOR_TOKEN,PUBLIC_BASE_URL
LANE wording: PASS start=1795755599 end=1795755599

The lanes printed no body lines.

## Out of Scope

none.

`wf scope` lists 7 changed files no ticket names, because T01 was a direct build: DECISIONS.md, install.sh, skills/build/references/decide.md, skills/build/scripts/check-mutation, skills/build/scripts/test/wf-test.sh, skills/build/scripts/wf, skills/final-review/SKILL.md. None changed since 56a8695. Checked against each line: the only review file in the branch diff is this feature's; no build-stage skill, reviewer or per-ticket check is in the diff (decide.md loses its one waiver line); check-mutation:26 still counts a file that is not Python as logic; nothing handles an AC with no test.

## Structure

`wf size`: none
none.

## Security

none.

Files covered: all 8 in `git diff --name-only 56a8695...HEAD` (2 test scripts, 6 files under docs/work). The finder reports no changed production function, so there is no caller to spot-check; `git diff --stat 56a8695 HEAD -- skills/build/scripts/wf skills/build/scripts/check-mutation` is empty.

Safe because: check-mutation refuses a patch that names a path outside the repo and leaves the working tree as it found it after a missed patch, a caught patch and a TERM sent mid-run. Proof, the previous review's script re-run at HEAD: `<scratchpad>/sec/proof.sh "$PWD/skills/build/scripts/check-mutation"` ->

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

- skills/build/scripts/check-mutation:32: a "no" row whose Note ends at the semicolon ("Mutation: mutations/x.diff;") runs an empty command, so check-mutation and check-review both exit 0 with no test run: neither
- skills/build/scripts/check-mutation:20: a patch that changes an f-string format spec (`:.2f` to `:.0f`) is reported as "changes only wording"; the spec's Decisions blank every string, so a changed string that drives logic (`role == "admin"` to `"guest"`) is treated the same way: neither. Decided (fable): Out of Scope line plus a TODOS.md entry, no new AC in this branch
- carried from 56a8695: skills/build/scripts/check-mutation:54: a "no" row whose whole Note is in backticks is skipped with exit 0: neither
- carried from 56a8695: skills/build/scripts/check-mutation:13: when the test command rewrites a patched file, or the run gets SIGKILL, the patch stays in the tree: neither
- carried from 56a8695: skills/build/scripts/check-mutation:33: a patch path in backticks is reported as a missing patch, and an empty patch file as uncommitted changes: neither
- carried from 56a8695: skills/build/scripts/check-mutation:52: a test command containing `|` is cut at the first `|`: neither
- carried from 56a8695: skills/build/scripts/wf:481: a grade cell written `partly.`, `**partly**` or `**no**` passes check-review: older

## Verify

not run: no verify skill

## Check warnings

none.

## Fix tickets

F03 guard "Mutation" without its colon: fixes US-1.AC2

## OPEN

none.
