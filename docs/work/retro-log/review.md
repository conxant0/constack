# Retro reads the logs first: final review

Verdict: PASS
Spec: docs/work/retro-log/spec.md
Range: 2dedb13...d31ec85390c5eabe45a9ebca96542ff3ecc85f2e
Mode: delta since 447262b
Date: 2026-11-28

`Base: origin/main` resolves to 2dedb13. The previous review (FAIL at 447262b) raised one behaviour finding, fixed by F08 (5ebd2aa). The fix diff `447262b..HEAD` touches skills/retro/scripts/retro-log (one condition in `typed()`), appends one block to its test, and adds US-1.AC8 to the spec. Every AC shares that test file and P1's files, so every row was re-judged. The F08 test block is appended and no earlier fixture sets `turnOrigin` to `scheduled` (only AC7's rows set it, to `sdk`, line 127), so the new condition cannot change AC1-AC7's results; those judgments stand. The branch also holds docs/work/helper-plain-git, a separate spec with its own review; its red commits reuse the ids US-1.AC1-AC3 and are not counted below.

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | b7e670e | yes | Re-judged: test unchanged by the delta. Main, helper and scratch errors give one `3x` line; the other feature's copy would make it 4; the single error must not print. Guards 569d7d7 and 3b9d5ee carry Mutation patches the AC forbids. |
| US-1.AC2 | d5058a7 | yes | Re-judged: test unchanged. Exact list `2x go`, `3x do the manual check via a subagent`, `ship it`. |
| US-1.AC3 | c292ee2 | yes | Re-judged: test and skills/retro/SKILL.md unchanged by the delta. |
| US-1.AC4 | 3b86047 | yes | Re-judged: test unchanged. Dropping the `isCompactSummary` skip fails the exact `go` check. |
| US-1.AC5 | 7169837 | yes | Re-judged: queued rows carry no `turnOrigin`, so the new check does not touch them. |
| US-1.AC6 | d399def | yes | Re-judged: test unchanged. |
| US-1.AC7 | 0b028dd | yes | Re-judged: the `sdk-cli` return is unchanged and its exact two-line check still covers it. |
| US-1.AC8 | 3463382 | yes | The fixture rows use `entrypoint: cli`, so the `sdk-cli` check cannot mask them. Three scheduled `/steward --tend 483` rows and one scheduled `check the deploy` row; the exact check `/steward 483` fails if any scheduled row is listed. |

Wording check:

LANE wording: PASS start=1795877440 end=1795877440

## Full suite

`test/run-all.sh ${PYTEST_PYTHON:-python3}` with `PYTEST_PYTHON=<python with pytest>` set on the command line:

LANE full: PASS start=1795877440 end=1795877520
LANE clean: PASS start=1795877440 end=1795877520 unset=<db token, redacted>,PUBLIC_BASE_URL
LANE wording: PASS start=1795877440 end=1795877440

(A first run without `PYTEST_PYTHON` failed both suite lanes with `python3 has no pytest`. That is the documented way to call the Test command, not a code failure.)

## Out of Scope

none. `wf scope` lists the same files as the previous review: skills/retro/SKILL.md (P1) and the helper-plain-git files (that spec's P1 files and docs folder). The delta adds only F08's files. Out of Scope line 1 now names helper-plain-git as built on this branch; the manual-check fix is not built.

## Structure

`wf size`: none
none

## Security

none. Finder coverage: all 6 files in `git diff --name-only 447262b...HEAD`; it found one caller of the changed `typed()`, the `messages` generator at skills/retro/scripts/retro-log:80-83 (opened). Spot-checked caller: skills/retro/scripts/retro-log:80-83 does call `typed(row)` and keeps only rows where it is truthy, as the report says. The report ended NO FINDINGS, so no filter ran.

Safe because: the worktree argument is mapped to `[A-Za-z0-9-]` before it is joined under `$CLAUDE_CONFIG_DIR/projects`, so the script opens logs only under that folder (the delta does not change this). Proof re-run at HEAD: `/usr/bin/python3 -I <scratchpad>/sec/proof.py` -> `opened 4 outside projects: []`, exit 0.

## Behaviour

none. Behaviour 1 from the previous review is fixed. Measured on copies of the two real project folders with scheduled rows, the 447262b -> HEAD output changes only by removing `7x /steward --tend 483` and `3x /steward --tend 485`. Measured on real logs: 0 owner-typed rows carry `turnOrigin: scheduled`, and queued attachments carry no `turnOrigin`. Probe: `bash <scratchpad>/behaviour2/beforeafter.sh` ->
```
### /home/lumbab/Developer/email-replaced
47d46
< 7x /steward --tend 483
### /home/lumbab/Developer/test-doc-cleanup
39d38
< 3x /steward --tend 485
```

### Notes

- skills/retro/scripts/retro-log:33,46,82-85: a row that parses as an object but has a string `message`, a numeric tool_result `content`, a `null` text block or a numeric `timestamp` crashes the script. Neither. Carried from 447262b.
- skills/retro/scripts/retro-log:71-76: a typed owner message that starts with `<` and is not a paste, command or shell input is left out. Neither. Carried from 1c855b2.
- skills/retro/scripts/retro-log:58: a queued attachment stamped `turnOrigin: scheduled` would be dropped before the human-origin check (0 such rows in 129 real queued attachments). Neither.

## Verify

not run: no verify skill
0 minutes.

## Check warnings

none

## Fix tickets

none

## OPEN

none
