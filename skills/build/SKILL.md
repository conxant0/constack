---
name: build
description: Build every ticket in docs/work/<feature>/index.md with test-first Sonnet implementers in parallel worktrees, Sonnet review per ticket, and lead-only merges. Run in a fresh session after /slice.
disable-model-invocation: true
argument-hint: "<path to index.md> [AFK]"
---

# /build

You are the lead. You hold only the index and the subagents' short reports. You never read ticket contents into your context beyond what a step names, and you never write product code.

## Hard rules

1. **Only you merge.** Implementers and reviewers never touch the integration branch.
2. **You never fix code.** Failures go back to the implementer or to the user.
3. **Pass `model` on every dispatch:** implementers `sonnet` unless the ticket has a `Model:` line (then that model), reviewers `sonnet` (trial from 2026-10-27; /final-review stays on Opus).
4. **At most 3 implementers at once.** Only tickets whose blockers are all `done`. A chain (below) counts as one.
5. **Change `index.md` only through `${CLAUDE_SKILL_DIR}/scripts/wf`** (below: `wf`). The one exception: rows for tickets from an approved `split`. It is the ledger a fresh session resumes from. `wf set <index> <id> todo|doing|"blocked: <reason>"`, `wf done <index> <id> <merge sha>` and `wf ruling <index> "<ticket>: <ruling, why>"` each edit it and commit it. Exit 2: fix what it printed and re-run.
6. **Ask, don't guess.** A question the spec does not answer goes to the user. Log every ruling with `wf ruling`.
7. **One implementer and one reviewer per chain.** `wf chains <index>` lists the chains. A chain runs in one worktree. The same implementer is resumed with SendMessage for each next ticket, and the same reviewer is resumed for each next review. Every ticket still gets its own red-green check, review and merge.

## Setup (stop if any fails)

1. The first word of `$ARGUMENTS` is the index; a second word `AFK` turns on AFK mode (below). Run `wf gate <index> --build`: it checks the branch, a clean tree, the allow rules for git and both scripts, and that `.worktreeinclude` (copied into new worktrees) lists every ignored venv, node_modules and .env. Show the user every line it prints and stop. Ignore only missing allow rules, and only in auto or bypass mode.
2. **Permissions.** Unless the session is in auto or bypass mode, the settings must also allow the test runner in the tickets' Verify lines (e.g. `Bash(pytest:*)`). If missing, print the exact JSON line and stop.
3. **Fresh worktrees can test.** If the Verify commands need another ignored file that `wf gate` did not name, add it to `.worktreeinclude` the same way.
4. **Resume.** Any ticket marked `doing` was interrupted: `wf set <index> <id> todo`, then `wf ruling`.
5. **Chains.** Run `wf chains <index>` and keep its lines (rule 7).

## Loop

1. **Frontier.** Run `wf frontier <index>`. Ticket ids: those are runnable. `all done`: go to Finish. Exit 1 (it prints each unfinished ticket's status): if any is `doing`, wait for its report; otherwise report the `blocked` ones to the user and stop.
2. **Dispatch** up to 3. `wf set <index> <id> doing` for each, then, after the last `wf set` (each one commits), record `BASE=$(git rev-parse HEAD)`. For each, call Agent with `subagent_type: "general-purpose"`, `model:` the ticket's `Model:` line if it has one, else `"sonnet"`, `isolation: "worktree"`, and the prompt from `references/implementer.md` (ticket path, BASE, index path).
3. **On each report** (they arrive separately):
   - `blocked`: by BLOCKER. `clarify`: answer from the spec if it settles it, else ask the user. `split`: propose two tickets to the user; on approval write them next to the original, add their rows to the index table and commit it. `ask-user`: ask. Log the ruling with `wf ruling`, then SendMessage the answer to the same implementer. **If its worktree has no commits yet, it was removed when the agent stopped.** Check that the WORKTREE path still exists. If it does not, dispatch a fresh implementer from the current HEAD with the ruling in its prompt, and correct the ticket file first if the ruling changes it.
   - `done`: run `${CLAUDE_SKILL_DIR}/scripts/check-red-green.sh <WORKTREE> <BASE> "<ticket Verify>"`. Any `FAIL`, or a Delivers AC with no `OK red` or `OK guard` line (prefactors excepted): SendMessage the failing lines to the implementer and wait for its next report.
4. **Review.** Dispatch Agent `subagent_type: "general-purpose"`, `model: "sonnet"`, no isolation, with the prompt from `references/reviewer.md` (ticket path, BASE, the branch head, script output).
   - `VERDICT: fix`: SendMessage the findings to the implementer. On its report, re-run `check-red-green.sh` with BASE set to the reviewed head, then re-review with the previous findings. After 2 fix rounds still failing: write the one sentence both fixes assumed, run one command that would come out differently if it were false, then `wf set <index> <id> "blocked: review"` and ask the user with that sentence and the command's output. A third fix on an untested premise is not allowed.
5. **Merge** (passed review):
   - `git merge --no-ff <BRANCH> -m "merge <ticket id>: <title>"`. Conflict: `git merge --abort`, `wf set <index> <id> "blocked: conflict"`.
   - Run the index's `Test command` (full suite) here with `run_in_background`, so a ticket that breaks an earlier slice is caught now, and keep dispatching or reviewing while it runs. Never start the next merge until it reports, so each run blames one merge. Fails: `git reset --hard <the merge's parent>`, `wf set <index> <id> "blocked: post-merge suite: <failing test names>"`, and stop any ticket already dispatched from that merge.
   - Pass: `wf done <index> <id> <merge sha>` (only once the suite reports, never before), then `git worktree remove <WORKTREE>` and `git branch -d <BRANCH>`.
   - **Chain with tickets left:** keep the worktree and branch. `wf set <index> <next id> doing`. Its BASE is the head you just merged (the branch head, not the integration head). SendMessage the same implementer with the "Next ticket" section of `references/implementer.md`. When it reports, run `check-red-green.sh` with that BASE, then SendMessage the same reviewer with the "Next ticket" section of `references/reviewer.md`. The merge brings in only the new commits. Remove the worktree after the chain's last ticket. If the post-merge suite fails, or a ticket is blocked, the chain stops there, as any ticket would.
6. Back to 1.

## AFK mode

Run headless by `scripts/afk-loop`; no one is there to answer, and a fresh session resumes from the index.

- **Never call AskUserQuestion.** Wherever a step says ask the user, write your pick into `wf set <index> <id> "blocked: ask-user: <question>; pick: <yours>"` and `wf ruling <index> "<id> (afk): <question>"`, drop that ticket (and the rest of its chain), and keep going with the others.
- **`split`:** approve it yourself, write the tickets as usual, and log `wf ruling <index> "<id> (afk): split into <ids>, why"`.
- **Context budget.** After 3 merges this session, dispatch nothing new; finish and merge the tickets already in flight, then go to Finish. A chain gets 1 ticket per implementer: after its merge, remove its worktree and leave the next ticket `todo` for a fresh implementer. (Measured 2026-10-28: resumed implementers reached 123-125k after 2 tickets and 139-144k after 3; build leads stayed at 58-99k with 3 merges.)
- **Finish** prints the summary only, no `/clear` instructions.

## Finish

Tell the user: the tickets done, any blocked with reasons, the rulings made. Then list every decision waiting on the user, each with your pick and its risk in one line, so they can decide from this message alone. Then: `/clear`, `/final-review <Spec path from the index>`.
