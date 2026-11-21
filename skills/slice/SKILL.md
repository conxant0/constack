---
name: slice
description: Cut an approved spec into vertical-slice tickets (docs/work/<feature>/index.md plus tickets/T01-*.md) for /build. Run in a fresh session after /spec.
disable-model-invocation: true
argument-hint: "<path to spec.md>"
---

# /slice

Turn an approved spec into an index plus one file per ticket. Each ticket is a thin, end-to-end slice an implementer can build test-first on its own.

## Hard rules

1. **Vertical only.** Every ticket except a prefactor delivers at least one AC through every layer it needs. Never a "database first" or "all the API" ticket.
2. **The spec is the only source of requirements.** If reading the code raises a question the spec does not answer, do not guess: go to step 3's gap handling.
3. **ACs are copied verbatim**, the whole `- US-n.ACm: ...` line, unchanged.
4. **Tickets that share a resource never run in parallel.** Same file, same table, same route, same config key, or one modifies what the other Consumes: add a blocked-by edge between them.
5. **Fable decides; the user hears only escalations.** A question this skill would put to the user goes through `${CLAUDE_SKILL_DIR}/../build/references/decide.md` (`model: "fable"`). Log each decision as a spec Decisions line ending `(fable, <date>)`.
6. **Decide, don't transcribe.** The implementer builds each ticket from it alone. Give exact signatures, each AC's test with its assertions, and one-line approaches for real choices. Never function bodies, except an algorithm the tests do not pin.

## Steps

1. **Gate.** `$ARGUMENTS` is the spec. Run `${CLAUDE_SKILL_DIR}/../build/scripts/wf gate <spec> --slice` (branch, clean tree, `Status: approved`, `wf check-spec` clean). If it prints anything, show it and stop.
2. **Map the code.** Dispatch one `Explore` subagent (`model: "sonnet"`) with the prompt in `references/code-map.md`, filling in the spec path. Keep only its report.
3. **Spec gaps.** If the map shows the spec cannot be built as written (an AC contradicts the code, a needed decision is missing), send the questions to rule 5, each with the code map's file:line evidence. Write each decision into the spec where the answer belongs (stories and ACs too when it changes behaviour), run `${CLAUDE_SKILL_DIR}/../build/scripts/wf check-spec <spec>` and fix what it prints, commit `docs(spec): fable rulings`, and continue. An escalated question: add `OPEN: <question>` to the spec where the answer belongs, set `Status: draft`, commit `docs(spec): open questions`, and stop. Tell the user to resolve it in the spec, set it approved, and re-run `/slice`.
4. **Slice.** Read `references/slicing.md` and cut the tickets.
5. **Show the slices.** Show the wave count (the most tickets on one blocked-by path), then one table: ticket, title, ACs delivered, files, blocked by, with each edge marked `interface` (it Consumes what the blocker Produces) or `file only` (rule 4). The marks live in this table only; `Blocked by` in the index and tickets stays bare ids, which `wf` parses. Go straight on to step 6; steps 7 to 9 are the table's checks.
6. **Write** `docs/work/<feature>/index.md` from `assets/index-template.md` and each `tickets/T<nn>-<slug>.md` from `assets/ticket-template.md`, following `references/ticket-detail.md`. Copy into every ticket's Constraints the project rules from the map that apply to its files.
7. **Checks.** Run the type-consistency and proportion checks in `references/ticket-detail.md`. Then run `${CLAUDE_SKILL_DIR}/../build/scripts/wf check-plan docs/work/<feature>/index.md` and fix every line it prints until it prints nothing. It checks the index header, ticket ids, blockers and cycles, each ticket's sections, shared files without a blocked-by edge (rule 4), a Tests heading per delivered AC, more than 4 ACs in an unfinished ticket (slicing rule 4), and AC lines MISSING from tickets or DRIFTed from the spec (rule 3).
8. **Test-strength check.** Dispatch one subagent (`general-purpose`, `model: "opus"`) with the prompt in `references/test-strength-check.md`, filling in the spec and tickets paths. Do not pass it the conversation. Check each finding against its AC line: skip one the AC does not require and name it in the hand-off. Fix the rest in the ticket's Tests block (never the spec; a finding that needs a spec change goes to rule 5), then re-run `wf check-plan`. One pass only.
9. **Grounded check.** Dispatch one subagent (`general-purpose`, same model as step 8) with the prompt in `references/grounded-check.md`, filling in the spec, tickets and feature paths and the code map's one-file test command. Unlike step 8 it reads code and runs every Tests snippet. Done when its report has one row per Tests block and ends `clean`; delete any probe file it left. Fix each FINDING in the ticket (never the spec; a finding that needs a spec change goes to rule 5), then re-run `wf check-plan`. One pass only.
10. **Commit** `git add docs/work/<feature> && git commit -m "docs(plan): <feature>"`.
11. **Hand off.** Give the user both options, with `<worktree>` as the absolute path of the current worktree:
   - Manual: `/clear`, then `/build docs/work/<feature>/index.md`.
   - AFK (build, final review and fix rounds, phone push when it stops), in a plain terminal tab: `cd <worktree> && ~/.claude/skills/build/scripts/afk-loop docs/work/<feature>/index.md`
