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
5. **No ticket files before the user approves the slice table** in step 5.
6. **Decide, don't transcribe.** A cheaper model builds each ticket from it alone. Give exact signatures, each AC's test with its assertions, and one-line approaches for real choices. Never function bodies, except an algorithm the tests do not pin.

## Steps

1. **Gate.** Read `$ARGUMENTS` (the spec). Stop unless:
   - it says `Status: approved` and contains no `OPEN:` line
   - `${CLAUDE_SKILL_DIR}/../build/scripts/wf gate <spec>` prints nothing
2. **Map the code.** Dispatch one `Explore` subagent (`model: "sonnet"`) with the prompt in `references/code-map.md`, filling in the spec path. Keep only its report.
3. **Spec gaps.** If the map shows the spec cannot be built as written (an AC contradicts the code, a needed decision is missing), add `OPEN: <question>` to the spec where the answer belongs, set `Status: draft`, commit `docs(spec): open questions`, list the questions with a recommended answer each, and stop. Tell the user to resolve them in the spec, set it approved, and re-run `/slice`.
4. **Slice.** Read `references/slicing.md` and cut the tickets.
5. **Approve.** Show one table: ticket, title, ACs delivered, files, blocked by. Wait for explicit approval; apply edits and show it again.
6. **Write** `docs/work/<feature>/index.md` from `assets/index-template.md` and each `tickets/T<nn>-<slug>.md` from `assets/ticket-template.md`, following `references/ticket-detail.md`. Copy into every ticket's Constraints the project rules from the map that apply to its files.
7. **Checks.** Run the type-consistency and proportion checks in `references/ticket-detail.md`. Then run `${CLAUDE_SKILL_DIR}/../build/scripts/wf check-plan docs/work/<feature>/index.md` and fix every line it prints until it prints nothing. It checks the index header, ticket ids, blockers and cycles, each ticket's sections, shared files without a blocked-by edge (rule 4), a Tests heading per delivered AC, and AC lines MISSING from tickets or DRIFTed from the spec (rule 3).
8. **Commit** `git add docs/work/<feature> && git commit -m "docs(plan): <feature>"`.
9. **Hand off.** Give the user both options, with `<worktree>` as the absolute path of the current worktree:
   - Manual: `/clear`, then `/build docs/work/<feature>/index.md`.
   - AFK (build, final review and fix rounds, phone push when it stops), in a plain terminal tab: `cd <worktree> && ~/.claude/skills/build/scripts/afk-loop docs/work/<feature>/index.md`
