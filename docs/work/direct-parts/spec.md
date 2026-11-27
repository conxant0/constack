# Build from the spec with parts in the index, no ticket files

Status: approved
Branch: feature/direct-parts
Base: origin/main
Date: 2026-11-27

## Problem

The ticket path writes far more planning text than code: three past features carried 1,913 lines of tickets and index against 56 lines when rebuilt straight from the spec, and the rebuilt code met every AC (measured 2026-11-27, four replays). The original ticketed build of the feature replayed twice ran its tickets one after another, so tickets bought no parallel speed there, and a lead with two helpers and no ticket files matched its time with no merge conflict. Of 6 bugs only the replays had, 5 trace to a spec point the original run stopped to settle and the replay decided alone. The owner wants one path that builds from the spec at any size, settles open spec points with the decision agent first, runs separate parts at the same time, and keeps the deterministic checks.

## User stories

### US-1 The no-ticket build takes a spec of any size

As the owner, I want the no-ticket build to accept a spec of any size, so that a medium or large feature does not need ticket files.

- US-1.AC1: Given an approved, well-formed spec with 7 ACs on its own clean branch, when the direct gate runs, then it exits 0 and prints nothing.
- US-1.AC2: Given an approved, well-formed spec with 4 ACs on its own clean branch, when the quick gate runs, then it exits 1 and its line still ends with a Fix that says to use the grilled path.

### US-2 Open spec points are settled before any code

As the owner, I want every choice the spec leaves open or contradicts written down and answered before building, so that no builder decides one alone.

- US-2.AC1: Given a build index with no "Open questions" section, when the questions check runs, then it exits 1 and its Fix line says to list every choice the spec leaves open or contradicts, send each to the decision agent, and write "none" when there are none.
- US-2.AC2: Given a build index whose "Open questions" section holds the question "Q1: which count does the summary show?" with no answer, when the questions check runs, then it exits 1, names Q1, and its Fix line says to send it to the decision agent and record the answer on that line.
- US-2.AC3: Given a build index whose "Open questions" section says "none", or holds only questions that each carry an answer, when the questions check runs, then it exits 0 and prints nothing.

### US-3 Parts live in the index and the checks read them there

As the owner, I want the split of a feature written as a few lines in the index, so that helpers can run at the same time, a restarted run knows what is done, and no ticket file is written.

- US-3.AC1: Given a build index whose parts cover every spec AC except US-1.AC2, when the parts check runs, then it exits 1, names US-1.AC2, and its Fix line says to add it to exactly one part.
- US-3.AC2: Given a build index where US-1.AC1 is listed under two parts, when the parts check runs, then it exits 1, names US-1.AC1 and both parts, and its Fix line says to leave it in one.
- US-3.AC3: Given a build index with a part that lists 14 ACs, when the parts check runs, then it exits 1, names the part and the count, and its Fix line says to split it so no part has more than 13.
- US-3.AC4: Given a build index where two parts with no blocked-by path between them both list the same file, when the parts check runs, then it exits 1, names the file and both parts, and its Fix line says to give the file to one part or order the two.
- US-3.AC5: Given a build index with parts P1 done and P2 todo blocked by P1, and no tickets folder, when the next-work command runs, then it prints P2 and exits 0.
- US-3.AC6: Given a helper branch for a part whose index line lists US-1.AC1 and US-1.AC2, holding a red commit for US-1.AC1 only, when the red-green check runs for that part with no ticket file, then it fails its delivers line and names US-1.AC2.

### US-4 The orchestrator writes no criterion code

As the owner, I want the orchestrating session held to merging and small glue, so that its memory stays small and every AC is built by a helper.

- US-4.AC1: Given a feature branch whose own commit, not reached through a merge commit, has the subject "feat(US-1.AC1): green", when the lead check runs, then it exits 1, names that commit, and its Fix line says to hand AC work to a helper and merge the helper's branch with a merge commit.
- US-4.AC2: Given a feature branch whose own commits change 41 lines outside the plan folder, when the lead check runs, then it exits 1, prints 41 and the limit 40, and its Fix line says to hand the work to a helper.
- US-4.AC3: Given a feature branch whose AC commits all arrive through merge commits and whose own commits change 10 lines outside the plan folder and any number inside it, when the lead check runs, then it exits 0 and prints nothing.

### US-5 The overnight loop runs the no-ticket build

As the owner, I want the overnight loop to drive an index that has parts and no ticket files, so that long runs do not need the ticket path.

- US-5.AC1: Given a build index with parts and no tickets folder, and the session command replaced by a recorder, when the overnight loop runs, then the first session it starts is the no-ticket build on the spec, and no ticket-build session is started.

## Decisions

- Testing seams: the exit codes and printed lines of the workflow script, the red-green check and the overnight loop, driven from the scripts' own test suite with index, spec and small repos written by the tests.
- Where it lives: the no-ticket build skill. The ticket skills and their scripts stay on disk unchanged as the fallback until two real features pass through the new path.
- Solo or orchestrated: a spec with at most 6 ACs is built in the one session as today, with one part, and the lead check does not run; the small-task lane keeps this behaviour. A spec with more is orchestrated: the session writes the parts, runs helpers, merges, and writes no AC code.
- Order of the build: gate, read the spec and code, write the index with "Open questions" and parts, questions check, decision agent answers recorded in the index, parts check, helpers per runnable part in their own worktrees and all of a wave in one message, red-green check and wording check per helper, merge with a merge commit, lead check, read the whole merged change once, one quality review, full suite.
- Parts: each part is an index row plus one line naming its ACs and the files it owns; a shared piece other parts need is its own earlier part. A feature that does not split is one helper part per 13 ACs in order.
- Helpers: follow-up work on a part goes back to the helper that built it, resumed, not to a fresh one. Each helper brief carries the part's line, the shared interfaces and the spec path.
- Quality review: the existing quality reviewer prompt, once, on the whole merged change, with at most 2 fix rounds. It also blocks an implicit state machine, the one rule only the dropped ticket reviewer held.
- Owner defaults chosen here, not asked: the lead's limit of 40 changed lines outside the plan folder, the part limit of 13 ACs (the largest part a helper built in the replays), and 6 ACs as the solo limit (today's value).
- The workflow guide, the readme and the decisions log are updated in the same change, with the replay numbers.

## Out of Scope

- Deleting or editing the ticket skills, the slicing skill or their checks.
- Running comment encoding during the build.
- A linter for the product repo, a failing test for small review fixes, and the inherited status-call bug (separate changes).
- Dropping the ticket reviewer from the ticket path.
- Counting helper token cost.

## Manual check

1. Run the scripts' test suite: every case passes, the new ones included.
2. Run the no-ticket build on the next real feature with more than 6 ACs: the index shows "Open questions" answered and parts, no tickets folder exists, and the feature branch's own commits hold no AC commit.
