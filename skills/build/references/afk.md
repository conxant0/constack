# AFK mode

Run headless by `scripts/afk-loop`; no one is there to answer, and a fresh session resumes from the index.

- **Questions go to Fable** (rule 6, `decide.md`), as in a run with the user present. AskUserQuestion is blocked.
- **An escalation blocks its ticket.** Write `wf set <index> <id> "blocked: ask-user: <question>; pick: <Fable's decision>"` and `wf ruling <index> "<id> (afk): <question>, the file:line evidence, and the worktree and commit range of any work already done"` (the user resolves it with `/unblock`, which reads this line), drop that ticket (and the rest of its chain), and keep going with the others.
- **Rulings are tagged** `(fable)` for Fable's decisions and `(afk)` for yours: afk-loop's PASS alert counts both.
- **A `blocked: conflict` or `blocked: post-merge suite` ticket** goes to rule 6 once: write its decision into the ticket as an Approach line `Ruling <date> (fable): <what the next implementer does differently>`, then `wf set <index> <id> todo`. A second block on the same ticket stays blocked for the user.
- **Context budget.** After 3 merges this session, dispatch nothing new; finish and merge the tickets already in flight, then go to Finish. A chain gets 1 ticket per implementer: after its merge, remove its worktree and leave the next ticket `todo` for a fresh implementer.
- **Finish** prints the summary only, no `/clear` instructions.
