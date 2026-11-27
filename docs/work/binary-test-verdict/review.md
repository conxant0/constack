# Final review grades each test yes or no, on proof: final review

Verdict: PASS
Spec: docs/work/binary-test-verdict/spec.md
Range: origin/main...2c9a8f762820fe22c41ccc841710287983d7095f
Mode: delta since 3573fded8dd949d451491b064ace8a538224ca82
Date: 2026-11-27

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 01add98 | yes | |
| US-1.AC2 | 58bafc0, guard 2945c68, guard 2f1e8bd | yes | |
| US-1.AC3 | 2907c9d | yes | |
| US-1.AC4 | 0833d7f, guard b611ad3 | yes | carried from 3573fde |
| US-1.AC5 | 118d4ea | yes | carried from 3573fde |

The fix work (F03) touched only binary-verdict-test.sh, which holds AC1 to AC3, so those three were re-judged. AC4 and AC5 live in check-mutation-test.sh, which `PREV..HEAD` does not touch, and no production file changed (`git diff --stat 3573fde HEAD -- skills/build/scripts/wf skills/build/scripts/check-mutation` is empty), so their rows are carried. Each re-judged AC was judged by changing `skills/build/scripts/wf` in a scratch worktree of HEAD and running `bash skills/build/scripts/test/binary-verdict-test.sh python3`: 8 changes, 8 caught, unmutated run exit 0.

- US-1.AC2: guard 2f1e8bd is judged by its Mutation patch (mutations/US-1.AC2-colon.diff, `/^ *Mutation:/` to `/^ *Mutation/`), a production change AC2 forbids; it now fails "AC2: Mutation without its colon". The earlier patches stay caught: the empty Note (mutations/US-1.AC2.diff), the dropped `^`, and the Note check turned off. AC2 was already true before F03, since F03 changes no production file.
- US-1.AC1: partly never flagged, and partly flagged only under FAIL: both caught.
- US-1.AC3: the PASS-plus-no check turned off, and a Fix line that says "or waive it": both caught.

Wording: `LANE wording: PASS`, no SURVIVED lines.

## Full suite

`f=0; for t in skills/build/scripts/test/*-test.sh test/install-test.sh; do bash "$t" python3 || f=1; done; [ $f = 0 ]`: pass

LANE full: PASS start=1795756223 end=1795756318
LANE clean: PASS start=1795756223 end=1795756321 unset=VENDOR_TOKEN,PUBLIC_BASE_URL
LANE wording: PASS start=1795756223 end=1795756223

The lanes printed no body lines.

## Out of Scope

none.

`wf scope` lists 8 changed files no ticket names: TODOS.md plus the 7 from the direct T01 build (DECISIONS.md, install.sh, skills/build/references/decide.md, skills/build/scripts/check-mutation, skills/build/scripts/test/wf-test.sh, skills/build/scripts/wf, skills/final-review/SKILL.md). Of these, only TODOS.md changed since 3573fde: one entry, the string-that-drives-behaviour item, which the spec's new Out of Scope line also states (the Fable ruling in the index). Nothing in `PREV..HEAD` builds what an Out of Scope line excludes.

## Structure

`wf size`: none
none.

## Security

none.

Files covered: all 7 in `git diff --name-only 3573fde...HEAD` (1 test script, 6 docs files). The finder reports no changed production function, so there is no caller to spot-check; I opened the one changed test line (binary-verdict-test.sh:32) and it is a hard-coded `review`/`expect` case, as the finder says.

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

- skills/build/scripts/wf:479: a grade cell written `no.`, `no (thin)`, `**no**`, `partially` or left blank passes check-review with exit 0, under PASS or FAIL (probe: `scratchpad/behaviour/probe2.sh`, all 6 cases rc=0): older
- carried from 3573fde: skills/build/scripts/check-mutation:32: a "no" row whose Note ends at the semicolon ("Mutation: mutations/x.diff;") runs an empty command, so check-mutation and check-review both exit 0 with no test run: neither
- carried from 3573fde: skills/build/scripts/check-mutation:20: a patch that changes an f-string format spec (`:.2f` to `:.0f`) or a compared literal is reported as "changes only wording": neither. Decided (fable): Out of Scope line plus a TODOS.md entry, no new AC in this branch
- carried from 56a8695: skills/build/scripts/check-mutation:54: a "no" row whose whole Note is in backticks is skipped with exit 0: neither
- carried from 56a8695: skills/build/scripts/check-mutation:13: when the test command rewrites a patched file, or the run gets SIGKILL, the patch stays in the tree: neither
- carried from 56a8695: skills/build/scripts/check-mutation:33: a patch path in backticks is reported as a missing patch, and an empty patch file as uncommitted changes: neither
- carried from 56a8695: skills/build/scripts/check-mutation:52: a test command containing `|` is cut at the first `|`: neither

## Verify

not run: no verify skill

## Check warnings

none.

## Fix tickets

none.

## OPEN

none.
