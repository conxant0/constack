# Faster /build and /final-review, weak tests caught during /build

Status: approved
Branch: feature/workflow-speed
Base: origin/main
Date: 2026-11-24

## Problem

Across 7 features since 2026-11-18, /final-review used as many tokens as all of /build (262M vs 261M), and its sessions average 31 minutes (sessions of 5+ minutes) because every step runs one after another. 21 of 32 fix tickets were weak tests against an AC, found only at final review, and each one costs another review round. The owner wants the review to run independent work at the same time, and weak tests caught by scripts while each ticket is built, without giving up red-first tests, frozen tests, one test per AC, two reviewers, the behaviour pass or the security pass.

## User stories

### US-1 Final review runs its script work at the same time, safely

As the owner running /final-review, I want one command that runs the full suite, the clean-checkout suite and the wording check together, each where it cannot disturb the others, so that a review session takes as long as its longest part and no step fails because another step was editing files.

- US-1.AC1: Given a branch whose final-review gate passed, when the review's script lanes run, then the full suite and the clean-checkout suite run at the same time (their run windows overlap) and each records pass or its failing test names.
- US-1.AC2: Given a branch that changes a sentence in a string constant, when the script lanes run, then the wording check runs in its own copy of the branch at HEAD: the review's working tree shows no changed tracked file at any moment of the full suite's run, and the full suite's result matches a run with no wording check beside it.
- US-1.AC3: Given a worktree whose env file sets a variable one test needs, when the script lanes run the clean-checkout suite, then that test fails there and the lanes' output names the test and the variable.
- US-1.AC4: Given the script lanes have finished, pass or fail, when the review lists its worktrees, then no copy the lanes made is left.
- US-1.AC5: Given a branch whose tests need an ignored path the worktree include file lists (a virtual environment or an env file), when the script lanes run the wording check in its own copy, then the copy has that path and the wording check reports sentences instead of stopping with exit 2.

### US-2 Every AC a ticket promises has a red or guard commit

As the lead, I want the red-green check to fail a ticket that promises an AC with no red or guard commit, so that I no longer check it by eye.

- US-2.AC1: Given a ticket whose Delivers line lists US-1.AC2 and a range with no `test(US-1.AC2): red` or `guard` commit, when the red-green check runs with that ticket, then it prints a FAIL line naming US-1.AC2 with a `Fix:` line and exits 1.
- US-2.AC2: Given a ticket whose Delivers line is `none` or `none (<reason>)` (a prefactor, refactor or test-isolation fix), when the red-green check runs with it, then it prints no delivers FAIL line.
- US-2.AC3: Given a ticket that delivers a lettered AC such as US-2.AC7b and a range with its red commit, when the red-green check runs, then it prints no delivers FAIL line for US-2.AC7b.
- US-2.AC4: Given a fix-round run whose range starts at the reviewed head and holds no red or guard commit, and the ticket's `test(US-1.AC2): red` commit sits between the ticket's start and that reviewed head, when the red-green check runs with that ticket and the ticket's start, then it prints no delivers FAIL line for US-1.AC2.
- US-2.AC5: Given no ticket argument (the test-only fix prompt's run), when the red-green check runs, then it prints no delivers line and no wording line, writes no warning log, and its other lines and exit status are as they are today.

### US-3 Wording a ticket adds is checked against its own tests

As the lead, I want each ticket's new or changed sentences in string constants checked against that ticket's own tests, so that untested copy shows up during /build instead of at final review.

- US-3.AC1: Given a ticket that adds a sentence to a module-level string constant in a Python source file, and its red and guard tests still pass with that sentence deleted, when the red-green check runs with that ticket, then it prints on standard output, with its other lines, a warning line naming the sentence as SURVIVED, with a `Fix:` line, and the warning alone does not change the exit status.
- US-3.AC2: Given a ticket whose red and guard tests make the wording check stop with no result (exit 2: a snapshot test fails its one-space probe, or the tests fail before any edit), when the red-green check runs, then it prints a warning saying the wording check could not run, with a `Fix:` line, not a FAIL.
- US-3.AC3: Given a ticket that changes only a comment and a docstring, when the red-green check runs, then it prints no wording line.

### US-4 A guard's mutation is a patch the check runs

As the lead, I want each guard commit to carry its mutation as a patch the red-green check applies, so that a guard that cannot catch its break is found by the script, not by a reviewer reading prose.

- US-4.AC1: Given a guard commit whose body holds a fenced unified diff under `Mutation:` that makes its tests fail, when the red-green check runs, then it prints an OK guard line.
- US-4.AC2: Given a guard commit whose patch applies but its tests still pass with it applied, when the red-green check runs, then it prints a warning naming the guard and AC, with a `Fix:` line.
- US-4.AC3: Given a guard commit whose patch does not apply, when the red-green check runs, then it prints a warning saying the patch does not apply, with a `Fix:` line.
- US-4.AC4: Given a guard commit with a prose `Mutation:` line and no patch, when the red-green check runs, then it prints a guard-patch warning saying the patch is missing, with a `Fix:` line.
- US-4.AC5: Given a guard commit with no `Mutation:` line at all, when the red-green check runs, then it prints a FAIL line and exits 1, as it does today.
- US-4.AC6: Given any guard patch check, when the red-green check finishes, then the worktree has no changed file and is back on the branch it started on.
- US-4.AC7: Given a guard commit whose patch changes a test file, when the red-green check runs, then it prints a guard-patch warning saying the patch must change production code only, with a `Fix:` line.

### US-5 Later tickets do not edit earlier or pre-existing tests

As the lead, I want `wf done` to check the whole branch for edits to tests that earlier tickets froze or that existed at Base, so that a test weakened by a later ticket is caught at merge.

- US-5.AC1: Given ticket T1's red commit touched a test file and a later ticket T2 changes that file outside a red or guard commit, with no ruling line in T2 naming that file before `may change:`, when `wf done` runs for T2, then it prints a warning naming the file and T2, with a `Fix:` line.
- US-5.AC2: Given the same change, and T2 has a ruling line naming that file before `may change:`, when `wf done` runs for T2, then it prints no warning for that file.
- US-5.AC3: Given a test file that existed at Base and a ticket changes it outside a red or guard commit with no matching `may change:` line, when `wf done` runs for that ticket, then it prints a warning naming the file.
- US-5.AC4: Given a ticket that adds a brand-new test file in an ordinary commit, when `wf done` runs for it, then it prints no warning for that file.
- US-5.AC5: Given the check is in warning mode and prints a warning, when `wf done` runs, then the ticket is still recorded done.
- US-5.AC6: Given T2's red commit removes or rewrites a line in a test file T1's red commit touched, with no matching `may change:` line, when `wf done` runs for T2, then it prints a warning naming the file and T2, with a `Fix:` line.
- US-5.AC7: Given T2's red commit only adds lines to that file, when `wf done` runs for T2, then it prints no warning for that file.
- US-5.AC8: Given the check is set to `block` and has a finding, when `wf done` runs, then it prints FAIL, exits 1 and does not record the ticket done, and its `Fix:` line says to undo the merge and send the finding to the implementer.

### US-6 Warnings are logged, graded, and switched to blocking

As the owner, I want new checks to warn first, with every warning logged and graded, so that I switch a check to blocking on evidence of few false alarms.

- US-6.AC1: Given the shipped settings, when a check runs, then the delivers check (US-2) blocks, and the wording (US-3), guard patch (US-4) and earlier-tests (US-5) checks warn.
- US-6.AC2: Given a check set to `block` in the settings and a finding, when that check runs, then it prints FAIL and exits non-zero; set to `warn`, it prints a warning and the finding alone does not change the exit status.
- US-6.AC3: Given a check run for a ticket, in warning mode, prints a warning, when it runs, then one line with the check name, the ticket id and the warning text is appended to the feature folder's warning log.
- US-6.AC4: Given the same warning line is already in the log, when the check prints it again on a re-run, then the log does not get a second copy.
- US-6.AC5: Given a check set to `block` prints a FAIL, when it runs, then nothing is written to the warning log.
- US-6.AC6: Given a warning log line that review.md's `Check warnings` section does not repeat with `real: <reason>` or `false alarm: <reason>` after it, when `wf check-review` runs, then it prints a line naming that log line, with a `Fix:` line.
- US-6.AC7: Given a feature folder with no warning log, or an empty one, when `wf check-review` runs, then it prints nothing about check warnings.
- US-6.AC8: Given a warning log with lines and a merge that is then undone with a hard reset, when the reset has finished, then the warning log still holds every line.
- US-6.AC9: Given the warning log is the only uncommitted change in the tree, when the gate runs, then it prints nothing about uncommitted changes.
- US-6.AC10: Given two checks that each print a different warning at the same time, when both have finished, then the warning log holds both lines.
- US-6.AC11: Given a `Check warnings` line marked `real` that names no fix ticket id after its reason, when `wf check-review` runs, then it prints a line naming it, with a `Fix:` line.
- US-6.AC12: Given no settings file, or one that does not list a check, when that check runs, then it uses its shipped mode (delivers blocks, the others warn).
- US-6.AC13: Given a settings value other than `warn` or `block`, when that check runs, then it prints an ERROR line naming the value, with a `Fix:` line, and exits 2.

## Decisions

- Data: one settings file lists each check (delivers, wording, guard patch, earlier tests) as `warn` or `block`. One warning log per feature, in the feature folder, one line per warning: check name, ticket id, warning text. review.md has a `Check warnings` section that repeats each log line followed by `real: <reason> (F<nn>)`, naming the fix ticket, or `false alarm: <reason>`. A guard's mutation is a fenced unified diff under `Mutation:` in the guard commit body.
- Boundaries: a check in `warn` mode never stops an AFK run and never blocks a merge. The wording check covers what mutate-copy covers with `--base`: sentences in module-level string constants in Python source files that are new or changed against the base; comments, docstrings and deleted constants are not checked. A test file is whatever the red-green check already treats as one. The red-green check gets the ticket path and finds the feature folder from it. The wording check's copy gets every path the worktree include file lists, env files included; the clean-checkout copy gets none of the env files.
- Testing seams: the red-green check's printed lines and exit status on fixture repos; `wf done` and `wf check-review` output and exit status; the final-review script lanes' output, run windows, the review tree's status and the worktree list.
- No cap on final-review rounds: PASS still needs every AC proven, and only the user waives a weak test (because rounds 3+ wrote 5 fix tickets, only 1 test-only, and 2 were money bugs; measured).
- Final-review order (plain rule in the skill, checked by hand): right after the gate the lead dispatches the security finder and the behaviour finder, starts the script lanes, then does its own steps (`wf red`, test judging, `wf scope` and Out of Scope, `wf size` and structure). The live check (verify) runs in the review's own tree once the script lanes have finished and removed their copies (because US-1.AC4 removes the copies, and verify writes nothing the tree tracks). Everything joins before the security coverage check, filters and proof, then the behaviour sort, then the write-up and step 8. Same for delta runs, with the previous reviewed head as the base.
- /build order on an implementer's `done` (plain rule in the skill, checked by hand): quality reviewer dispatched at once; red-green check run in the background; ticket reviewer dispatched when the check reports, with its output. A check FAIL while the quality review runs: wait for both, send the FAIL lines and the quality findings in one message; after that fix the quality reviewer re-reviews the fix diff even if it said pass. A quality `fix` that arrives before the check finishes waits for the check before any message to the implementer (the check checks out commits in that worktree). Same order for a chain's next ticket.
- The ticket reviewer does not re-check fix diffs only the quality reviewer asked for (because 27 build fix rounds were all quality-initiated and no final-review finding traced to an unseen fix diff; measured).
- The wording check per ticket uses the ticket's own red and guard test files as its test command (because the full Verify often includes snapshot tests, which stop it). Final review's own wording check stays until the per-ticket one proves out.
- Guard patch writers: the implementer prompt, the test-only fix prompt and /direct. Final review's test judging reads the patch.
- The delivers check reads commit subjects from the ticket's start to HEAD and re-runs nothing outside the range it was given. The lead passes the ticket's start on every run, first or fix round (because a fix round's range starts at the reviewed head and holds no red commit).
- The warning log is written in the lead's feature folder, the one holding the ticket, never in an implementer's worktree. It is never committed (because a merge undo would wipe uncommitted lines from a tracked file, and a changed tracked file stops the red-green check); the gate does not count it as an uncommitted change, and review.md's `Check warnings` section is the committed record.
- The earlier-tests check stays in `wf done`, after the merge. In `block` mode a finding is handled like a failed post-merge suite: the merge is undone and the finding goes to the implementer.
- A ruling line that allows a test change keeps today's shape, the test file's path before `may change:`. A fix ticket that changes an existing test gets that line from final review when the ticket is written.
- The ticket reviewer treats a SURVIVED sentence the way final review does: one that states a rule a delivered AC carries is a finding, any other is ignored.
- A warning graded `real` fails the verdict and gets a fix ticket in that review round; `false alarm` changes nothing.
- A warning check becomes blocking after 3 features with at most 1 false alarm; the owner flips it in the settings file, and removes the matching prompt text in that same change.
- Each check's own test asserts its `Fix:` text.
- Settings: one in-repo settings file beside the build scripts, lines `<check>=<warn|block>`; the four shipped modes are also built in, so a missing file or name falls back to them. One helper prints a check's mode and one helper writes the log (fable, 2026-11-24).
- A finding prints as one line starting WARN (warn mode) or FAIL (block mode), then the check name. The log line is the check name, ticket id and that line's text without its Fix. A `Check warnings` row is the log line followed by `real: <reason> (F<nn>)` or `false alarm: <reason>` (fable, 2026-11-24).
- The red-green check takes the ticket and the ticket's start as optional arguments after today's three; the start defaults to the base. Without a ticket it prints no delivers or wording line and logs nothing (fable, 2026-11-24).
- A guard's mutation is a fenced unified diff directly under the prose `Mutation:` line, committed with the message kept verbatim (because git's default message cleanup corrupts a patch; measured). The OK guard line prints as today; a guard-patch finding is one extra line after it (fable, 2026-11-24).
- A ticket's commits are the merged side of its merge, or, when it was built without a merge, the commits since its `doing` commit. The test-file definition lives in one shared place that the red-green check and `wf` both read (fable, 2026-11-24).
- `wf done` reads `may change:` lines from the ticket file and from index Rulings lines that start with the ticket id; a line allows a file when a token before `may change:` equals its repo-relative path exactly (fable, 2026-11-24).
- The log is kept out of git's view by a local ignore entry the writer adds, so no clean-tree check anywhere counts it; the gate also skips it. Writers append without a lock, one line per write, after checking the line is not already there (measured: 40 concurrent writers, no duplicates or broken lines) (fable, 2026-11-24).
- The per-ticket wording check covers non-test Python files the ticket added or changed since its start, with the ticket's start as base, and runs only the ticket's red and guard Python test files under one package root. When it cannot build that command it never falls back to the full suite: any new sentence then lands in a could-not-run warning (fable, 2026-11-24).
- The script lanes are one new script taking the index and the base. Each lane prints a header with its status and start and end times; the clean lane's header names the variables it unset (names only). Copies get the include paths as symlinks. A wording-only re-run with a narrower test command is available for a wording lane that could not run (fable, 2026-11-24).
- Success measure: after 2 features built with this change, re-running the session measurement gives a final-review session average of at most 20 minutes (was 31). Model estimate: 5 to 13 minutes saved per session (inferred).

## Out of Scope

- A cap on final-review rounds with test-only findings becoming follow-up tickets (rejected: it would let an AC ship with a test that does not prove it).
- A money-words check that refuses a "quality (logged)" ruling mentioning charge, credit or paid (skipped: 1 case in 32 fix tickets, and the behaviour pass caught it).
- A check that the lead dispatched agents in the planned order, in final review or in /build (it would need session-log parsing; the session measurement re-run and the Manual check cover it).
- The ticket reviewer re-checking fix diffs only the quality reviewer asked for.
- Patch mutations for the tests /encode-comments writes (the red-green check does not read its `test(comment)` commits; later).
- Removing prompt text a check replaces (done in the change that flips that check to blocking).
- Product-repo checks: the paid-tool money invariant test and the zero-assertion pytest/vitest check (separate spec in the product repo).
- Whether the ticket reviewer earns its place (0 fix verdicts in 27 rounds, 76 agent-minutes; later question).

## Manual check

1. Run /build on the next feature. Expected: on each implementer `done`, the quality reviewer starts before the red-green check reports, and the ticket reviewer starts after it.
2. In that build, look at the feature folder's warning log. Expected: each line has the check name, ticket id and warning text, and no AFK run stopped on a warning.
3. Run /final-review on it. Expected: the two finders are dispatched and the script lanes start right after the gate, the review's working tree stays clean while the wording check runs, and review.md's `Check warnings` section marks every log line `real` or `false alarm`.
4. After 2 features, re-run the session measurement. Expected: final-review sessions average 20 minutes or less.
