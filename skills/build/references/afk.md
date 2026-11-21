# AFK mode

Run headless by `scripts/afk-loop`; no one is there to answer, and a fresh session resumes from the index.

- **Never call AskUserQuestion.** Wherever a step says ask the user, write your pick into `wf set <index> <id> "blocked: ask-user: <question>; pick: <yours>"` and `wf ruling <index> "<id> (afk): <question>, the file:line evidence, and the worktree and commit range of any work already done"` (the user resolves it with `/unblock`, which reads this line), drop that ticket (and the rest of its chain), and keep going with the others.
- **Rulings are tagged `(afk)`**, not `(lead)`: afk-loop's PASS alert counts them.
- **`split`:** approve it yourself, write the tickets as usual, and log `wf ruling <index> "<id> (afk): split into <ids>, why"`.
- **Context budget.** After 3 merges this session, dispatch nothing new; finish and merge the tickets already in flight, then go to Finish. A chain gets 1 ticket per implementer: after its merge, remove its worktree and leave the next ticket `todo` for a fresh implementer.
- **Finish** prints the summary only, no `/clear` instructions.
