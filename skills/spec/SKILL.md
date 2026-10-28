---
name: spec
description: Turn the grill conversation in this session into docs/work/<feature>/spec.md, the definition of done. Run right after the grill, in the same session.
disable-model-invocation: true
argument-hint: "[feature-slug]"
---

# /spec

Synthesize the grill that just happened into a spec. The file is the handoff: every later stage reads it in a fresh session.

## Hard rules

1. **No new interview.** Write from the conversation. The only questions you ask are the one round in step 5.
2. **Never invent.** Anything the conversation did not settle is written as `OPEN: <question>` where the answer belongs.
3. **Every AC is testable.** If you could not write a failing test for it ("fast", "intuitive", "clean"), rewrite it with a measurable threshold the grill supports, or mark it `OPEN`.
4. **No file paths, function names or signatures.** They go stale. The plan names them.
5. **Status stays `draft`** until the user explicitly approves and no `OPEN` remains.

## Steps

1. **Check the branch.** Run `git branch --show-current` and `git rev-parse --abbrev-ref @{upstream}`.
   - On `main`, `staging` or another base branch: stop. Tell the user to create the integration worktree first and relaunch inside it:
     `git worktree add ../<feature> -b feature/<feature> origin/staging`
     `cd ../<feature> && claude` (terminal), or open that folder in the desktop app. `worktree.baseRef: head` is set in `~/.claude/settings.json`.
   - No upstream: ask which base branch this work merges into.
2. **Name it.** `<feature>` is `$ARGUMENTS` if given, else a short kebab-case slug from the grill.
3. **Write** `docs/work/<feature>/spec.md` from `assets/spec-template.md`. Number stories `US-1`, `US-2`... and their criteria `US-1.AC1`, `US-1.AC2`... in Given/When/Then. Every Out of Scope item the grill named goes in Out of Scope. Then run `${CLAUDE_SKILL_DIR}/../build/scripts/wf check-spec docs/work/<feature>/spec.md` and fix every line it prints.
4. **Builder check.** Dispatch one subagent (`general-purpose`, `model: "sonnet"`) with the prompt in `references/builder-check.md`, filling in the spec's absolute path. Do not pass it the conversation.
5. **One question round.** Send the user a single numbered message containing every `OPEN` item plus the builder's questions (drop duplicates). Give each a recommended answer with a one-line reason.
6. **Update** the spec with the answers. Any answer that adds or changes behaviour updates the stories and ACs, not just the Decisions.
7. **Approve.** Show the path and ask for approval. Apply requested edits and ask again. On explicit approval, with no `OPEN` left:
   - set `Status: approved`, run `wf check-spec` again, and fix every line it prints
   - `git add docs/work/<feature>/spec.md && git commit -m "docs(spec): <feature>"`
8. **Hand off.** Tell the user: `/clear`, then `/slice docs/work/<feature>/spec.md`.
