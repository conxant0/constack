---
name: encode-comments
description: Strip comments and turn every rule a comment states into a test or lint rule. Runs pstack's no-comments with my overrides: on a feature's diff after /build or /direct and before /final-review, or on given paths for a one-off cleanup.
disable-model-invocation: true
argument-hint: "<base ref, e.g. origin/main | paths...> [AFK]"
---

# /encode-comments

A rule lives in a check that fails when the rule breaks: a test or a lint rule. A comment or an agent prompt holding it is prose nobody runs.

**Scope** comes from `$ARGUMENTS`, minus a final `AFK`:
- **Diff mode:** one word that is a git ref (default: what `~/.claude/skills/build/scripts/wf base` prints). Scope is the diff against it, including the working tree; "the base" below is that ref.
- **Path mode:** one or more files or directories that exist in the worktree (`git ls-files <paths>`). Scope is every comment in those files, existing ones included; "the base" below is `HEAD` when the run starts. A word that is both a ref and a path is a path.

A final word `AFK` means `scripts/afk-loop` runs this headless: no one is there to answer, so decide every call yourself, leave the tree committed, and make step 5's report the whole reply (afk-loop runs /final-review next).

## Steps

1. **Strip.** Read the newest `~/.claude/plugins/cache/cursor-plugins/pstack/*/skills/no-comments/SKILL.md` and follow its steps 1 and 2; the steps below replace its 3 to 6. Comment Sicko is `subagent_type: "pstack:comment-sicko"`. Pass Sicko the scope above as the caller's files or diff. Commit the accepted deletions as `chore(comments): strip comments`. Done when `git status --short` is empty.
2. **Encode every rule comment.** A rule comment states something that must or must never happen: an invariant, a budget or safety guarantee, an ordering, why a broad `except` or a suppression is allowed. Its wording is irrelevant; it need not say "do not remove". Find them in the removed lines of the strip commit (`git show HEAD`) and among the comments Sicko kept. For each:
   - Write a test (or a lint rule, when the rule is about code shape) in a place the project's test command collects.
   - Prove it **red** through that test command: make one break, the way the comment forbids and nothing else, and see the check fail. Restore with `git checkout -- <file>` and rerun it green. Red counts only when the failure is an assertion (or lint finding) in this rule's own check. An ImportError, SyntaxError, collection error, a crash before any assert, or a failure in a different test means the break was wrong, not that the rule is held: make a cleaner break (at most 2 tries), otherwise record the rule as unenforced.
   - Commit `test(comment): <rule>` with a body line `Mutation: <file>: <the break> -> <the failing assertion, quoted from the test output>`. A paraphrase such as "the new assertion fails" is not a quote. Delete the comment if Sicko kept it.
   - A rule no in-scope check can hold: leave it deleted and record it as unenforced.
   Done when every rule comment is encoded red-proven or recorded unenforced.
3. **Flags.** Fix only trivial accepted flags (delete a dead path, drop a parameter, use the real API), one commit each: `refactor(comments): <symbol>`. Every flag that needs a new shape or a wider root-cause fix is follow-up work for the report.
4. **Suite.** Run the project's test command once. A failure that also fails at the base is not yours: name it. If there are unenforced rules, commit an empty `chore(comments): unenforced rules` whose body lists each as `file:line: <comment text>`, so the rule outlives this session.
5. **Report**: deletion count, restored comments, reruns, each rule encoded (test name), each unenforced rule, each trivial fix, each follow-up flag (symbol and the reshape). End with the next step. Diff mode: `/clear`, then `/final-review <spec path>`. Path mode: push the branch, open a PR to the base (`~/.claude/skills/build/scripts/wf base`), and run `/security-review` from this worktree while it is open (no final review covers it).
