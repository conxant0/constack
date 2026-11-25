---
name: quick
description: Small task with no grill. Writes a 1-3 AC spec from a one-line task, gets one approval, then builds it through /direct's steps in this session and hands to /encode-comments and /final-review. Same checks and reviews as the full workflow.
disable-model-invocation: true
argument-hint: "\"<one-line task>\" [feature-slug]"
---

# /quick

The no-grill lane: a spec you write in one pass, one approval, then `/direct` in this same session. Every later check (`wf red`, `/final-review`, the copy check, the security pass) reads that spec, so the spec stays; only the interview, the builder check and the question rounds go. `WF` below is `${CLAUDE_SKILL_DIR}/../build/scripts/wf`.

## Hard rules

1. **Fit, or stop and say `/grill-me`.** Stop before writing anything if the task needs more than 3 ACs, a new route, table, migration, tool input, or a paid or auth path, or more than 3 questions to pin down. Say which one it hit.
2. **Never invent.** A choice the one line does not settle and a user can observe (wording, a default, an error, an empty case) is a question in step 4, never a guess in an AC.
3. **`/spec`'s hard rules 3-5 bind.** Read them in `${CLAUDE_SKILL_DIR}/../spec/SKILL.md`: testable ACs, no file paths or names, `draft` until an explicit yes.
4. **Out of Scope names the nearest thing a builder might add** that the task did not ask for.

## Steps

1. **Branch.** Run `git branch --show-current` and `git rev-parse --abbrev-ref @{upstream}`. On the base (`WF base`), `main` or another base branch: stop and print `git worktree add ../<feature> -b feature/<feature> $(WF base)` then `cd ../<feature> && claude`, and tell the user to run `/quick` again there. No upstream: ask which base branch this work merges into, recommending what `WF base` prints.
2. **Read first.** The task is the quoted part of `$ARGUMENTS`; `<feature>` is the second word if given, else a short kebab-case slug. Grep and open the code the task touches, enough to know its testing seam and every caller. Then apply rule 1.
3. **Write** `docs/work/<feature>/spec.md` from `${CLAUDE_SKILL_DIR}/../spec/assets/spec-template.md`: one story, 1-3 ACs in Given/When/Then, a 1-2 sentence Problem, a Decisions list holding only the testing seam and any settled choice, Out of Scope, and a Manual check of 1-3 steps. Every Decision line that states behaviour a user or caller can observe needs an AC that shows it with one example, or it becomes a step 4 question. Then run the checks exactly as `/spec` step 3 says: `WF check-spec`, each executable `~/.claude/checks/spec-*` with the `spec checks:` line, and its exit 1 / exit 2 handling.
4. **One approval.** Send one message: the spec's path, its ACs and Out of Scope lines verbatim, then any rule-2 questions numbered, each with a recommended answer and a one-line reason. Ask: approve as written, or what to change. Apply changes, putting any answer that adds or changes behaviour into the ACs, not just Decisions, and ask again; a change that pushes it past rule 1 means stop and say `/grill-me`.
5. **Approve and build.** On an explicit yes: set `Status: approved`, re-run step 3's checks, `git add docs/work/<feature>/spec.md && git commit -m "docs(spec): <feature>"`. Then read `${CLAUDE_SKILL_DIR}/../direct/SKILL.md` and follow its hard rules and steps 1-7 with `docs/work/<feature>/spec.md` as its `$ARGUMENTS`. Its step 3 may reuse what step 2 here already read. Its step 7 is the hand-off: `/clear`, `/encode-comments <Base>`, `/clear`, `/final-review <spec path>`.
