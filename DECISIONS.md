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
- An AC already true before its code (size guard, regression guard, shared code an earlier green covered) commits `test(US-n.ACm): guard` with a `Mutation:` line in the body, no green. check-red-green.sh requires it to pass and to name a mutation; wf red accepts it. /slice marks expected ones `(guard)` on the Tests heading; unplanned ones are allowed and the reviewer checks them. Why: mcp-filters-3 logged 7 pass-on-arrival rulings and one final-review FAIL (US-4.AC1/AC2) from this alone.
- Per-ticket reviewers run on Sonnet as a trial; /final-review and its security finder stay on Opus. Why: Opus was ~75% of mcp-filters-3's $15.45. Count escaped bugs on features built after this date before keeping it.

## Delta final review (2026-10-28)
- A /final-review re-run after a FAIL re-judges only fix work since the last review's HEAD (PREV): ACs with a new red/guard commit, a touched test file, or a touched ticket file; the security finder diffs PREV...HEAD and checks callers of changed functions. Red commits, full suite and scope still run on the whole branch. Other AC rows carry over; `Mode:` line in review.md records which.
- Why: the old re-run repeated the Opus AC check and security pass on unchanged code. Both late-round finds checked (mcp-filters-1 F03, mcp-lists F03) sat in the AC or story the previous fix had touched, so delta would have caught them. Lost: the "second fresh look" at untouched code. Count bugs escaping delta runs over the next 3 features before keeping it.

## Structure step (2026-10-28)
- /final-review step 5b: advisory structure pass (wf size: file crosses 1000 lines or grows 100+ while over; duplicate helper; wrong layer; feature branch in a shared flow). Max 5 findings under ## Structure in review.md; never a fix ticket or FAIL. Taken from Cursor's thermo-nuclear-code-quality-review, minus its "restructure the codebase" ambition (conflicts with Out of Scope). Review after 3 features: switch to blocking if findings were real, delete if noise.
