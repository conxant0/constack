---
name: unblock
description: Resolve the blocked tickets an AFK /build left in index.md, one at a time with the user, then print the command that restarts afk-loop. Pasted from afk-loop's blocked alert.
disable-model-invocation: true
argument-hint: "<path to index.md>"
---

# /unblock

An AFK `/build` stopped on `blocked:` rows in `$ARGUMENTS`. You turn each one into a ruling the next build can act on. You never write product code; the next `/build` does.

`wf` is `~/.claude/skills/build/scripts/wf`.

## Steps

1. **Read the blockers.** One Bash call: `git branch --show-current; git status --short; wf frontier <index>; grep -n '(afk)' <index> | tail -20`. Not on the index's `Branch:` or tree dirty: say so and stop. No `blocked` row: say so, print the restart command (step 6) and stop.
2. **One ticket at a time**, in table order. For each, find its `(afk)` ruling lines (they name the evidence, the worktree and any commits already made).
3. **Check the facts before asking.** The AFK lead's question and pick are a draft, not a finding. Open every file:line it cites and the code on both sides, and run the cheap check that would prove it wrong. Label each claim measured or inferred. If the facts contradict the blocker, say so: the question may change.
4. **Ask.** AskUserQuestion, standalone (the user may see only the dialog): what is blocked, what each side does today (measured), and 2-3 options, your recommendation first with "(Recommended)". The AFK pick is one option, not the default. Prefer the option that changes no existing product behaviour and no existing test written on purpose, unless the spec says otherwise.
5. **Apply the answer**, then commit it all as one commit:
   - The spec, if the answer changes an AC or Out of Scope (a scope change updates the spec in the same commit).
   - **The ticket file.** Implementers never read the index, so a ruling only in `## Rulings` does not reach them. Add the files the answer touches to `## Files`, fix `## Tests`/`## Approach`, and add an Approach line `Ruling <date> (<user>): <ruling>`. Name any earlier ticket's test it now legitimately changes, so review does not read it as a weakened test.
   - Partial work: if the `(afk)` line names a worktree with commits, check it still exists (`git worktree list`) and add `Earlier commits for AC<x>: <worktree> <range>; cherry-pick or redo` to the Approach line.
   - `wf set <index> <id> todo`, then `wf ruling <index> "<id> (<user>): <ruling, why, what the ticket now does>"`, then `git commit -q --amend --no-edit -- <spec> <ticket files>` to fold the doc edits into that ruling commit.
   - `blocked: review`, `blocked: conflict` and `blocked: post-merge suite` get the same treatment: the ruling says what the next implementer must do differently, written into the ticket.
6. **Finish.** List each ticket: ruling, commit sha. Then print the restart command for the user to run in a plain terminal (not in this session), with absolute paths and a trailing space after each path:
   `cd <repo root> && ~/.claude/skills/build/scripts/afk-loop <abs index path> `
   For a single ticket the user wants to watch instead: `/clear`, then `/build <abs index path> `.
