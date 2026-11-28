# Workflow skills: phase 2 decisions (2026-10-17)

## Pipeline and artifacts
All stages run inside one integration worktree, created before the grill:
`git worktree add ../<feature> -b feature/<feature> origin/staging`
`cd ../<feature> && claude --settings '{"worktree":{"baseRef":"head"}}'`
Each stage after spec starts in a fresh session (`/clear`).

| Stage | Command | Reads | Writes (committed on integration branch) |
|---|---|---|---|
| grill | /grill-me (existing) | idea | conversation only |
| spec | /spec (same session as grill) | grill conversation | docs/work/<feature>/spec.md |
| slice | /slice <spec path> | spec.md + code map | index.md + tickets/T01-<slug>.md ... |
| build | /build <index path> | index.md, ticket paths | merged slices, index.md statuses, Rulings |
| final review | /final-review <spec path> | spec.md, index.md, diff | review.md; fix tickets F01-... on failure |

## spec
- Same session as the grill; synthesize, no new interview.
- Sections: Problem, User stories (US-n with US-n.ACm in Given/When/Then), Decisions (no file paths), Out of Scope, Manual check.
- `Status: draft | approved` line; set to approved only on user approval.
- No invention: gaps written as `OPEN: <question>`. Untestable ACs rewritten measurable or marked OPEN. No approval while any OPEN remains.
- Builder check: one fresh subagent reads only spec.md, returns at most 5 questions where a wrong guess changes the build; user answers in one round.
- disable-model-invocation: true; SKILL.md <= ~60 lines; assets/spec-template.md, references/builder-check.md.

## slice (renamed from /plan: Claude Code has a built-in /plan)
- `/slice <spec path>` in a fresh session; refuses if Status != approved or any OPEN.
- No separate plan document: plan = index.md + one file per ticket.
- Slicing rules: prefactor first (no behaviour change); vertical slices each delivering >= 1 AC; infra only inside the first slice that needs it, auth as its own slice; ~100-300 changed lines per ticket; user approves slicing + blocked-by edges before ticket files are written.
- Ticket fields: Delivers (AC IDs + text copied verbatim), Blocked by, Files, Interfaces (exact typed signatures), Tests (per AC: name, file, assertions with spec values), Approach (one line per real choice), Constraints (project rules copied in), Verify (one command), Out of scope.
- Density (adopted 2026-10-17): Pocock's vertical shape, Superpowers' decision density. Bar: every line lets the implementer write exactly one reasonable thing; no bodies except undetermined algorithms; no line ranges. Extra checks: type consistency across tickets, proportion.
- index.md: Branch, Base, one line per ticket (id, title, blocked-by, status), Rulings section. Status: todo | doing | done <sha> | blocked: <reason>.
- Final check: every AC ID in spec appears in >= 1 ticket with matching text.
- Spec gap found while reading code: write OPEN to spec.md, set Status: draft, stop.
- Tickets listing the same file get a blocked-by edge.
- One Explore subagent maps code (paths + signatures only).
- disable-model-invocation: true; SKILL.md <= ~80 lines; assets/ticket-template.md, assets/index-template.md, references/slicing.md (rules + one horizontal-to-vertical worked example).

## build
- `/build <index path>` in a fresh session. Refuses unless current branch == index Branch and tree is clean.
- Setup check: required allow rules (git, project test command, skill script) present in .claude/settings.json; if missing, print exact lines and stop.
- Frontier: dispatch every todo ticket whose blockers are done, in parallel, max 3, with isolation: "worktree".
- Implementer (Sonnet, model passed explicitly): input = ticket path + integration SHA. Per AC: failing test -> run, confirm fail -> commit `test(US-n.ACm): red` -> minimal code -> commit green. Refactor when all green, run Verify. Max 3 attempts per AC; frozen tests; maxTurns as backstop. "One test per acceptance criterion is required; this overrides any instruction to minimise tests."
- Report (<= 10 lines): STATUS, TICKET, BRANCH, COMMITS, VERIFY, BLOCKER (split | clarify | ask-user + one sentence).
- Blocked: clarify -> answer from spec or ask user; split -> propose to user; ask-user -> ask. Log every ruling in index.md. Resume same implementer via SendMessage.
- scripts/check-red-green.sh <base> <branch> "<verify>": fail expected at each red commit, pass at HEAD, no test file changes after its red commit (except later red commits); prints failure line per AC. Run by lead before review; failure goes back to implementer.
- Reviewer (Opus, model passed explicitly): input = ticket path + diff range, never the implementer report. Checks: no existing test edited/deleted, no skip/xfail/hardcoding; diff inside Files + out-of-scope; Missing / Extra / Misunderstood vs ACs; reads failure lines from the script. Flags only correctness and stated requirements. Fixes go back to the same implementer; re-review scoped to the fix diff; max 2 rounds then escalate to user.
- After pass: merge --no-ff into integration branch, re-run Verify there, mark done <sha>, commit index.md, remove the worktree. Merge conflict or failing post-merge Verify: revert, mark blocked. Lead never fixes code.
- disable-model-invocation: true; SKILL.md <= ~80 lines; references/implementer.md, references/reviewer.md, scripts/check-red-green.sh.
- Gap fixes (2026-10-17): /slice adds blocked-by edges for any shared resource (file, table, route, config key, consumed interface), not only shared files. /build runs the full suite (index Test command) after every merge instead of the ticket's Verify; failure resets the merge and blocks the ticket.
- Added in build (2026-10-17): report carries WORKTREE (pwd) for the script; setup requires `.worktreeinclude` for ignored files tests need (verified in Claude Code 2.1.301 binary); implementer checks HEAD == BASE first; test changes in fix rounds only when a finding says the test is wrong, as `test(US-n.ACm): fix per review`; fix-round script runs scoped to BASE = last reviewed head. Script probed on 4 fixtures (good, fake red, weakened test, failing HEAD): all correct.

## final-review
- `/final-review <spec path>` in a fresh session inside the worktree.
- 1. Each US-n.ACm has a red commit: `git log origin/<base>..HEAD --grep`.
- 2. One full test-suite run at HEAD.
- 3. Judgment: does each AC's test actually test what the AC says?
- 4. Out of Scope check against the diff.
- 5. Security pass on origin/<base>...HEAD (base from index.md) with Anthropic's claude-code-security-review prompt copied into references/security.md. Verify the prompt against a known vulnerable diff in phase 3.
- No /code-review inside it (per-ticket Opus reviewers cover correctness; user may type /code-review on large branches).
- Writes review.md. On failure: each finding becomes a fix ticket F01-... appended to index.md as todo; untestable findings go to review.md as OPEN for the user. Then /build, then /final-review again. Done only when review.md passes.
- disable-model-invocation: true; SKILL.md <= ~60 lines; references/security.md.
- Built (2026-10-17): security.md adapts anthropics/claude-code-security-review .claude/commands/security-review.md (commit c19afa74097b, MIT, license copied as references/security-LICENSE): finder subagent, parallel false-positive filter subagents, keep confidence >= 8, base = index Base. Security fix = new AC added to the spec (with approval) + F-ticket, so /build needs no change. Probes: finder caught a planted f-string SQL injection (0.95) and returned NO FINDINGS on the parameterized version; step 2 grep loop flagged exactly the missing AC. Filter step not probed separately.

## Ponytail
Leave on. Its SubagentStart hook injects into every subagent (~3 KB each). Skills do not depend on it. Scope with PONYTAIL_SUBAGENT_MATCHER if cost matters.

## Guard ACs and Sonnet ticket reviewers (2026-10-27)
- An AC already true before its code (size guard, regression guard, shared code an earlier green covered) commits `test(US-n.ACm): guard` with a `Mutation:` line in the body, no green. check-red-green.sh requires it to pass and to name a mutation; wf red accepts it. /slice marks expected ones `(guard)` on the Tests heading; unplanned ones are allowed and the reviewer checks them. Why: one feature logged 7 pass-on-arrival rulings and one final-review FAIL (US-4.AC1/AC2) from this alone.
- Per-ticket reviewers run on Sonnet as a trial; /final-review and its security finder stay on Opus. Why: Opus was ~75% of that feature's $15.45. Count escaped bugs on features built after this date before keeping it.

## Delta final review (2026-10-28)
- A /final-review re-run after a FAIL re-judges only fix work since the last review's HEAD (PREV): ACs with a new red/guard commit, a touched test file, or a touched ticket file; the security finder diffs PREV...HEAD and checks callers of changed functions. Red commits, full suite and scope still run on the whole branch. Other AC rows carry over; `Mode:` line in review.md records which.
- Why: the old re-run repeated the Opus AC check and security pass on unchanged code. Both late-round finds checked (F03 on two earlier features) sat in the AC or story the previous fix had touched, so delta would have caught them. Lost: the "second fresh look" at untouched code. Count bugs escaping delta runs over the next 3 features before keeping it.

## Structure step (2026-10-28)
- /final-review step 5b: advisory structure pass (wf size: file crosses 1000 lines or grows 100+ while over; duplicate helper; wrong layer; feature branch in a shared flow). Max 5 findings under ## Structure in review.md; never a fix ticket or FAIL. Taken from Cursor's thermo-nuclear-code-quality-review, minus its "restructure the codebase" ambition (conflicts with Out of Scope). Review after 3 features: switch to blocking if findings were real, delete if noise.

## Decisions get an AC example (2026-10-29)
- /spec step 3: every Decision line stating observable behaviour (refusal, default, error, meaning of an empty result) gets at least one AC example, or OPEN. Builder check also asks for Decision lines no AC shows.
- Why: ai-search-mcp's escaped bug (PR #339, a custom org_type that reaches no tier returned 0, reading as "none exist") broke spec Decision line 69, which had no AC, so no ticket, reviewer or /final-review checked it. Same idea as Specification by Example's "rules with no examples" check. Example per rule, not the rule restated, to avoid stating it twice.
- Review after 3 specs: count ACs added this way and whether any escape still came from a Decision line.

## Trial tallies
- Sonnet ticket reviewers, 2026-10-29: 3b, ai-search-mcp. 0 escapes blamed on the reviewer; 1 spec-gap escape (PR #339).
- Delta final review, 2026-10-29: 1/3 features (ai-search-mcp). 0 escapes.
- /unblock (2026-10-29): afk-loop stops on a blocked ticket and prints a paste command that opens claude on `/unblock <index>`. It re-checks the AFK pick against the code (the T18 pick would have changed app behaviour and a deliberate test), asks one ticket at a time, and writes the ruling into the ticket file, because implementers never read the index.
## Quality reviewer per ticket (2026-11-09)
- /build step 4 runs a second Sonnet reviewer beside the ticket reviewer, prompt in build/references/quality-reviewer.md. It blocks on 3 things: a test that cannot fail, ticket-stated behaviour no test would miss, and production logic duplicated from the repo. Rule breaks, structure and duplicated test helpers are logged with `wf ruling`, never blocking. Fresh agent per ticket, also inside chains.
- Why: an audit of one repo's tests found always-pass tests that came in through red and guard commits and passed both the Sonnet ticket reviewer and the Opus final review. reviewer.md checks the diff against the ticket and says "no style", so nothing asked for test strength. A guard's `Mutation:` line is prose nothing runs (a9ed077f7 mutated its own golden JSON and passed).
- Replay experiment, 12 past tickets (4 always-pass tests, 4 duplicates from step 5b, 4 clean), blind prompts, $18.87 of subagents (prices guessed, tokens measured):
  - Executed mutation per AC (Sonnet, $0.59, 118s per ticket): 0/4 always-pass tests, 0/4 duplicates. It mutates what each AC says, so a vacuous test sharing a commit or AC with a good one is never looked at (c01, c09, c03). It did find 2 weak assertions the reviewer missed. Not adopted.
  - Quality reviewer, Sonnet ($0.51, 52s): 3/4 always-pass tests, 3/4 duplicates plus 1 partial. Raised findings on 3 of 4 clean tickets; 6 sampled, 5 true as stated, 1 overstated (checked against the code).
  - Same prompt on Opus (3 tickets, $1.88): nothing Sonnet missed.
  - Missed by every arm: a test that compared a result with the test's own dict.
- BLOCK/LOG split proposed by Claude from the 6 sampled findings, approved by the user (2026-11-09): duplicated rule, untested tie-break, golden test proving only a fixture, charge test without quote assertions -> block; duplicated test helpers -> log.
- Review after 3 features: count BLOCK findings fixed vs judged noise, fix rounds added per ticket and their cost, and any always-pass test that still reaches /final-review. Drop to LOG-only if more than a third of BLOCK findings are noise.

## build/SKILL.md trimmed (2026-11-13)
- Serial mode and AFK mode moved to build/references/serial.md and afk.md, read only when that mode is on. Reasons moved out of the skill into this file. 1,827 words to ~1,150. No behaviour change intended.
- Reasons that used to sit inline: the frontend suite is skipped on backend-only merges because it costs ~166s and only showed flaky failures (measured 2026-10-29). AFK's 3-merge context budget: resumed implementers reached 123-125k tokens after 2 tickets and 139-144k after 3; build leads stayed at 58-99k with 3 merges (measured 2026-10-28). Opus defaults: see the 2026-11-11 section.

## Fewer questions to the user (2026-11-13)
- Every user ruling (build rule 6, /unblock, /final-review) ends `pick: <recommendation>; chose: <answer or "pick">`. Why: 52 user rulings across 22 features, 0 recorded whether the recommendation was taken, so no category could be automated on evidence.
- Build rule 8 widened: the lead rules on updating an existing test that pins a count, set, list or contract the ACs change (no assertion removed or loosened), and on env fixes in Verify (python to python3). It writes `Ruling <date> (lead): <test> may change: <what>` into the ticket's Approach; reviewer.md and implementer.md accept exactly that change. Raising a size limit (a `*_CHARS_MAX` constant) stays the user's: it is a budget, and auto-raising it ratchets. Why: ~12 of 52 user rulings were this kind (keyword count, rough).
- /final-review (not AFK) writes AC, removal and clean-checkout fix tickets without asking; the user is asked only new AC wording and build-or-decline per structure ticket.
- Not done: AFK proceeding on its pick. Risks: later tickets build on a wrong pick; the model judging "low risk" is the one that picked wrong (T18); a long veto list gets rubber-stamped. Revisit after 3 features of pick/chose data: automate only categories where chose == pick every time.

## PR review comments fed back (2026-11-16)
- Read all 41 reviewer comments on the last 25 merged PRs. Repeat causes: copy that contradicts the code (7+), the no-signal rule reversed (#391, #407, #406), stale branch vs staging, owed items.
- quality-reviewer.md gains BLOCK check 4: copy that says something the code does not do (LOG renumbered to 5).
- /pr fills "Security review" from review.md's Security section and Range instead of writing pending; it says "not covered" only when source changed after the range.
- The product repo's own rules files gained 6 tool-text rules and utf-8 reads.
- Review after 3 PRs: count reviewer comments in these categories.

## Behaviour pass in /final-review (2026-11-19)
- Read 67 reviewer comments on 34 PRs. Four heads the reviewer asked changes on had passed /final-review at that sha (#424 7ffe43566 and 175fc6bf7, #426 d057c652e, #407 5361744b9). The blocking findings were states no AC listed: a step that ran and found nothing, finished but not marked, a reopened chat, a charge then an error.
- /final-review step 6c (new, references/behaviour.md): one blind subagent lists the states the diff branches on and must reproduce each bug with a probe; at most 5; each fails the verdict and becomes a new AC plus F ticket, the security route. Reverses "No /code-review inside it" (2026-10-17) for reproduced bugs only.
- Not added, on purpose (80/20): a staging merge check, a removed-test ledger and a CHANGELOG check already run in /pr through the repo's pre-push script; copy vs code is quality-reviewer BLOCK check 4 (2026-11-16). Their effect is not measured yet.
- Not tested: a whole run with 6c. Replay on #426 at d057c652e and score against the reviewer's 2026-11-12 list (8 items) and count extra findings as noise.
- Review after 3 features: 6c findings fixed vs noise, minutes added, reviewer comments still in the four categories above.

## /pstack:no-comments before /final-review (2026-11-20)
- /build Finish, /direct step 7 and global CLAUDE.md step 5 hand off `/pstack:no-comments diff against <Base>` before `/final-review`. Plugin: `pstack@cursor-plugins` (Lauren Tan, v0.15.46, user scope, no hooks; every skill but setup-pstack is manual-only).
- Why after the build: per-ticket runs in parallel worktrees would collide at merge. Why before the final review: it edits code (deletes workarounds, may add a type, test or lint), and /final-review reruns the suite and security pass on that.
- Base is named because the skill and its comment-sicko agent default to `main`, which lags `staging`.
- AFK unchanged: encoding a constraint waits for interactive approval, so afk-loop does not run it.
- Watch: comment-sicko keeps only 5 exception kinds (license, foreign-dependency gotcha, prettier-ignore or pedantic lint suppression, public API doc, issue/RFC link). Our-code "why" comments die. Not tested: no run yet. Backup: `~/.claude/backups/skills-2026-11-20-pre-no-comments`.

## /encode-comments wraps no-comments (2026-11-20)
- Replaces the raw `/pstack:no-comments` hand-off. New user skill `~/.claude/skills/encode-comments`: reads pstack's no-comments SKILL.md from the plugin cache (a user-invoked skill cannot fire another) and overrides it: any comment stating a rule becomes a red-proven test or lint rule before deletion, whatever its wording; trivial flags only, the rest reported; one suite run. Global CLAUDE.md Code rules gained "Enforce with a check".
- Why (measured 2026-11-20, read-only dry run on one PR): Comment Sicko killed 24 of 34 added comments and raised 19 MUST KILL flags. Raw no-comments would attempt all 19 refactors before /final-review, and its step 5 offers encodings only for "do not remove" wording, so two rules stated in comments and one lint-suppression reason would be deleted with no test.
- A rule no in-scope check can hold is deleted (the user's pick 2026-11-20, pstack's default) and recorded in an empty `chore(comments): unenforced rules` commit body, so it outlives the session.
- Order: Sicko's deletions are committed before encoding, so the red-proof `git checkout -- <file>` reverts only the deliberate break. Tests must run under the project's test command.
- /final-review: new test files show up in `wf scope` (step 5) as unplanned files to read; they fail only if an Out of Scope line excludes them. afk-loop runs `/encode-comments <Base> AFK` between /build AFK and /final-review AFK every round (fix tickets add comments too); Base is the first word of the index's `Base:` line; uncommitted changes after it stop the loop with a notification.
- Not tested: no run yet.
- Path mode (2026-11-20): `/encode-comments <paths...>` scopes to every comment in those files, for one-off cleanups of merged code (first target: one backend package, 158 comments + 2 suppressions measured). Base is HEAD at start; it ends with a PR plus /security-review, since no /final-review follows.

## Three prose rules became checks (2026-11-21)
- /build rule 3 (model on every dispatch): `build/scripts/require-model.sh`, a PreToolUse hook on Agent registered in build/SKILL.md frontmatter, so it runs only in a session that invoked /build (until /clear). Why: settings env CLAUDE_CODE_SUBAGENT_MODEL=sonnet ran any dispatch without a model on Sonnet, silently. Probed headless with a test skill carrying the same hook: the no-model call was blocked, the haiku call ran.
- Red and guard commits touch test files only (reviewer.md:18): check-red-green.sh FAILs one that touches a non-test path (`test_re`: test dirs, fixtures, test_*.py, *_test.py, conftest.py, *.test/spec.js/ts). check-red-green-test.sh gained two FAIL cases; its "touches code runs all" case now uses a frontend test file. Red first, then green.
- AFK never asks (afk.md): afk-loop passes `--disallowedTools ... AskUserQuestion`. afk-loop-test.sh logs the fake claude's args and asserts it, plus /encode-comments <Base> AFK before each /final-review.


## Final review grades each test yes or no, on proof (2026-11-27)
- `partly` is gone and no AC row can be waived. A `no` row's Note is `Mutation: <patch beside the review>; <test command>`; `wf check-review` holds that shape, and the new `build/scripts/check-mutation` applies each patch in place, re-runs the command and puts the tree back. A patch the tests catch is not a `no`.
- Why (measured 2026-11-27, 32 features in the product repo): 46 of 104 fix tickets were test-only gaps from AC rows, and the owner waived 20 rows by hand, 8 of them "a sentence in the step text has no assert" on one feature.
- Logic only: under an unqualified "show a break the tests miss" rule those 8 would all have become forced fix tickets. A patch whose Python files match once every string is blanked is wording, which mutate-copy already judges, and check-mutation rejects it.
- Limits: the wording comparison is Python only (other files count as logic); a `yes` is not checked.
- Review after 3 features: count `no` rows, patches the script rejected, and fix tickets written.

## /direct builds any size from parts in the index (2026-11-27)
- /direct takes a spec of any size and writes no ticket files. The index gains `## Open questions` (each answered by the decide.md Fable subagent before any code, the answer on the question's line) and `## Parts` (one line per table row: its ACs, at most 13, and the files it owns). At most 6 ACs: one session, one part, as before. More: the session orchestrates helpers per runnable part in their own worktrees, merges with `git merge --no-ff`, writes no AC code, then one quality review (quality-reviewer.md plus the implicit-state-machine row the ticket reviewer held) on the whole change.
- Why (measured 2026-11-27, independent scorers on 4 replays of 3 past features): planning docs 1,913 lines with tickets vs 56 without; every AC met; tests about as strong. Of 6 bugs only the replays had, 5 came from a spec point the original run stopped to settle and the replay decided alone, hence Open questions first. In a parallel replay a lead with 2 helpers and a 25-line split list matched the ticketed build's time (37 vs 36 min commit span; the ticketed build ran its 5 tickets one after another), 0 merge conflicts, quality reviewer 0 blocks in 2 min.
- Checks: `wf gate --direct` drops the 6-AC limit; `wf questions`, `wf parts` (every AC in exactly one part, at most 13 per part, a file shared by two parts needs a blocked-by path) and `wf lead` (first-parent, non-merge commits in Base..HEAD: no `<type>(US-n.ACm)` subject, at most 40 changed lines outside the plan folder). `check-red-green.sh <wt> <base> "<verify>" <index.md>:<part>` reads the part's ACs for its delivers line. afk-loop runs `/direct <spec> AFK` for an index with `## Parts` and no `tickets/` folder.
- Owner defaults: lead limit 40 lines, part limit 13 ACs (the largest part a helper built in the replays), solo limit 6 ACs.
- /slice, /build and their checks stay on disk unchanged as the fallback. Review after 2 real features through /direct, then delete the ticket path.

## Orchestrated /direct against slice + build: two replays (2026-11-28)
- Method: two features already built with tickets (feature A, 24 ACs; feature B, 30 ACs) were wound back to before any code in a standalone clone and rebuilt unattended with this branch's /direct from the same spec. The ticket side is the original build, its cost and active minutes read from the saved session logs up to its first final review. Both sides then got one fresh /final-review under the 2026-11-27 grading. One price table for both sides; active minutes are gaps of at most 15 minutes between log lines.
- Build only, 54 ACs (measured): /direct $88.78 ($1.64 per AC) and 361 min (6.7 per AC); tickets $100.24 ($1.86 per AC) and 354 min (6.6 per AC). Per feature: feature A $32.81 and 121 min vs $44.58 and 200 min; feature B $55.97 and 240 min vs $55.66 and 154 min.
- Code repairs from the review (measured): /direct 1 + 2, tickets 1 + 1. One repair per feature was the same spec gap on both sides. Test-only fix tickets: /direct 2 + 0, tickets 1 + 1; the ticket side of feature B also got one ticket restoring 104 Base comment lines /encode-comments stripped.
- Planning text (measured): /direct 56 and 85 index lines; tickets plus index 1,163 and 1,575 lines.
- Runs (measured): 3 and 4 /direct sessions, 7 and 11 parts, 0 lead AC commits, no block, no read of the original build.
- Pass rules set before the runs, from the 32-feature ticket baseline: (1) code repairs at most 1 per 20 ACs pooled; (2) owner stops at most 1 per feature; (3) build time at most 5.0 active min per AC pooled; (4) build cost at most $1.16 per AC pooled; (5) planning text at most 5 lines per AC and 0 manual-check bugs from an unasked spec question. Result: 1 missed by one ticket (1 per 18; tickets 1 per 27), 3 and 4 missed by both sides, 5 passed on lines. Rules 3 and 4 are too tight for features of 24 to 30 ACs (inferred, since the ticket side misses them too).
- Read: a tie on cost, time and repairs; /direct wins on planning text. A one-ticket gap from one review per side is noise.
- Not measured: owner stops (unattended runs), the Manual check, and Verify on the feature A /direct side (the verify skill refused a clone with a `.env` at its root).
- Found in the runs: check-red-green.sh FAILed a commit that a "may change" ruling allows, and a piped verify command made it pass always; both fixed 2026-11-28 (it reads the ruling line for that exact file from the ticket's Approach or the index's Rulings, and runs every command with pipefail). A stale `.pyc` gave a false FAIL about 1 time in 3; the check now exports PYTHONDONTWRITEBYTECODE=1 itself (fixed 2026-11-28; the race was not reproduced on purpose, so the fix is by cause). Not fixed: one helper died and its worktree commits had to be recovered by the lead.
- Unchanged: /slice and /build stay as the fallback until 2 real features pass through /direct. Logs and the scoring script: `~/.claude/afk-logs/direct-vs-tickets/`.

## Verify skill can live outside the repo (2026-11-28)
- /final-review step 6b looks for the verify skill in order: the repo's own `.claude/skills/verify/SKILL.md` (wins, unchanged); else the file named by `git config --get constack.verify`, if it exists; else `not run: no verify skill`, verdict unaffected. The own-check flag on `.claude/skills/verify/` in the branch diff is unchanged.
- Why: a product's verify skill moved into a private overlay so the workflow tooling owns the boot and drive scripts; the product repo keeps only the list of tools its checks may call, beside the test that keeps that list complete. A skill found globally would run in every repo and its `not run` row would block PASS there, so the lookup is gated per repo by the config key, which the overlay's installer sets.
- A skill read by path does not get `${CLAUDE_SKILL_DIR}` filled in, so 6b says to read it as the folder holding that SKILL.md.
