Prompt for the code-map Explore subagent. Replace <SPEC_PATH> with the spec's absolute path.

---

Read <SPEC_PATH>. Then map the code this spec will touch. Return paths, signatures and short facts only. Never paste file contents or code bodies.

Return exactly these sections:

## Touches
Per user story (US-n): the existing files it will change or sit next to, and the existing functions, endpoints, components or tables involved, as `path: signature or shape`, with parameter and return types and table column types.

## New code goes
Where new files of each kind belong, following existing patterns: `kind: directory (example sibling file)`.

## Tests
- Full suite command: `<command>`
- Command to run one test file: `<command with a placeholder path>`
- Where test files live and how they are named, with one example path per kind (unit, route/API, UI).

## Project rules
Rules from CLAUDE.md, AGENTS.md, .claude/rules/ or similar that apply to the files above (copy wording, naming, layering, security, migrations). One line each, quoted or tightly paraphrased, with the file it came from.

## Conflicts
Anything in the code that contradicts the spec or that the spec does not decide. One line each. Write "none" if none.

Keep the whole report under 80 lines.
