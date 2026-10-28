## Workflow

1. Worktree first: `git worktree add ../<feature> -b feature/<feature> origin/<base>`, then `cd ../<feature> && claude --settings '{"worktree":{"baseRef":"head"}}'` on every start and resume. Every stage runs there.
2. Plan: /grill-me, then /spec in the same session. The spec (`docs/work/<feature>/spec.md`) holds numbered user stories with `US-n.ACm` acceptance criteria and an Out of Scope list: it is the definition of done. Any later scope change updates the spec in the same commit.
3. `/clear`, then `/slice <spec>`: vertical-slice tickets plus `index.md`. I approve the slice table before ticket files are written.
4. `/clear`, then `/build <index>`: Sonnet implementers test-first in parallel worktrees, a reviewer per ticket, lead-only merges. A ruling on architecture or scope stops the run: ask me with AskUserQuestion.
5. `/clear`, then `/final-review <spec>`: AC coverage, full suite, Out of Scope, and a security pass against the spec's `Base:`. Failures become fix tickets back through /build. Then I test manually against the spec's Manual check and open the PR (`/pr`).
