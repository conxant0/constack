---
name: build
description: Build every ticket in docs/work/<feature>/index.md with test-first Opus implementers in parallel worktrees, Opus review per ticket, and lead-only merges. Run in a fresh session after /slice.
disable-model-invocation: true
argument-hint: '<path to index.md> [AFK]'
hooks:
  PreToolUse:
    - matcher: "Agent"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/build/scripts/require-model.sh"
---

# /build

You are the lead. You hold only the index and the subagents' short reports. You never read ticket contents into your context beyond what a step names, and you never write product code.

## Hard rules

1. **Only you merge.** Implementers and reviewers never touch the integration branch.
2. **You never fix code.** Failures go back to the implementer or to rule 6.
3. **Pass `model` on every dispatch:** `opus`, except an implementer whose ticket has a `Model:` line (use that), and `fable` for rule 6. `scripts/require-model.sh` blocks a dispatch without one.
4. **At most 3 implementers at once.** Only tickets whose blockers are all `done`. A chain counts as one.
5. **Change `index.md` only through `${CLAUDE_SKILL_DIR}/scripts/wf`** (below: `wf`), except rows for tickets from an approved `split`. It is the ledger a fresh session resumes from. `wf set <index> <id> todo|doing|"blocked: <reason>"`, `wf done <index> <id> <merge sha>` and `wf ruling <index> "<ticket>: <ruling, why>"` each edit and commit it. Exit 2: fix what it printed and re-run.
6. **Decide, don't guess.** A question the spec does not answer, except what rule 8 lets you rule, goes to Fable: read `references/decide.md` at the first one and follow it. Only its Escalate list reaches the user. Log every ruling with `wf ruling`. A ruling the user made ends `pick: <your recommendation, copied from the question as you asked it>; chose: <their answer, or "pick">`.
7. **One implementer and one reviewer per chain** (`wf chains <index>` lists them). A chain runs in one worktree; resume the same implementer and the same reviewer with SendMessage for each next ticket. Every ticket still gets its own red-green check, review and merge.
8. **Rule on mechanical clarifies yourself.** Yours when the answer changes no product behaviour:
   - a test file, a registry or list a new name must join, a file the Approach implies
   - an existing test that pins a count, set, list or contract the ticket's ACs change (an expected tool list, a golden output, fixture setup the new behaviour needs), when no assertion is removed or loosened
   - an environment fix in Verify or the Test command (e.g. `python` to `python3`)

   Add the file to the ticket's Files; for an existing test, also add an Approach line `Ruling <date> (lead): <test> may change: <what changes>`, so review accepts it. Commit the ticket, log `wf ruling <index> "<id> (lead): <ruling, why>"` (`(afk)` in AFK mode), SendMessage the answer. Everything else goes to rule 6.
9. **Keep command output short: it stays in context and is re-read every turn.** Pipe test runs through `2>&1 | tail -40` (pytest with `-q`), read files by line range or grep, and never dump a full diff or log you can grep.

## Setup (stop if any fails)

1. The first word of `$ARGUMENTS` is the index. A second word `AFK` turns on AFK mode: read `references/afk.md` now. Run `wf gate <index> --build` (branch, clean tree, allow rules for git and both scripts, `.worktreeinclude` lists every ignored venv, node_modules and .env). Show the user every line it prints and stop. Ignore only missing allow rules, and only in auto or bypass mode.
2. **Permissions.** Unless in auto or bypass mode, the settings must also allow the test runner in the tickets' Verify lines (e.g. `Bash(pytest:*)`). If missing, print the exact JSON line and stop.
3. **Fresh worktrees can test.** If Verify needs another ignored file `wf gate` did not name, add it to `.worktreeinclude`.
4. **Resume.** Any ticket marked `doing` was interrupted: `wf set <index> <id> todo`, then `wf ruling`.
5. **Chains.** Run `wf chains <index>` and keep its lines. If one chain holds every ticket not yet `done`, serial mode is on: say so and read `references/serial.md`.

## Loop

1. **Frontier.** Run `wf frontier <index>`. Ticket ids: runnable. `all done`: go to Finish. Exit 1 (prints each unfinished ticket's status): if any is `doing`, wait for its report; otherwise report the `blocked` ones to the user and stop.
2. **Dispatch** up to 3. `wf set <index> <id> doing` for each, then, after the last one (each commits), `BASE=$(git rev-parse HEAD)`. For each, call Agent with `subagent_type: "general-purpose"`, `model` per rule 3, `isolation: "worktree"`, and the prompt from `references/implementer.md` (ticket path, BASE, index path).
3. **On each report** (they arrive separately):
   - `blocked`, by BLOCKER. `clarify`: answer from the spec, else rule it under rule 8, else rule 6. `split`: send the two proposed tickets to rule 6; on yes write them next to the original, add their rows to the index and commit. `ask-user`: rule 6. Log the ruling with `wf ruling`, then SendMessage the answer to the same implementer. If its WORKTREE path is gone (an agent with no commits loses it on stop), dispatch a fresh implementer from HEAD with the ruling in its prompt, correcting the ticket file first if the ruling changes it.
   - `done`: run `${CLAUDE_SKILL_DIR}/scripts/check-red-green.sh <WORKTREE> <BASE> "<ticket Verify>"`. Any `FAIL`, or a Delivers AC with no `OK red` or `OK guard` line (prefactors excepted): SendMessage the failing lines to the implementer and wait.
4. **Review.** Dispatch two Agents in one message, both `subagent_type: "general-purpose"`, `model: "opus"`, no isolation: the ticket reviewer with `references/reviewer.md` (ticket path, BASE, branch head, script output), and a fresh quality reviewer with `references/quality-reviewer.md` (ticket path, BASE, branch head). The ticket passes only when both say `pass`. Log any `LOG:` lines with `wf ruling <index> "<id> quality (logged): <findings>"`.
   - `VERDICT: fix` from either: SendMessage both reviewers' findings to the implementer in one message. On its report, re-run `check-red-green.sh` with BASE set to the reviewed head, then re-review with whichever reviewer said fix, passing its previous findings. After 2 fix rounds still failing: write the one sentence both fixes assumed, run one command that would come out differently if it were false, then `wf set <index> <id> "blocked: review"` and send rule 6 that sentence and the output. Its decision goes into the ticket as an Approach line `Ruling <date> (fable): <decision>`; set the ticket `todo` for a fresh implementer. A second `blocked: review` on the same ticket goes to the user. No third fix on an untested premise.
5. **Merge** (passed review):
   - `git merge --no-ff <BRANCH> -m "merge <ticket id>: <title>"`. Conflict: `git merge --abort`, `wf set <index> <id> "blocked: conflict"`.
   - Run the index's `Test command` (full suite) with `run_in_background`, plus its `Frontend test command` if `git diff --name-only HEAD^1 HEAD` lists a path under `packages/frontend/`. Keep dispatching or reviewing while it runs, but never start the next merge until it reports, so each run blames one merge. Fails: `git reset --hard <the merge's parent>`, `wf set <index> <id> "blocked: post-merge suite: <failing test names>"`, and stop any ticket dispatched from that merge.
   - Pass: `wf done <index> <id> <merge sha>` (only after the suite reports), then `git worktree remove <WORKTREE>` and `git branch -d <BRANCH>`.
   - **Chain with tickets left:** keep the worktree and branch. `wf set <index> <next id> doing`; its BASE is the branch head you just merged. SendMessage the same implementer the "Next ticket" section of `references/implementer.md`; on its report run `check-red-green.sh` with that BASE, then SendMessage the same reviewer the "Next ticket" section of `references/reviewer.md`. Remove the worktree after the chain's last ticket. A failed suite or a blocked ticket stops the chain there.
6. Back to 1.

## Finish

Tell the user: the tickets done, any blocked with reasons, the rulings made, with every `(fable)` ruling listed in one line each so they can reverse one before the PR. Then list every escalation waiting on the user, each with Fable's decision and its risk in one line, so they can decide from this message alone. Then: `/clear`, `/encode-comments <Base from the index>`, then `/clear`, `/final-review <Spec path from the index>`. (AFK: summary only.)
