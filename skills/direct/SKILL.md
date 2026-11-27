---
name: direct
description: Build an approved spec of any size with no ticket files, then hand to /final-review. Up to 6 ACs this session builds it test-first; above that it orchestrates helpers in parallel worktrees, one per part listed in the index, and writes no AC code itself.
disable-model-invocation: true
argument-hint: "<path to spec.md> [AFK]"
---

# /direct

The no-ticket lane: spec, index with parts, build, `/final-review`. `WF` below is `${CLAUDE_SKILL_DIR}/../build/scripts/wf`. A spec with at most 6 ACs is **solo**: Steps 1-7 in this session, one part. More is **orchestrated**: Steps 1-3, the Orchestrated section, then Step 7. A second word `AFK` (from `afk-loop`): read `${CLAUDE_SKILL_DIR}/../build/references/afk.md`, reading "ticket" as "part".

## Hard rules

1. **Solo up to 6 ACs, orchestrated above.** Count the spec's AC lines; lettered ones count.
2. **One red or guard commit per AC, subject exactly `test(US-n.ACm): red` or `test(US-n.ACm): guard`.** `/final-review` finds them by subject.
3. **Never edit, skip or weaken a test that existed before this session, or one of yours after its red commit.** The one exception is an existing test that pins a count, set, list or contract an AC changes: change only that, say so in the commit body, and log it with `WF ruling <index> "<part> (direct): <test file path> may change: <what>"`.
4. **Least code that turns the current test green.** Nothing the spec does not ask for; Out of Scope lines bind.
5. **Keep command output short.** Pipe test runs through `2>&1 | tail -40` (pytest with `-q`), read by line range or grep.

## Steps

1. **Gate.** The first word of `$ARGUMENTS` is the spec: `WF gate <spec> --direct`; show any line it prints and stop.
2. **Index.** An `index.md` beside the spec means a resume: a `doing` part whose `merge <part>:` commit is on HEAD resumes at Orchestrated step 5; `WF set` every other `doing` part to `todo`, log `WF ruling`, and continue from the first step or part not done. Otherwise write it from `${CLAUDE_SKILL_DIR}/assets/index-template.md`: `Spec`, `Branch` and `Base` from the spec, the test command from the project's CLAUDE.md, no `tickets/` folder. Solo: one row `| P1 | <feature> | none | todo |` and one Parts line holding every AC; orchestrated: Orchestrated step 1. Under `## Open questions`, every choice the spec leaves open or contradicts, or `none` (`/quick` writes `none`: its approval settled them). Send them all in one call to the decision agent (`${CLAUDE_SKILL_DIR}/../build/references/decide.md`, Dispatch; only its Escalate list reaches the user) and write each DECISION on its question's line as `Answer: <decision> (fable)`; an answer that changes behaviour updates the spec's ACs or Out of Scope in the same commit. Done when `WF questions <index>` and `WF parts <index>` print nothing. Commit `docs(direct): <feature> index`; solo: `WF set <index> P1 doing`.
3. **Read first.** Open the code each AC touches and grep every caller of anything you will change, before the first test.
4. **Per AC, in spec order:**
   - Write one test that fails whenever the AC is false, using the spec's own values. Run it; it must fail because the behaviour is missing, not from a typo. Commit only the test: `test(US-n.ACm): red`.
   - Write the code. Run the test; at most 3 tries, then stop and tell the user what you tried. Commit `feat(US-n.ACm): green`.
   - **Guard** (the test passes on arrival because the code already does it): write no code. Break the production code the way the AC forbids, see the test fail, and with the break still in place save `git diff -- <production files>` to a file outside the worktree. Restore with `git checkout -- <file>`, then commit the test with `git commit --cleanup=verbatim -F <message file>`: the subject `test(US-n.ACm): guard`, a blank line, the line `Mutation: <file>: <what you changed> -> <the failing line>`, then the saved diff between a line ```` ```diff ```` and a line ```` ``` ````. Never use `-m` for the patch: the default cleanup strips its blank lines and trailing spaces, so it no longer applies.
5. **Copy check.** If the branch changed any module-level string constant a person or the model reads, run `${CLAUDE_SKILL_DIR}/../build/scripts/mutate-copy --base <Base> <changed files> -- <the tests covering them, with -x and a `--deselect <file>` for each snapshot and golden test file>`. For each `SURVIVED` sentence that states a rule (an ask, a price, a limit, a never), add an assert on the rule and commit `test(copy): <CONSTANT> <rule>`. A sentence that only describes needs none: leave it for the review to list.
6. **Suite.** Run the index's `Test command` once. A failure that also fails at `Base` is not yours: name it. Then `WF done <index> P1 $(git rev-parse HEAD)`.
7. **Hand off.** Tell the user: `/clear`, then `/encode-comments <Base>`, then `/clear`, then `/final-review <spec path>`. AFK: a summary only.

## Orchestrated

You are the lead: you write the index, merge, and add glue of at most 40 changed lines outside the plan folder. Helpers write every AC. Run `WF lead <index>` after each commit of yours: a line it prints names that commit, still the tip, so `git branch <part>-lead && git reset --hard HEAD~1` and send that branch to the helper owning its files.

1. **Parts.** In Step 2, one row and one Parts line per part. A shared piece other parts need is its own earlier part. A feature that does not split is one part per 13 ACs, in spec order, each blocked by the one before. An AC the decision agent adds mid-build is a new last part, blocked by every part not done; re-run `WF parts`.
2. **Helpers.** `WF frontier <index>`; `all done` goes to step 5. For each runnable part, at most 5 at once, `WF set <index> <part> doing`; then `BASE=$(git rev-parse HEAD)`. Dispatch the whole wave in one message: Agent, `subagent_type: "general-purpose"`, `model: "opus"`, `isolation: "worktree"`, prompt `${CLAUDE_SKILL_DIR}/references/helper.md` filled with the part's line, the spec path, BASE, and the signatures it shares with other parts.
3. **On each report.** `blocked`: answer from the spec, else the decision agent, then SendMessage the answer to that helper. `done`: `${CLAUDE_SKILL_DIR}/../build/scripts/check-red-green.sh <WORKTREE> <BASE> "<Test command>" <index>:<part> <BASE>` (red, guard, green, delivers and wording). Any `FAIL`, or a `WARN wording` sentence that states a rule, goes back to the same helper with SendMessage; after 2 tries, `WF set <index> <part> "blocked: <check>"` and the decision agent.
4. **Merge.** `git merge --no-ff <BRANCH> -m "merge <part>: <title>"`: the lead check reads every first-parent commit as yours, so never fast-forward or squash. Conflict: `git merge --abort`, and the helper rebases on HEAD. Run the Test command; a failure resets to the merge's parent and goes back to the helper. Pass: `WF done <index> <part> <merge sha>`. The last part's `WF done` waits for step 8, so a restarted run still finds work. Keep the worktree: follow-up work on a part goes to the helper that built it, resumed with SendMessage (after a restart, a fresh helper from HEAD with the part's line and the findings). Back to step 2.
5. **Lead check.** `WF lead <index>` prints nothing.
6. **Read the merged change once.** `git diff <Base>...HEAD --stat`, then the diff.
7. **Quality review.** One Agent, `subagent_type: "general-purpose"`, `model: "opus"`, prompt `${CLAUDE_SKILL_DIR}/../build/references/quality-reviewer.md` with `<TICKET>` the spec path, `<BASE>` the Base and `<HEAD>` HEAD, plus this BLOCK check after its check 4: "4b. **Implicit state machine.** New code where two or more booleans or nullable fields combine to mean a mode, instead of one explicit status." `VERDICT: fix`: each finding goes to the helper whose part owns the file, merged as in step 4, then re-reviewed with the previous findings; after 2 fix rounds, the decision agent. Log `LOG:` lines with `WF ruling`.
8. **Suite.** Run the Test command once; a failure that also fails at `Base` is not yours: name it. Pass: `WF done <index> <last part> <its merge sha>`. Remove the helpers' worktrees and branches, then Step 7.
