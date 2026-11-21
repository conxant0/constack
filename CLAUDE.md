@RTK.md

## Workflow

1. Worktree first: `git worktree add ../<feature> -b feature/<feature> <base>` (`<base>` is what `~/.claude/skills/build/scripts/wf base` prints), then `cd ../<feature> && claude` on every start and resume. Every stage runs there.
2. Plan: /grill-me, then /spec in the same session. The spec (`docs/work/<feature>/spec.md`) holds numbered user stories with `US-n.ACm` acceptance criteria and an Out of Scope list: it is the definition of done. Any later scope change updates the spec in the same commit.
3. Small spec (at most 6 ACs, no new route, table, migration, tool input, paid or auth path): `/clear`, then `/direct <spec>` builds it in one session with no tickets, and I skip to step 5. Otherwise `/clear`, then `/slice <spec>`: vertical-slice tickets plus `index.md`. I approve the slice table before ticket files are written.
4. `/clear`, then `/build <index>`: implementers test-first in parallel worktrees, two reviewers per ticket (ticket fit, plus test strength and duplication; models are whatever the build skill sets), lead-only merges. A ruling on architecture or scope stops the run: ask me with AskUserQuestion.
5. `/clear`, then `/encode-comments <Base>` (strips added comments; each rule a comment states becomes a test or lint rule), then `/clear`, then `/final-review <spec>`: AC coverage, full suite, Out of Scope, and a security pass against the spec's `Base:`. Failures become fix tickets back through /build. Then I test manually against the spec's Manual check and open the PR (`/pr`). The final review's security pass is the PR's security review: never list `/security-review` as pending, owed or "not run" on a branch that passed /final-review, and never offer to run it again. Write it as "Security review: done in the final review".

## Code rules

- No implicit state machines: when two or more booleans or nullable fields combine to mean a mode (`isLoading`, `error`, `data`), replace them with one explicit status (enum or discriminated union) changed in one named place.
- Enforce with a check: something we want held or never want is a test or a lint rule that fails when it breaks. A code comment or an agent prompt line holding it is a gap to close with a check. Every check prints a `Fix:` saying how to repair what it flags, and the run that hits it routes the failure to the agent that owns it (at most 2 tries) before it reaches me. A check's own test asserts the `Fix:` text.
