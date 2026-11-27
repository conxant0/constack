# Build from the spec with parts in the index: build index

Spec: docs/work/direct-parts/spec.md
Branch: feature/direct-parts
Base: origin/main
Test command: `f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Ticket | Title | Blocked by | Status |
|---|---|---|---|
| T01 | direct-parts (direct) | none | done a52f733c |
| F01 | The final gate names a merged part still doing | none | doing |

## Rulings
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: "gate --direct 7 ACs" now expects exit 0 and no output (US-1.AC1 drops the 6-AC limit)
- 2026-11-27, T01 (direct): skills/build/scripts/test/wf-test.sh may change: the --quick over-limit Fix text in "gate --quick 4 ACs" and "gate --quick draft" now names the grilled path (US-1.AC2)
- 2026-11-27, final-review (fable): the orchestrated flow never marks its last part done (skills/direct/SKILL.md:40, :44); reproduced: gate --final prints 'not every ticket is done (run /build)' for a merged part still doing; decided: new AC US-3.AC7 plus fix ticket F01 (final gate names the part with a Fix, step 8 marks it done), commit fc16196; why: an Out of Scope line would leave US-5's so-that false, and the repo rule wants a check, not a prompt line
- 2026-11-27, final-review (fable): structure finding, two readers of a Parts line (check-red-green.sh:26, wf:548); reproduced: trailing-space heading and unknown AC id disagree; decided: declined; why: a refactor no AC needs is declined, both cases need a malformed index and fail loudly
- 2026-11-27, F01 (afk): was doing at session start, interrupted; reset to todo for a fresh implementer

