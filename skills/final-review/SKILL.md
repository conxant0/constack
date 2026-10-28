---
name: final-review
description: Whole-branch review against the spec after /build: every AC proven by a red or guard commit and an honest test, full suite green, nothing out of scope, security pass against the real base. Writes review.md; failures become fix tickets for /build.
disable-model-invocation: true
argument-hint: "<path to spec.md> [AFK] [FULL]"
---

# /final-review

The definition of done is the spec. This review proves each acceptance criterion was built and tested, and that nothing else was. The work is not done until `review.md` says `Verdict: PASS`.

## Hard rules

1. **Review against `Base:` from the index, never `origin/HEAD` or `main`.**
2. **Read-only until step 7.** You do not fix code. Failures become fix tickets that go through /build.
3. **Report only failures of the spec, the tests or security.** No style or "could be cleaner" findings. The one exception is step 5b, which is advisory and never changes the verdict.
4. **Never invent a requirement.** A finding no AC or Out of Scope line covers, and that is not a security finding, goes under OPEN for the user.

## Steps

1. **Gate.** The first word of `$ARGUMENTS` is the spec (a second word `AFK`: see step 8); the index is `index.md` in the same folder. Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf gate <spec> --final`. It checks the branch, a clean tree and that every ticket is `done`. If it prints anything, show it and stop. Run `git fetch origin`; set `BASE` to the index's `Base:` and `HEAD=$(git rev-parse HEAD)`.
   **Delta or full.** If any later word of `$ARGUMENTS` is `FULL`, this is a **full** run. Otherwise, if `docs/work/<feature>/review.md` says `Verdict: FAIL` and the sha after `...` on its `Range:` line (`PREV`) is an ancestor of HEAD (`git merge-base --is-ancestor PREV HEAD`), this is a **delta** run: steps 4 and 6 re-judge only the fix work in `PREV..HEAD`. Otherwise it is a **full** run. Steps 2, 3 and 5 always cover the whole branch.
2. **Red commits.** Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf red <spec>`: every AC, lettered ones like AC7b included, needs a `test(<id>): red` or `test(<id>): guard` commit in `BASE..HEAD`. Each line it prints is a failure.
3. **Full suite.** Run the index's `Test command` once at HEAD. Record pass, or the failing test names.
4. **Tests check their AC.** For each AC, read its red or guard commit (`git log "$BASE..HEAD" --format='%h %s' | grep -E "test\(<id>\): (red|guard)$"`, then `git show <sha>`). Answer one question: does this test fail whenever the AC is false? For a guard, also check that the `Mutation:` in its body is a production-code change the AC forbids, and that the AC really was true before its ticket (else the green was skipped). A test that checks something narrower, different, or nothing is a failure.
   **Delta:** re-judge only an AC that (a) has a red or guard commit in `PREV..HEAD`, (b) has its test file in `git diff --name-only PREV HEAD`, or (c) is delivered by a ticket whose `Files` include a file in that diff. Copy every other AC's row from the previous `review.md`, noting `carried from <PREV short sha>`. If unsure whether an AC is affected, re-judge it.
5. **Out of Scope.** Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf scope <index>`: it lists changed files no ticket planned to touch. Read those diffs first. Then, for each Out of Scope line in the spec, check the relevant diff. Anything built that the line excludes is a failure.
5b. **Structure (advisory).** Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf size <index>`: each line is a file the branch pushed past 1000 lines or grew by 100+ while already over. Then read the branch diff (delta: `PREV..HEAD`) for: a near-duplicate of a helper that already exists (name its path), logic in the wrong layer per the project's CLAUDE.md, and a feature-specific branch added into a shared flow that its own module would keep out. At most 5 findings, each with the smaller structure that removes it, and only ones you would defend. No naming, formatting or taste. These go under `## Structure` in `review.md` only: never a fix ticket, never OPEN, never a FAIL.
6. **Security.** Follow `references/security.md` with `<BASE>` filled in. Then name the one fact the change is safe because of (e.g. "every new route resolves `account_id` before reading user data"), and prove it with a script or test that runs the real code, kept in the scratchpad, not the repo. Write the fact, the command and its output into `review.md`. If the proof fails, that is a security finding. If it cannot be proven, write `unproven` and put it under OPEN.
   **Delta:** fill `<BASE>` with `PREV`, and add to the finder prompt: "Earlier commits were already reviewed. For every function this diff changes, open each of its callers anywhere in the branch and check the change does not make that caller unsafe." Re-run the previous review's proof command at HEAD instead of writing a new one, unless the fix diff changes the fact it proves.
7. **Write** `docs/work/<feature>/review.md` from `assets/review-template.md`. `Verdict: PASS` only if steps 2-6 (not 5b) found nothing and OPEN is empty.
8. **On FAIL.** Propose fix tickets to the user as one list:
   - an AC failure: an `F<nn>` ticket delivering that AC
   - out-of-scope code: an `F<nn>` removal ticket (Delivers "none")
   - a security finding: a new AC under the story it belongs to, worded as Given/When/Then, plus an `F<nn>` ticket delivering it
   **AFK:** never call AskUserQuestion. If OPEN is not empty, commit `review.md` and stop: those are the user's. Otherwise approve the list yourself and log each new AC with `${CLAUDE_SKILL_DIR}/../build/scripts/wf ruling <index> "final-review (afk): added <AC id>, <why>"`.
   On approval: add any new ACs to the spec, write each `tickets/F<nn>-<slug>.md` from `assets/fix-ticket-template.md`, append them to the index as `todo`, and commit `docs(review): <feature> fix tickets`. Tell the user: `/clear`, `/build <index path>`, then `/final-review` again.
9. **On PASS.** Commit `review.md` (`docs(review): <feature> pass`). Tell the user it is ready for their manual check (the spec's Manual check section) and a PR against `Base:`.
