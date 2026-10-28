---
name: pr
description: Write a human-first PR title and body from the spec, review.md or the diff, show it, then push and open a draft PR (or rewrite the body of the branch's open PR). Use when the user types /pr.
disable-model-invocation: true
argument-hint: "[base branch, defaults to the spec's Base: or staging]"
---

# /pr

A reviewer reads only the top section. It shows what changed (in visuals, not paragraphs), what feedback is wanted, the before and after, and whether a revert undoes it. Everything else is folded away. Sources: Google eng-practices "Writing good CL descriptions", GitHub Docs "Helping others review your changes", Pirouzkhah et al., MSR 2026 (stating the feedback wanted was the strongest predictor of merge, yet only 16% of PRs include it), and Matt Pocock's `pr` skill for the Summary visuals, Evidence and Merge danger.

## Hard rules

1. **Never push or open anything before the user says "go"** to the exact title and body shown.
2. **Always a draft. No reviewers, no labels.**
3. **Base:** the argument, else `Base:` from `docs/work/<feature>/spec.md` or `index.md`, else `staging`. Refuse `main` unless the user typed it.
4. **Repo copy rules bind the title and body:** read the repo's `CLAUDE.md` and follow any copy or brand-voice rules in it. Never name a customer ("a customer asked for X"). No `Co-Authored-By` line or Claude attribution.

## Steps

1. **Check, and stop on any failure.** `git branch --show-current` is not `main` or `staging`. `git status --short` is empty. Run `gh pr view --json number,url,body` to see whether the branch already has an open PR (that switches step 5 to an edit).
2. **Gather.** Use `docs/work/<feature>/spec.md` and `review.md` if present: user stories, Manual check, Out of Scope, measured results. Also read `git log --oneline <base>..HEAD` and `git diff <base>...HEAD --stat`, then the diff itself. The body describes the diff as it is now, not the plan.
3. **Draft** in this shape (omit any section that would be empty):

   ````
   Title: type(scope): imperative summary
     type = feat | fix | docs | plan | test | chore. One sentence that stands alone.

   > Staging-only banner, only when it cannot be fully tested until merged to staging.

   ## Summary
   1-2 sentences: the cost before, what this does.

   <caption line>
   ```text
   <visual, see "Visuals" below>
   ```

   **Review ask:** the feedback wanted (design call, correctness of X, naming) and which file to open first.

   ## Evidence
   - **Before:** failing test as pseudocode, console output, or a measured cost ("0 of 20 had an email").
   - **After:** the same test passing, the new output, or the same measure now.

   ## Merge danger
   **Door:** Two-way: a revert fully undoes this.
     or  One-way: a revert won't undo it, because <the migration already ran / emails were sent / credits were charged>.
   **Blast radius:** <one word>: who or what breaks if this is wrong.
   **Touches:** auth, credits, data writes, migrations or rate limits, or "none". Security review: pending | done (by hand over origin/<base>...HEAD).

   <details><summary>Changes</summary> (a table when there are 3+ tools, endpoints or files of note) </details>
   <details><summary>Tests</summary> (command run, result, known baseline failures) </details>
   <details><summary>Manual check</summary> (from the spec) </details>
   <details><summary>Out of scope</summary> (from the spec) </details>
   ````

   Keep the prose of the top section (banner through Merge danger) under 120 words; visuals do not count. Name the cost in the "before", never "Fix bug". Skip preambles.

   **Visuals.** Pick the smallest view that answers the reviewer's first question. Add another only if it answers a different question. Max 3, each a different kind, each with one caption line above it, about 40 lines in total. Past that the PR is too big: say so and suggest a split. No Mermaid (the draft is approved in a terminal). Kinds:

   - **Pseudocode** for logic or an algorithm (scoring, matching, gating).
   - **Call tree** for runtime flow, e.g. `tool -> service -> repository -> table` for a new endpoint or MCP tool.
   - **Component tree** for UI structure, with the state and module boundaries that matter.
   - **Shallow file tree** for a broad refactor.
   - **Shaped diff** (a `diff` block of any of the above) when the surrounding shape already exists and the point is what changed. Usually the best choice for a fix:

     ```diff
      checkPush(run)
     +  if run is dead
     +    finish run on the portal first
        read portal state
     ```

   **Evidence.** A before and an after, never just "tests are green". Screenshots are strongest for a visual change; otherwise the exact test that failed and now passes, as pseudocode, or console output. Label numbers measured or inferred, with dates.

   **Door.** Spell out what a revert does or does not undo, every time, so a reader who has never heard "one-way door" still gets it. These are always one-way, whatever the diff looks like: migrations, billing or credit charges, writes to production user data, anything that emails or notifies a customer, destructive table reloads, and anything sent to an external service. A feature flag stays two-way only until the first write lands in the new format.
4. **Verify the draft.** Grep the title and body for anything the repo's `CLAUDE.md` copy rules forbid. Re-read the body against the diff and delete every claim the diff does not support; check each visual names only functions, files and components that exist in the diff. Check the door against the one-way list. Then show the title and body and wait for "go".
5. **Ship.** Run `git push -u origin HEAD`, then either `gh pr create --draft --base <base> --title ... --body-file <tmp>`, or `gh pr edit <n> --title ... --body-file <tmp>` when a PR already exists. Write the body file in the scratchpad.
6. **Report.** Give the PR URL, then: "Next: open a session in this worktree and run `/security-review`. It diffs against the default branch, so if its file list is wider than `git diff --name-only origin/<base>...HEAD`, review that range by hand."
