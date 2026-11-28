# Retro reads the logs first: build index

Spec: docs/work/retro-log/spec.md
Branch: feature/self-improve
Base: origin/main
Test command: `test/run-all.sh ${PYTEST_PYTHON:-python3}`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Part | Title | Blocked by | Status |
|---|---|---|---|
| P1 | retro-log | none | done fd8874be |
| F01 | No-logs check holds when other features have logs | F04 | done 1430936c |
| F02 | Compaction summaries are not typed messages | F01 | done 80d60ca9 |
| F03 | Messages typed mid-turn are typed messages | F02 | done d7e7e9df |
| F04 | Merge origin/main and run the suite with run-all.sh | none | done cdd59ae2 |
| F05 | Repeated errors print by count | none | done a5a377e0 |
| F06 | Messages that start with a paste are typed messages | F05 | done 15120827 |
| F07 | Prompts from script-run sessions are not typed messages | F06 | done 3cb3c6bb |
| F08 | Scheduled wakeups are not typed messages | none | done 5ebd2aa0 |

## Open questions

none

## Parts

- P1: US-1.AC1, US-1.AC2, US-1.AC3; files: skills/retro/scripts/retro-log, skills/retro/scripts/test/retro-log-test.sh, skills/retro/SKILL.md

## Rulings
- 2026-11-28, final-review (fable): suite fails on afk-loop/check-mutation/wf tests, pre-existing at 7ed6b03, fixed on origin/main by PR #10; decided: F04 merges origin/main and sets Test command to test/run-all.sh <absolute python with pytest>; why: the fix already exists on Base, old command stays red after the merge (measured)
- 2026-11-28, final-review (fable): compaction summary listed as typed (behaviour 1); decided: US-1.AC4 as drafted keyed on isCompactSummary, plus Decisions names compaction summaries as harness rows; why: story promise holds, marker is stabler than text
- 2026-11-28, final-review (fable): queued mid-turn messages missing (behaviour 2); decided: US-1.AC5 with human, peer and task-notification queued rows and a typed message after; why: covers all three origins measured and pins time order
- 2026-11-28, F01 quality (logged): retro-log-test.sh:13 check() prints FAIL got/want with no Fix: line (CLAUDE.md check rule); shared helper, needs a follow-up ticket
- 2026-11-28, final-review (fable): paste-led messages dropped from typed messages (behaviour 1); decided: US-1.AC6, print as stored, paste included; why: story promise holds, stripping still drops 27 of 30 real paste-only messages
- 2026-11-28, final-review (fable): afk-loop claude -p prompts listed as typed (behaviour 2); decided: US-1.AC7, entrypoint sdk-cli rows are harness rows; why: story promise holds, origin-based filter would drop 78 real /clear-style rows
- 2026-11-28, F05 quality (logged): retro-log-test.sh check() helper prints no Fix: line (CLAUDE.md rule) -> add Fix: to check() in a ticket allowed to change helpers; lines 86-90 copy setup of 34-39 -> later helper six_repeated <word>
- 2026-11-28, final-review (fable): scheduled /steward and /loop wakeups listed as typed (behaviour 1); decided: US-1.AC8 keyed on turnOrigin scheduled, plus a Decisions sentence; why: story promise holds, missing-origin filter drops real typed rows
- 2026-11-28, final-review (fable): Test command placeholder cannot run in review-lanes; decided: test/run-all.sh ${PYTEST_PYTHON:-python3}, the python set on each run's command line; why: smaller change, keeps the scrubbed path out of the repo
- 2026-11-28, final-review (fable): Out of Scope line 1 vs helper-plain-git on this branch; decided: reword the line, no removal; why: smaller change, the files are another approved spec's reviewed delivery
