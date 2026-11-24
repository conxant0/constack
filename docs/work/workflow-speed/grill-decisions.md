# workflow-speed: grill decisions (2026-11-24)

Input for /spec. Source: /grill-me on ~/.claude/handoffs/workflow-speed-checks.md and measurements/gates.out.

## Decisions

### Final review
- No round cap. PASS still needs every AC proven (Q1 A). Evidence: rounds 3+ wrote 5 fix tickets, 1 test-only, 2 money bugs (measured).
- After step 1's gate, four lanes start together (Q2):
  - Agents: security finder + behaviour finder.
  - Suites: step 3 full suite (main worktree) + step 3b clean suite (clean worktree).
  - Code runs: step 4 mutate-copy, then step 6b verify, in one new detached worktree at HEAD (mutate-copy edits files in place, so it cannot share the suite's tree).
  - Lead: step 2 wf red, step 4 judging, step 5 wf scope + Out of Scope, step 5b wf size + structure.
  - Join, then: step 6 coverage check/filters/proof, 6c sort, 7 write, 8.
- Lead uses finder results only after its own steps 2-5b (Q3 A). Delta runs use the same lanes, with PREV (Q4 A).
- Proof: no script check; re-run gates.py after 2 features. Target: final-review session average <= 20 min (was 31 for sessions >= 5 min) (Q5 A). Model estimate: saves 5-13 min/session (inferred).

### /build
- On implementer `done`: quality reviewer starts at once; check-red-green.sh runs in the background; ticket reviewer starts when the script reports (needs its output) (Q7 A).
- Script FAIL while quality review runs: wait for both, send script FAIL lines + quality findings in one message; after the fix the quality reviewer re-reviews the fix diff (BASE = reviewed head) even if it said pass (Q6 A).
- If the quality reviewer says fix before the script finishes, the lead waits for the script before messaging the implementer (the script checks out commits in that worktree).
- Same overlap for the next ticket in a chain (Q8 A).
- Ticket reviewer does not re-check quality-only fix diffs (Q17 A). Evidence: 27 fix rounds, all quality-initiated, 0 final-review findings traced to an unseen fix diff (measured).

### Checks
- (a) check-red-green.sh takes the ticket path as a 4th arg; FAIL per Delivers AC with no OK red/guard; `Delivers: none` passes. Blocking from day one (Q9 A, Q14 A).
- (b) mutate-copy per ticket in check-red-green.sh: ticket's changed non-test .py files, `--base <BASE>`, test command = the ticket's own red/guard test files; SURVIVED lines go to the ticket reviewer in the script output; exit 2 prints WARN. Final-review step 4 mutate-copy stays (Q10 A).
- (c) Guard body holds a fenced unified diff under `Mutation:`; script git-applies it at the guard commit, runs the guard's tests, expects FAIL, restores. Update writers: implementer.md, test-only-fix.md, /encode-comments; reader: final-review step 4 (Q11 A).
- (d) `wf done` checks the whole branch: a change to an earlier ticket's red/guard test file, or a test file existing at Base, fails unless the changing ticket has a matching `may change: <path>` line (Q12 A).
- Each check's own test asserts its `Fix:` text.

### Rollout
- b, c, d start as warnings: print, merge continues, no AFK stop. (a) blocks (Q14 A).
- Warnings written to a file in the feature folder; final review marks each real or false alarm with a one-line reason (Q15 A).
- After 3 features, a check with at most 1 false alarm becomes blocking, flipped in one settings file listing each check as warn|block (Q16 A).

## Scope
All in this PR (~9 tickets, guess): lanes (~1), own worktree for mutate-copy/verify (~1), build overlap (~1), checks a+d (~2), checks b+c with writers/reader (~3), warning log + settings file (~1).

## Out of Scope
- Cap on final-review rounds.
- Money-words check on `wf ruling` "quality (logged)" lines (Q13: skipped; 1 case in 32 fix tickets, caught by the behaviour pass).
- A script check that final-review lanes run in parallel (gates.py re-run measures it).
- Ticket reviewer re-checking quality-only fix diffs.
- Removing old prompt lines once a check flips to blocking (done in the flip change).
- Product-repo checks: paid-tool money invariant test, zero-assertion pytest/vitest check.
- Later question: does the ticket reviewer earn its place (0 fix verdicts in 27 rounds, 76 agent-min)?

## Changed in spec review (2026-11-24, owner agreed)
The spec wins where it differs from the lines above.
- Verify (step 6b) runs in the review's own tree after the script lanes finish, not in the mutate-copy worktree (the lanes remove their copies).
- /encode-comments is not a guard patch writer (the red-green check does not read `test(comment)` commits); /direct is.
- The warning log is never committed; review.md's `Check warnings` section is the committed record.
- `wf done` also warns when a red or guard commit removes or rewrites lines in an earlier ticket's test or a test that existed at Base.
