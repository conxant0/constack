---
name: direct
description: Build a small approved spec in this one session, test-first, with no tickets and no subagents, then hand to /final-review. For copy-only and other small changes where /slice and /build cost more than the change itself.
disable-model-invocation: true
argument-hint: "<path to spec.md>"
---

# /direct

The light lane: spec, this session, `/final-review`. It writes no ticket files and dispatches no implementer or reviewer; `/final-review` is the only review, so every commit must be one it can read. `WF` below is `${CLAUDE_SKILL_DIR}/../build/scripts/wf`.

## Hard rules

1. **Fit, or stop and say `/slice <spec>`.** `WF gate --direct` holds approved and at most 6 ACs; you judge that no AC needs a new route, table, migration, tool input, or a paid or auth path. If the work turns out to need one of those, or passes about 150 changed non-test lines, stop where you are, commit what is green, and say `/slice`.
2. **One red or guard commit per AC, subject exactly `test(US-n.ACm): red` or `test(US-n.ACm): guard`.** `/final-review` finds them by subject.
3. **Never edit, skip or weaken a test that existed before this session, or one of yours after its red commit.** The one exception is an existing test that pins a count, set, list or contract an AC changes: change only that, and say so in the commit body.
4. **Least code that turns the current test green.** Nothing the spec does not ask for; Out of Scope lines bind.
5. **Keep command output short.** Pipe test runs through `2>&1 | tail -40` (pytest with `-q`), read by line range or grep.

## Steps

1. **Gate.** `WF gate $ARGUMENTS --direct`; show any line it prints and stop. Then judge the rest of rule 1.
2. **Index.** Write `index.md` beside the spec from `${CLAUDE_SKILL_DIR}/../slice/assets/index-template.md`: `Spec`, `Branch` and `Base` from the spec, the project's test commands from its CLAUDE.md, and one row `| T01 | <feature> (direct) | none | todo |`. No `tickets/` folder. Commit `docs(direct): <feature> index`, then `WF set <index> T01 doing`.
3. **Read first.** Open the code each AC touches and grep every caller of anything you will change, before the first test.
4. **Per AC, in spec order:**
   - Write one test that fails whenever the AC is false, using the spec's own values. Run it; it must fail because the behaviour is missing, not from a typo. Commit only the test: `test(US-n.ACm): red`.
   - Write the code. Run the test; at most 3 tries, then stop and tell the user what you tried. Commit `feat(US-n.ACm): green`.
   - **Guard** (the test passes on arrival because the code already does it): write no code. Break the production code the way the AC forbids, see the test fail, restore with `git checkout -- <file>`, and commit `test(US-n.ACm): guard` with a body line `Mutation: <the change you made and the failure it gave>`.
5. **Copy check.** If the branch changed any module-level string constant a person or the model reads, run `${CLAUDE_SKILL_DIR}/../build/scripts/mutate-copy --base <Base> <changed files> -- <the tests covering them, with -x and a `--deselect <file>` for each snapshot and golden test file>`. For each `SURVIVED` sentence that states a rule (an ask, a price, a limit, a never), add an assert on the rule and commit `test(copy): <CONSTANT> <rule>`. A sentence that only describes needs none: leave it for the review to list.
6. **Suite.** Run the index's `Test command` once. A failure that also fails at `Base` is not yours: name it. Then `WF done <index> T01 $(git rev-parse HEAD)`.
7. **Hand off.** Tell the user: `/clear`, then `/encode-comments <Base>`, then `/clear`, then `/final-review <spec path>`.
