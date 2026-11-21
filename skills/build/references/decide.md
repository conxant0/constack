# Decide

After the grill, the user is out of the loop. A question a step would put to the user goes to Fable through this file instead, and the user hears only an escalation. /build, /slice and /final-review all point here.

## Escalate

These stay the user's, whoever is asked. Each one weakens a check:

- deleting, skipping or loosening an assertion, or editing a test written on purpose so the change can pass (build rule 8's pinned count, set, list or contract is still the lead's)
- raising a size or character limit (a `*_CHARS_MAX` constant, a description cap)
- waiving a final-review row that says `no` or `partly`
- a Verify row `not run`, or a branch that changes its own verify skill

Escalating: in AFK, follow `afk.md`'s blocked line. Otherwise, AskUserQuestion, with Fable's decision as the first option marked "(Recommended)". Log the answer with `pick: <Fable's decision>; chose: <their answer, or "pick">`.

## Dispatch

Send every open question at this stop in one Agent call: `subagent_type: "general-purpose"`, `model: "fable"`, no isolation. Give Fable the problem, not a menu. Its prompt:

1. Each question, numbered: what happened in the source's own words (the implementer's BLOCKER, the reviewer's finding, the failing command and its output), where it happened (file:line, worktree path, commit range), and the spec path.
2. Your pick as one line labelled `lead draft`, or none.
3. This instruction: "Read `~/.claude/skills/build/references/decide.md`, section Preferences. For each question, in order:
   a. Reproduce it: run the failing test, probe or command in the named worktree, or read the cited lines, and record what you saw. Probes go in the scratchpad; leave `git status --short` as you found it.
   b. Find the options yourself from what you reproduced. The lead draft is one candidate, written by the agent that hit the problem, and may be wrong or narrow.
   c. Decide by the Preferences.
   Answer each question in this shape:
   `Q<n>: REPRODUCED: <command and what it showed> | does not happen: <command and output> | could not run: <why> | n/a (nothing to run, e.g. an AC's wording) | OPTIONS: <the ones you weighed> | DECISION: <one of them> | WHY: <one sentence naming the preference that settled it> | ESCALATE: yes|no | SPEC: <the AC or Out of Scope line to add or change, or none>`
   ESCALATE is yes only for a decision the Escalate section lists."

On the reply:

- **Could not run:** send that question back once with what it lacked (a path, a worktree, a command). A second `could not run` is escalated: an issue nobody could see is decided by the user.
- **Does not happen:** the decision is no change; the finding or blocker was wrong.
- **Escalate:** check each decision against the Escalate section yourself, whatever Fable answered.
- **The rest:** act on it as if the user had answered. A SPEC line that changes an AC's wording or an Out of Scope line goes into the spec in the same commit as the ticket change. Log each decision with `wf ruling <index> "<id> (fable): <question>; reproduced: <one line>; decided: <DECISION>; why: <WHY>"`.
- **A SPEC line that adds an AC** is built as its own last ticket, so no other ticket builds on it. Commit the AC line and a new ticket file delivering only that AC on their own (`docs(spec): <AC id> (fable)`), add its index row blocked by every ticket not yet `done`, and put that commit's sha in the ruling line. Undoing the decision is then `git revert -m 1 <its merge sha>`, `git revert <that sha>`, and deleting its index row. In /slice the AC still gets that commit at step 3, and step 6 slices it as one ticket blocked by every other. The AC of a final-review security or behaviour finding is required, not chosen, and is exempt.

## Preferences

Apply them in order. The first one that settles a question decides it.

1. **Money is right now.** A bug that charges wrongly or twice, or loses what a customer paid for, is fixed in this branch.
2. **The smaller change.** Behaviour the spec did not ask for (an edge case found in review, a bug older than the branch) gets an Out of Scope line plus a `TODOS.md` entry, not a new AC. The story's promise holds: when an Out of Scope line would leave a user story's "so that" false, choose the fix. A refactor no AC needs is declined.
3. **Existing behaviour stays.** Choose the option that leaves current product behaviour and existing tests as they are, unless an AC says otherwise.
4. **The repo's rules bind.** The project's CLAUDE.md and `.claude/rules/` beat any option that breaks them.
