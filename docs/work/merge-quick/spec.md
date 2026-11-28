# One build command: /direct takes a spec or a one-line task

Status: approved
Branch: feature/merge-quick
Base: origin/main
Date: 2026-11-28

## Problem

The owner has two commands for one job. `/quick` writes a small spec from a one-line task, asks once, then follows `/direct` step by step; it is 25 lines of its own plus a script whose only purpose is to catch `/direct` being renumbered under it. That is a second name to remember and plumbing that exists only because the two are separate. The installer also never removes the link of a skill that was deleted, so deleting `/quick` would leave a dead command behind.

## User stories

### US-1 The build command takes a spec or a one-line task

As the owner, I want `/direct` to accept either an approved spec or a one-line task, so that I remember one command.

- US-1.AC1: Given an argument whose first word names an existing spec file, when the entry check runs, then it exits 0 and prints exactly `spec`.
- US-1.AC2: Given the argument `"fix notes.md typo"` and no file named fix, when the entry check runs, then it exits 0 and prints exactly `task`.
- US-1.AC3: Given an argument whose first word ends in `.md` and names no existing file, when the entry check runs, then it exits 1, names that word, and its Fix line says to correct the path or to quote a one-line task.
- US-1.AC4: Given a quoted one-line task followed by the word `AFK`, when the entry check runs, then it exits 1 and its Fix line says a one-line task needs the owner's approval, so run it attended or pass an approved spec.
- US-1.AC5: Given no argument at all, when the entry check runs, then it exits 1 and its Fix line says to give the path of an approved spec or a quoted one-line task.
- US-1.AC6: Given an argument whose first word names an existing spec file and whose second word is `AFK`, when the entry check runs, then it exits 0 and prints exactly `spec`.

### US-2 A spec written from a one-line task stays small

As the owner, I want a spec nobody grilled held to 3 ACs, so that the unreviewed lane cannot grow into a feature.

- US-2.AC1: Given an approved, well-formed spec with 4 ACs on its own clean branch, when the task gate runs, then it exits 1, its line says a one-line task takes at most 3 ACs, names `/direct` and not `/quick`, and its Fix line says to use the grilled path.
- US-2.AC2: Given an approved, well-formed spec with 3 ACs on its own clean branch, when the task gate runs, then it exits 0 and prints nothing.
- US-2.AC3: Given a well-formed spec with 3 ACs whose status is draft, on its own clean branch, when the task gate runs, then it exits 1, its line says the status is draft and that `/direct` needs approved, and its Fix line says to set the status to approved, commit and re-run.
- US-2.AC4: Given any spec, when the gate is called with the old mode name `--quick`, then it exits 2 and prints a usage line that lists `--task` and does not list `--quick`.

### US-3 The second command is gone

As the owner, I want `/quick` removed everywhere it ships, so that nothing points at a command that does not exist.

- US-3.AC1: Given this repo's skills folder, README, workflow rules and installer, when they are searched for `/quick`, and the skills folder for a skill named quick, then there is no match.
- US-3.AC2: Given the shipped skills, when the citation check runs, then it exits 0 and prints nothing.
- US-3.AC3: Given a copy of the shipped skills in which the spec skill's hard rule 3 has a different bold lead, when the citation check runs, then it exits 1, names that item and the build skill that cites it, and its Fix line says to point the build skill at the item's new number or restore it.

### US-4 The installer removes links to deleted skills

As a user who installed with the installer, I want links to skills and hooks that no longer exist removed on the next run, so that a deleted command stops showing up.

- US-4.AC1: Given a home whose skills folder and hooks folder each hold, directly inside, a link whose stored target is an absolute path inside this checkout that no longer exists, when the installer runs, then both links are gone, it prints one `pruned <path>` line for each, where the path is the link's own, and it exits 0.
- US-4.AC2: Given a home whose skills folder holds a dangling link that points outside this checkout, a dangling link with a relative target, and a real folder that is not a link, when the installer runs, then all three are still there and no `pruned` line is printed.

## Decisions

- Testing seams: the exit codes and printed lines of the workflow script (entry check, task gate), the citation check and the installer, driven from the repo's own test suites with specs, skill copies and throwaway homes written by the tests. US-3.AC1 is a test that searches the shipped files.
- Entry rule, decided by the workflow script on the first word of the argument, after any opening quote: an existing file means `spec`; a word ending in `.md` that names no file is refused; no argument is refused; anything else is `task`. `AFK` after a spec path is allowed as today; after a task it is refused.
- One flow: `/direct` step 1 runs the entry check. `spec` continues as today. `task` writes a small spec, asks once, then continues with the same steps in the same session. The task text lives inside step 1, so no step is renumbered and no separate file is read.
- What the task path keeps from `/quick`, as skill text: stop and say `/grill-me` when the task needs more than 3 ACs, more than 3 questions, a new route, table, migration, tool input, or a paid or auth path; never guess a choice the user can observe, ask it in the one approval message; Out of Scope names the nearest thing a builder might add; the spec stays draft until an explicit yes; the optional feature slug is the word after the quoted task; the index's Open questions line is `none`. The 3-AC cap is checked by the task gate (US-2); the rest is the model's judgement, accepted by the Manual check.
- Citation check: it moves beside `/direct` and keeps only the 4 `/spec` items the task path cites by number (hard rules 3, 4 and 5, and step 3 with its `spec checks:` line). It no longer checks `/direct`'s own steps, because nothing outside `/direct` cites them.
- Gate mode: `--quick` is renamed `--task`; the old name is not kept as an alias. Only the name and the wording of its lines change: it still refuses a draft, a malformed spec, the wrong branch and uncommitted changes as before. It runs after the owner's yes and the spec commit; a requested change edits the spec and asks again, and nothing is built before a yes.
- `/quick` is deleted outright, with no stub that redirects.
- Prune rule: only links directly inside `~/.claude/skills` and `~/.claude/hooks` whose stored target is an absolute path starting with this checkout's path and does not exist. Relative links, nested entries and anything else are left alone. It runs on every install, with or without `--replace`.
- Where `/quick` may still be named: the decisions log and past work folders, which are history. US-3.AC1 does not search them.
- Docs: the workflow rules (step 2), the README flow table and `/direct`'s description and argument hint name `/direct "<one-line task>"`. The decisions log gets one entry. Past work folders and earlier decisions log entries are not edited.

## Out of Scope

- Raising the task path's cap to 6 ACs, or dropping it (the unreviewed lane stays small).
- A `/quick` stub or alias (deleted outright).
- Pruning dangling links that point outside this checkout, or links anywhere but the skills and hooks folders.
- Cleaning installs made through skillshare (its own sync owns those links; checked by hand after the build).
- Changing `/spec`, `/slice`, `/build` or the orchestrated section of `/direct`.

## Manual check

1. In a scratch worktree of any project, run `/direct "<a one-line task>"`: it writes a spec with at most 3 ACs, shows the ACs and Out of Scope, asks once, and after a yes builds it in the same session and ends with the hand-off to `/encode-comments` and `/final-review`.
2. Run `/direct` with the path of an approved spec: it builds as before, with no approval question.
3. Type `/quick`: no such command. On a home set up by the installer, re-run the installer: it prints a `pruned` line for the old quick link.
