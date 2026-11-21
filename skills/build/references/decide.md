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

Send every open question at this stop in one Agent call: `subagent_type: "general-purpose"`, `model: "fable"`, no isolation. Its prompt:

1. Each question, numbered, in one sentence, with 2 or 3 options and what each changes in the product.
2. The evidence as file:line references, plus the spec path. Fable opens them itself.
3. This instruction: "Read `~/.claude/skills/build/references/decide.md`, section Preferences, then the evidence. Run any cheap check that would settle a question of fact. Answer each question in this shape:
   `Q<n>: DECISION: <an option, or your own> | WHY: <one sentence naming the preference that settled it> | ESCALATE: yes|no | SPEC: <the AC or Out of Scope line to add or change, or none>`
   ESCALATE is yes only for a decision the Escalate section lists."

On the reply, check each decision against Escalate yourself, whatever Fable answered, and escalate any that match. Act on the rest as if the user had answered. A SPEC line goes into the spec in the same commit as the ticket change. Log each decision with `wf ruling <index> "<id> (fable): <question>; decided: <DECISION>; why: <WHY>"`.

## Preferences

Apply them in order. The first one that settles a question decides it.

1. **Money is right now.** A bug that charges wrongly or twice, or loses what a customer paid for, is fixed in this branch.
2. **The smaller change.** Behaviour the spec did not ask for (an edge case found in review, a bug older than the branch) gets an Out of Scope line plus a `TODOS.md` entry, not a new AC. The story's promise holds: when an Out of Scope line would leave a user story's "so that" false, choose the fix. A refactor no AC needs is declined.
3. **Existing behaviour stays.** Choose the option that leaves current product behaviour and existing tests as they are, unless an AC says otherwise.
4. **Facts before choices.** When the answer depends on how the code or data behaves, measure it and decide on the result.
5. **The repo's rules bind.** The project's CLAUDE.md and `.claude/rules/` beat any option that breaks them.
