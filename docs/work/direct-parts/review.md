# Build from the spec with parts in the index, no ticket files: final review

Verdict: PASS
Spec: docs/work/direct-parts/spec.md
Range: origin/main...4e596bba5ad15c30b08c012a1250361d8a62e1bb
Mode: delta since 104a62d85d3504139f98056b291f81d603c6571c
Date: 2026-11-27

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | e98e652 | yes | wf-test "gate --direct 7 ACs": exact exit 0 and empty output; carried from 104a62d |
| US-1.AC2 | 695b248 | yes | wf-test "gate --quick 4 ACs": exact exit 1 and the full line with the grilled-path Fix; carried from 104a62d |
| US-2.AC1 | f9ddd9f | yes | questions-test "no section": exact exit 1 and full Fix line; carried from 104a62d |
| US-2.AC2 | 727d806 | yes | questions-test "unanswered": exact line naming Q1; carried from 104a62d |
| US-2.AC3 | 4a3e63a | yes | guard; Mutation makes `questions` reject "none", a production change the AC forbids; carried from 104a62d |
| US-3.AC1 | 67a1b31 | yes | parts-test "AC in no part": exact line naming US-1.AC2; carried from 104a62d |
| US-3.AC2 | 91b941e | yes | parts-test "AC under two parts": names US-1.AC1, P1 and P2; carried from 104a62d |
| US-3.AC3 | 6b52f39 | yes | parts-test "part with 14 ACs": names P1 and 14; 13 passes; carried from 104a62d |
| US-3.AC4 | 98ffa41 | yes | parts-test "shared file, no path": names src/a.py, P1 and P2; a blocked-by chain passes; carried from 104a62d |
| US-3.AC5 | 5037f46 | yes | guard; Mutation stops `frontier` reading "done <sha>" as done, so P2 is not printed; carried from 104a62d |
| US-3.AC6 | ffb2857 | yes | delivers-part-test: exit 1 and the exact `FAIL delivers US-1.AC2` line, no tickets folder; carried from 104a62d |
| US-4.AC1 | 6e60b76 | yes | lead-test: exact line naming the commit sha and subject; re-judged: test file changed in 104a62d..HEAD, new cases only add checks |
| US-4.AC2 | ed61ce3 | yes | lead-test: 30 + 11 lines outside the plan folder, 50 inside; exact line with 41 and 40; re-judged: test file changed in 104a62d..HEAD, new cases only add checks |
| US-4.AC3 | 63b4c85 | yes | guard; Mutation drops `--first-parent`, so merged helper AC commits are flagged; re-judged: test file changed in 104a62d..HEAD, new cases only add checks |
| US-5.AC1 | 6f5e5cd | yes | afk-loop-test: first recorded session is `/direct <spec> AFK`, no `/build` session; re-judged: test file changed in 104a62d..HEAD, new cases only add checks |
| US-3.AC7 | f950cdd | yes | final-gate-parts-test: exact exit 1 and full line naming P2, its merge sha and the no-ticket Fix; asserts no "/build"; plus the no-merge and tickets-folder cases keep "run /build" (6801d7b) |

`wf red`: no lines.

## Full suite

`f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`: pass

LANE full: PASS start=1795787030 end=1795787155
LANE clean: PASS start=1795787030 end=1795787158 unset=<private env var>,PUBLIC_BASE_URL
LANE wording: PASS start=1795787030 end=1795787030

## Out of Scope

none

`wf scope` lists the 14 files the parts own, as in the previous round (this index has no tickets; same reply at Base). The fix diff 104a62d..HEAD changes `gate --final` in skills/build/scripts/wf and Orchestrated step 8 in skills/direct/SKILL.md. Against "Deleting or editing the ticket skills, the slicing skill or their checks": an index with a tickets folder still gets "not every ticket is done (run /build)" (final-gate-parts-test, last case), and no file under skills/slice or a skills/build prompt changed.

## Structure

`wf size`: none

- skills/build/scripts/check-red-green.sh:26: duplicate `## Parts` reader. declined (previous review; not re-raised).

The fix diff adds no new duplicate: the new gate code reuses `tickets()` and `base_ref()`.

## Security

none

Finder coverage: 9 of 9 files in `git diff --name-only 104a62d...HEAD` covered (wf, skills/direct/SKILL.md, 3 test files, 4 docs). Spot-checked caller: `wf gate <spec> --final` at skills/final-review/SKILL.md:23 and the `gate)` dispatch at skills/build/scripts/wf:640, both present and as reported. The finder ended with NO FINDINGS.

Safe because: the new checks treat index body text, a part id and commit subjects (now including the `merge Pn:` subjects `gate --final` reads) as data and never run them as shell. Proof: previous proof extended with a `doing` part and a commit `merge P1: <injection>` sent through `gate --final`: `bash /private/tmp/claude-501/-<home>-Developer-direct-parts/11d443d8-fd68-4719-9494-9cae1fabbe00/scratchpad/proof.sh` ->
```
questions exit=1
parts exit=0
lead exit=1
red-green P1 exit=1
red-green injected part id exit=2
gate --final exit=1 merged-path=yes
PROOF OK: no index text, part id, commit subject or merge subject was executed
```

## Behaviour

none

### Notes

- skills/build/scripts/wf:367: P2 merged but still doing and P3 todo (an interrupted orchestrated run): `gate --final` prints only the P2 line, whose Fix does not mention P3; after `wf done P2` the gate falls back to "run /build" and `wf frontier` prints P3 (probe /private/tmp/claude-501/-<home>-Developer-direct-parts/behaviour-delta/probe.sh <wf-head> after); money no, common no (needs an interrupted session); neither
- skills/build/scripts/wf:373: a parts index with no tickets folder and a part not done without a merge commit (for example, a solo P1 doing): `gate --final` says "run /build" while afk-loop starts /direct for the same index (probe.sh <wf-head> solo); money no, common no; older
- skills/build/scripts/wf:543: "## Open questions" written as "None", nothing, or without the leading "- " prints "no section"; money no, common no; neither (carried from 104a62d)
- skills/build/scripts/check-red-green.sh:26: "## Parts " with a trailing space passes `wf parts`, fails check-red-green; money no, common no; neither (carried from 104a62d)
- skills/build/scripts/wf:562: a part naming an AC the spec does not have passes `wf parts`; money no, common no; neither (carried from 104a62d)
- skills/build/scripts/wf:407: `wf scope` prints every file a part owns as unplanned; money no, common yes; older (carried from 104a62d)

## Verify

not run: no verify skill

## Check warnings

none

## Fix tickets

none

## OPEN

none
