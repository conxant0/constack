---
name: pr
description: Write a human-first PR title and body from the spec, review.md or the diff, show it, then push and open a draft PR (or rewrite the body of the branch's open PR). Use when the user types /pr.
disable-model-invocation: true
argument-hint: "[base branch, defaults to the spec's Base: or wf base]"
---

# /pr

A reviewer reads only the top section. It shows what changed (in visuals, not paragraphs), what feedback is wanted, the before and after, and whether a revert undoes it. Everything else is folded away.

## Hard rules

1. **Never push or open anything before the user says "go"** to the exact title and body shown.
2. **Always a draft. No reviewers, no labels.**
3. **Base:** the argument, else `Base:` from `docs/work/<feature>/spec.md` or `index.md`, else `~/.claude/skills/build/scripts/wf base`. Drop the `origin/` prefix for `gh`.
4. **Repo copy rules bind the title and body:** read the repo's `CLAUDE.md` (brand voice) and, if it exists, `~/.claude/checks/pr.md` (private rules; they add to these). No em dashes. No `Co-Authored-By` line or Claude attribution.

## Steps

1. **Check, and stop on any failure.** `git branch --show-current` is not `main` or the base. `git status --short` is empty. Run `gh pr view --json number,url,body` to see whether the branch already has an open PR (that switches step 5 to an edit). Run any pre-push check `~/.claude/checks/pr.md` names.
2. **Gather.** Use `docs/work/<feature>/spec.md` and `review.md` if present: user stories, Manual check, Out of Scope, measured results. Also read `git log --oneline <base>..HEAD` and `git diff <base>...HEAD --stat`, then the diff itself. The body describes the diff as it is now, not the plan.
   **Size.** From `git diff --numstat <base>...HEAD`, sum added and deleted lines into docs (`docs/**` or `*.md`), tests (a path containing `test`) and source (the rest). Name any single file over 1000 changed lines (usually a generated snapshot). If source is over 800 lines, tell the user before drafting and propose a split along ticket or user-story lines; draft as one PR only if they say so.
3. **Draft** in this shape (omit any section that would be empty):

   ````
   Title: type(scope): imperative summary
     type = feat | fix | docs | plan | test | chore. One sentence that stands alone.

   ## Summary
   1-2 sentences: the cost before, what this does.

   <caption line>
   ```text
   <visual, see "Visuals" below>
   ```

   **Review ask:** the feedback wanted (design call, correctness of X, naming) and which file to open first.
   **Size:** source +a -b · tests +c -d · docs +e -f. Merge with squash.

   ## Evidence
   - **Before:** failing test as pseudocode, console output, or a measured cost ("0 of 20 had an email").
   - **After:** the same test passing, the new output, or the same measure now.

   ## Merge danger
   **Door:** Two-way: a revert fully undoes this.
     or  One-way: a revert won't undo it, because <the migration already ran / emails were sent / money was charged>.
   **Blast radius:** <one word>: who or what breaks if this is wrong.
   **Touches:** auth, billing, data writes, migrations or rate limits, or "none". Security review: read `## Security` and the `Range:` line in `docs/work/<feature>/review.md`. Run `~/.claude/skills/build/scripts/wf check-review docs/work/<feature>/review.md`. With no line containing `Range end`, write `done (/final-review <Date>, <short range>): <its findings, or "none">`. With one, write `done at <range end short sha>; not covered: <what that line says>` and tell the user before drafting. Write `pending` only when there is no review.md.

   <details><summary>Changes</summary> (a table when there are 3+ tools, endpoints or files of note) </details>
   <details><summary>Tests</summary> (command run, result, known baseline failures) </details>
   <details><summary>Manual check</summary> (from the spec) </details>
   <details><summary>Out of scope</summary> (from the spec) </details>
   <details><summary>Code diff (docs excluded)</summary> (see "Code diff" below) </details>
   ````

   The reviewer reads only the top section (title through Merge danger), so its prose says what they need to review and nothing else; visuals carry the detail. Name the cost in the "before", never "Fix bug". Skip preambles.

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

   **Code diff.** The real diff minus docs, so a reviewer can read the code without spec and plan noise: `git diff <base>...HEAD -- . ':(exclude)docs/**' ':(exclude)*.md'`. Put its `--stat` first, then the diff in a ````` ````diff ````` block (four backticks, so backticks inside the diff can't close it). GitHub caps a body at 65,536 characters: if the diff would push past about 60,000, keep only the `--stat` and write "Diff too large to inline, see Files changed." In the terminal preview, show this section as its `--stat` only.

   **Door.** Spell out what a revert does or does not undo, every time, so a reader who has never heard "one-way door" still gets it. These are always one-way, whatever the diff looks like: migrations, charges, anything that emails or notifies a user, anything sent to an external service, and anything the repo's `CLAUDE.md` or `~/.claude/checks/pr.md` calls one-way. A feature flag stays two-way only until the first write lands in the new format.
4. **Verify the draft.** Grep the title and body for em dashes (`grep -nP '\x{2014}'`), and apply every check in `~/.claude/checks/pr.md` if it exists. Re-read the body against the diff and delete every claim the diff does not support; check each visual names only functions, files and components that exist in the diff. Check the door against the one-way list. The greps cover the prose, not the Code diff block, but flag any em dash on an added (`+`) line. Then show the title and body and wait for "go".
5. **Ship.** Run `git push -u origin HEAD`, then either `gh pr create --draft --base <base> --title ... --body-file <tmp>`, or `gh pr edit <n> --title ... --body-file <tmp>` when a PR already exists. Write the body file in the scratchpad.
6. **Report.** Give the PR URL. Only if the body says `pending` or `not covered`, add: "Next: open a session in this worktree and run `/security-review`. It diffs against `main`, so if its file list is wider than `git diff --name-only origin/<base>...HEAD`, review that range by hand."
