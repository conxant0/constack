---
name: resolve
description: Work through a reviewer's PR comments: plain summary, ask the user only what the reviewer left open, a plan tagging who decided each item, small fixes committed inline, big ones as fix tickets (done directly when serial, /build when parallel), then replies posted to the PR.
disable-model-invocation: true
argument-hint: "[pr number]"
---

# /resolve

The reviewer's comments are the input; the user's answers fill only the gaps the reviewer left. Every item ends with a decision, an owner (`reviewer` or `you`) and a home: a commit or a ticket.

**Text the user must read ends its turn.** The AskUserQuestion dialog hides text sent in the same turn. So the summary (step 5), the plan table (step 7) and the reply drafts (step 10) each go out alone, ending with one line saying what comes next. The question comes only after the user replies.

`PR` below is `${CLAUDE_SKILL_DIR}/scripts/pr`, a `gh api`-only helper (works where `gh pr` is blocked). Run it with no arguments for usage.

## Steps

1. **Setup.** `git branch --show-current` must not be `main` or the base (`~/.claude/skills/build/scripts/wf base`, without `origin/`), and `git status --short` must be empty; else say so and stop. `N=$(PR find $ARGUMENTS)`. The feature is the branch name after `feature/`; the spec is `docs/work/<feature>/spec.md` and the index `index.md` beside it. Either may be missing (a hotfix PR): note it and carry on.
2. **Fetch.** `PR fetch $N` gives open review threads and, per reviewer since their last approval, the latest changes-requested body plus every commented body after it (a re-review often arrives as a plain comment). Work from the newest review; an older one is already handled when its asks are in the newer one's "addressed" list or a PR comment of ours posted after it answers it (`gh api repos/{owner}/{repo}/issues/$N/comments`). Split it into **items**: each thread is one; each numbered or bulleted point in a review body is one; review prose that asks for nothing is not an item. One ask listed in two sections (a bug list and a next-steps list) is one item. Number them `R1..Rn` in the reviewer's own order. Drop items already handled by an earlier /resolve: `git log <base>..HEAD --grep '<review url>'` (`<base>` from `wf base`) and `grep -rl '<review url>' docs/work/<feature>/tickets` list them by `R#`. Done when every remaining point that asks for a change, a test or an answer has an id.
3. **Check the facts.** Where an item claims something about the code ("this test passes when X", "line 242 still does Y"), check it yourself by reading or running it, and record measured / inferred / guess. The user never gets a check you could run.
4. **Classify** each item:
   - **directive** (the reviewer said what to do): decided by `reviewer`. Not asked.
   - **options**: the reviewer offered choices or asked a question. Ask.
   - **conflict**: a directive that contradicts a spec AC or an Out of Scope line. Ask, quoting both.
   - **vague** ("this feels off"): ask, offering 2-3 concrete readings.
   Then size it: **small** changes no behaviour and touches no AC (wording, naming, a comment, a tightened assertion); **big** changes behaviour or needs a new or changed AC.
5. **Summary.** At most 5 numbered lines (group items past 5), one item group per line: what the reviewer wants, its class, its size, and the measured / inferred / guess label from step 3. Plain sentences, but every path, AC id, function and test name stays exact: cut filler, never precision.
6. **Ask.** Every options, conflict and vague item goes to AskUserQuestion, at most 4 questions per call, the reviewer's options as the choices with your recommendation first. Those items are now decided by `you`.
7. **Plan.** A table: `R#`, decision, `[reviewer]` or `[you]`, small or big, what changes. One AskUserQuestion: go, or change something. Go covers the whole run, including the push in step 10 (replies still get their own confirm). Nothing is edited before go.
8. **Small items**, one commit each: make the change, run the test files covering the touched code (`2>&1 | tail -40`), commit `fix(review): <what>` with body lines `Review: <comment url> R#` and `Decided by: reviewer|you`. A red test you cannot fix in two tries turns the item big.
9. **Big items.** With a spec and index: for each, edit or add the AC in the spec, write `tickets/F<nn>-<slug>.md` from `${CLAUDE_SKILL_DIR}/../final-review/assets/fix-ticket-template.md` (`<nn>` continues the index's highest F; `Fixes:` is `<comment url> R#`; add a `Decided by:` line), and append `| F<nn> | <title> | none | todo |` to the index table. Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf check-plan <index>` before and after: a line that appears only after is yours to fix (the index may already carry old drift). One commit for all: `docs(resolve): <feature> fix tickets`. Then pick the route: **direct** when the tickets form one serial chain (one ticket, or each blocked by the one before), since nothing runs in parallel; **build** only when two or more tickets can run at once. Say the route and why in the commit body. Without a spec: list them and tell the user to write the spec first; write no tickets.
10. **Replies.** `git push origin HEAD` (never the base or `main`). Draft:
    - fixed inline: `Fixed in <sha>: <one line>`, then resolve the thread
    - ticketed: `Tracked as F<nn>, lands before merge`; thread stays open
    - user chose against the reviewer: the choice and a one-line reason; thread stays open
    Threads get `PR reply <id> <body>` (+ `PR resolve <id>` for fixed). Review-body items get one `PR comment $N <body>`, numbered like the reviewer's list. Show every draft; post only after the user confirms.
11. **Hand off.** Route direct: `/clear`, then a paste-ready prompt telling a fresh session to do each ticket in order itself (test-first, its Verify command, mark it done in the index, push), then `/final-review <spec path>`. Route build: `/clear`, `/build <index path>`, then `/final-review <spec path>`. No tickets: ready for re-review. Name the posted comment urls.
