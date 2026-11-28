# Retro reads the logs first: final review

Verdict: PASS
Spec: docs/work/retro-log/spec.md
Range: 2dedb13...044102657cd7f70de61e3b393cfad9dca66d1fb9
Mode: delta since 1c855b2
Date: 2026-11-28

`Base: origin/main` resolves to 2dedb13, which is also its merge-base with HEAD. The delta `1c855b2..HEAD` changes `typed()` in skills/retro/scripts/retro-log and adds three cases to its test file. That test file holds every AC's test, so every row below was re-judged.

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | b7e670e | yes | Re-judged. Guard 3b9d5ee: its Mutation patch (`errors.most_common()` -> `errors.items()`) is a change the AC forbids, the script already used `most_common()` before F05, and the new case (3x error logged last) fails on it. Guard 569d7d7 still covers the no-logs case. |
| US-1.AC2 | d5058a7 | yes | Re-judged: covers the repeat, the punctuation-only repeat, the task notification and the helper prompt, in order. |
| US-1.AC3 | c292ee2 | yes | Re-judged: step 1 under `## Steps` must name `${CLAUDE_SKILL_DIR}/scripts/retro-log`. |
| US-1.AC4 | 3b86047 | yes | Re-judged: the new sdk-cli early return does not touch the `isCompactSummary` skip, and dropping that skip fails the exact-list check. |
| US-1.AC5 | 7169837 | yes | Re-judged: queued rows in a cli session still reach the origin check, and dropping it fails the exact-list check. |
| US-1.AC6 | d399def | yes | Dropping the `<pasted_content` exception loses both paste messages, and stripping the paste block breaks the as-stored text. Both fail the exact four-line check. |
| US-1.AC7 | 0b028dd | yes | Dropping the `entrypoint == "sdk-cli"` check prints `/final-review ...` and `yes, approve as written`, and dropping `/clear` loses a line. Both fail the exact two-line check. |

## Full suite

LANE full: PASS start=1795863479 end=1795863565
LANE clean: PASS start=1795863479 end=1795863565 unset=<db token, redacted>,PUBLIC_BASE_URL
LANE wording: PASS start=1795863479 end=1795863479

## Out of Scope

none. `wf scope` listed skills/retro/SKILL.md as unplanned. It is in part P1's files in the index, and the delta does not touch it. No Out of Scope line is built.

## Structure

`wf size`: none
none

## Security

none. Finder coverage: docs/work/retro-log/{index.md,mutations/US-1.AC1.diff,review.md,spec.md,tickets/F05-F07}, skills/retro/scripts/retro-log (`typed()`), skills/retro/scripts/test/retro-log-test.sh. This matches `git diff --name-only 1c855b2...HEAD`. Spot-checked caller: skills/retro/scripts/retro-log:80-83, the `messages` generator, calls `typed(row)` for every main-session row, as the report says. The report ended NO FINDINGS, so no filter ran.

Safe because: the worktree argument is mapped to `[A-Za-z0-9-]` before it is joined under `$CLAUDE_CONFIG_DIR/projects`, so the script reads logs only under that folder. Proof: the previous proof was re-run at HEAD, since the fix diff does not touch the path mapping. `bash /tmp/tmp.AxRgQVDhTR/proof.sh /home/lumbab/Developer/self-improve` -> `ok ../../secret -> no logs on this machine`, `ok /tmp/tmp.dnBwbjHrc0/cfg/projects/../../secret -> no logs on this machine`, `ok ../secret -> no logs on this machine`, exit 0.

## Behaviour

none

### Notes

- skills/retro/scripts/retro-log:71-76: a typed owner message whose first character is `<` and that is not a paste, command or shell input (e.g. `<br> tags show in the email body, fix it`) is left out of typed messages (probe `bash /tmp/behaviour-probe2/probe-lt.sh` -> `start` / `ship it`). Common: no (0 of 202 real `<`-led cli user rows are plain owner text). Neither: Base has no script.
- skills/retro/scripts/retro-log:61,70-71: a scheduled `/loop` fire (`turnOrigin: "scheduled"`) prints as a typed slash command. Common: no. Neither. Carried from 1c855b2.

## Verify

not run: no verify skill
0 minutes.

## Check warnings

none

## Fix tickets

none

## OPEN

none
