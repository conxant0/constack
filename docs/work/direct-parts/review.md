# Build from the spec with parts in the index, no ticket files: final review

Verdict: FAIL
Spec: docs/work/direct-parts/spec.md
Range: origin/main...104a62d85d3504139f98056b291f81d603c6571c
Mode: full
Date: 2026-11-27

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | e98e652 | yes | wf-test "gate --direct 7 ACs": exact exit 0 and empty output |
| US-1.AC2 | 695b248 | yes | wf-test "gate --quick 4 ACs": exact exit 1 and the full line with the grilled-path Fix |
| US-2.AC1 | f9ddd9f | yes | questions-test "no section": exact exit 1 and full Fix line |
| US-2.AC2 | 727d806 | yes | questions-test "unanswered": exact line naming Q1 |
| US-2.AC3 | 4a3e63a | yes | guard; Mutation makes `questions` reject "none", a production change the AC forbids |
| US-3.AC1 | 67a1b31 | yes | parts-test "AC in no part": exact line naming US-1.AC2 |
| US-3.AC2 | 91b941e | yes | parts-test "AC under two parts": names US-1.AC1, P1 and P2 |
| US-3.AC3 | 6b52f39 | yes | parts-test "part with 14 ACs": names P1 and 14; 13 passes |
| US-3.AC4 | 98ffa41 | yes | parts-test "shared file, no path": names src/a.py, P1 and P2; a blocked-by chain passes |
| US-3.AC5 | 5037f46 | yes | guard; Mutation stops `frontier` reading "done <sha>" as done, so P2 is not printed |
| US-3.AC6 | ffb2857 | yes | delivers-part-test: exit 1 and the exact `FAIL delivers US-1.AC2` line, no tickets folder |
| US-4.AC1 | 6e60b76 | yes | lead-test: exact line naming the commit sha and subject |
| US-4.AC2 | ed61ce3 | yes | lead-test: 30 + 11 lines outside the plan folder, 50 inside; exact line with 41 and 40 |
| US-4.AC3 | 63b4c85 | yes | guard; Mutation drops `--first-parent`, so merged helper AC commits are flagged |
| US-5.AC1 | 6f5e5cd | yes | afk-loop-test: first recorded session is `/direct <spec> AFK`, no `/build` session |

## Full suite

`f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`: pass

LANE full: PASS start=1795781355 end=1795781580
LANE clean: PASS start=1795781355 end=1795781584 unset=<private env var>,PUBLIC_BASE_URL
LANE wording: PASS start=1795781355 end=1795781356

## Out of Scope

none

`wf scope` listed all 16 changed files outside the plan folder, because this index has no tickets and no Parts lines; each diff was read. Against the line "Deleting or editing the ticket skills, the slicing skill or their checks": no file under `skills/slice` and no `skills/build` prompt changed. The branch does edit three shared scripts under `skills/build/scripts` (`wf`, `check-red-green.sh`, `afk-loop`), which the ACs require (the spec's testing seams name them). Their ticket paths behave as before: `check-red-green.sh <ticket.md>` reads the same `## Delivers` block, `afk-loop` still starts `/build` when a `tickets/` folder exists or the index has no `## Parts`, and the only changed existing reply is the `gate --quick` Fix text that US-1.AC2 asks for. Comment encoding, a product linter, the ticket reviewer and token counting are untouched.

## Structure

`wf size`: none

- skills/build/scripts/check-red-green.sh:26: `delivers()` parses a `## Parts` line with its own awk, a near-duplicate of the reader in `parts()` at skills/build/scripts/wf:548. The two already disagree: on a heading written `## Parts ` (trailing space) `wf parts` exits 0 and `check-red-green.sh <index>:P1` exits 2 with "no line for P1" (probe p3-crg.sh case b), and a part naming an AC the spec lacks passes `wf parts` then fails delivers (probe p6-unknown-ac.sh). Smaller structure: one reader in `wf` (a `part-acs <index> <part>` subcommand) that `check-red-green.sh` calls, so both checks read the same lines. declined. Decided (fable): decline; no AC needs one reader, both disagreements need a malformed index and fail loudly with a Fix line, and the unknown-AC case does not come from the duplicate reader.

## Security

none

Finder coverage: 18 of 18 files in `git diff --name-only origin/main...HEAD` covered (3 scripts, 4 skill and prompt files, 6 test files, 5 docs). Spot-checked caller: `WF lead <index>` at skills/direct/SKILL.md:35 and :41, both present and used as the report says. The finder ended with NO FINDINGS.

Safe because: the new checks treat index body text, a part id and commit subjects as data and never run them as shell. Proof: `bash /private/tmp/claude-501/-<home>-Developer-direct-parts/043f794b-90c6-4938-b583-1eb61950e06c/scratchpad/proof.sh` (an index whose table title, question, answer, Parts ACs and files, a commit subject, and the `<index>:<part>` argument all carry `$(touch PWNED)`, backticks and `; touch PWNED`) ->
```
questions exit=1
parts exit=0
lead exit=1
red-green P1 exit=1
red-green injected part id exit=2
PROOF OK: no index text, part id or commit subject was executed
```

## Behaviour

- skills/direct/SKILL.md:40 and :44: the orchestrated flow never marks its last part done. Step 4 says "The last part's `WF done` waits for step 8"; step 8 runs the suite, removes the helpers' worktrees and hands off, with no `WF done` (`grep -n 'WF done' skills/direct/SKILL.md` hits only line 30, the solo step 6, and line 40). A lead that follows the text leaves the last row `doing`, and the next step, `/final-review`, stops at its gate. Probe: `bash /private/tmp/claude-501/-<home>-Developer-direct-parts/043f794b-90c6-4938-b583-1eb61950e06c/scratchpad/behaviour/p2-final.sh` section (b) -> `wf frontier`: `P2 doing`, exit 1; `wf gate spec --final`: `docs/work/x/index.md:1: not every ticket is done (run /build)`, exit 1. `p5-afk.sh` case (a): the loop restarts `/direct <spec> AFK` and stops with "build made no progress" when that session makes no commit. No AC covers it; the spec's Manual check 2 would meet it. Common: yes on the orchestrated path (every run that follows the text). Money: no. Decided (fable): new AC US-3.AC7 and fix ticket F01: the final gate names a merged part still `doing` with a Fix for the no-ticket build, and Orchestrated step 8 marks the last part done.

### Notes

- skills/build/scripts/wf:543: "## Open questions" holding "None", "None.", nothing, or an answered question without the leading "- " prints "no \"## Open questions\" section" at the heading's own line; money no, common no; neither
- skills/build/scripts/check-red-green.sh:26: a "## Parts " heading with a trailing space passes `wf parts` and then fails check-red-green with "no line for P1"; money no, common no; neither
- skills/build/scripts/wf:562: a part naming an AC the spec does not have passes `wf parts`, then delivers demands its red commit; money no, common no; neither
- skills/build/scripts/wf:364: a parts index whose last part is merged but still `doing` gets "not every ticket is done (run /build)" from `gate --final`; money no; same reply at Base; older (the skill text that makes this state the normal one is under OPEN)
- skills/build/scripts/wf:407: `wf scope` prints every file a part owns as "changed, but no ticket lists it under Files"; money no, common yes; same reply at Base; older

## Verify

not run: no verify skill

## Check warnings

none

## Fix tickets

F01 The final gate names a merged part still doing: fixes Behaviour, skills/direct/SKILL.md:40 (new AC US-3.AC7).

## OPEN

none
