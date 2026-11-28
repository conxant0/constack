# One build command: /direct takes a spec or a one-line task: build index

Spec: docs/work/merge-quick/spec.md
Branch: feature/merge-quick
Base: origin/main
Test command: `f=0; for t in skills/*/scripts/test/*-test.sh test/install-test.sh; do bash "$t" >/dev/null 2>&1 || { f=1; echo "FAIL $t"; }; done; exit $f`

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Part | Title | Blocked by | Status |
|---|---|---|---|
| P1 | Entry check and task gate in wf | none | todo |
| P2 | Citation check moves beside /direct | none | todo |
| P3 | Installer prunes dead links | none | todo |
| P4 | /quick removed, /direct takes a task | P1, P2, P3 | todo |

## Open questions

- Q1: Entry check interface (spec Decisions "Entry rule"). Answer: `wf entry '<raw argument>'`, one argv holding the raw string with literal quotes; SKILL.md step 1 calls it through a quoted heredoc (`WF entry "$(cat <<'ARG'` / `$ARGUMENTS` / `ARG` / `)"`); zero argv, empty, whitespace or `""` is no argument (AC5, exit 1); two or more argv is exit 2 usage; trim, strip one leading `"`, first word runs to whitespace or the closing `"`; order: empty word -> AC5; `[ -f word ]` from cwd -> `spec`; ends `.md` -> AC3; else task, refused (AC4) if any word after the closing quote is exactly `AFK`, or the last word is `AFK` when there is no quote pair; else `task` (fable)
- Q2: Prune prefix (US-4). Answer: `$src/` with the slash, so a sibling checkout such as /repo-2 is not pruned (fable)
- Q3: P2 drops the moved test's /direct step case. Answer: authorised by spec Decisions "Citation check" (hard rule 3 pinned-set exception); drop only "direct step 7 renumbered"; keep "missing skill" retargeted to remove spec/SKILL.md (exit 2); keep the spec cases with citer `$d/direct/SKILL.md`; ruling logged for old and new test paths (fable)
- Q4: Where the US-3.AC1 search test lives. Answer: skills/direct/scripts/test/no-quick-test.sh (P4); finds the root from its own path, searches skills/ plus README.md, CLAUDE.md, install.sh; builds the needle from a split variable (`q=quick`, `"/$q"`) so no file holds the literal; prints each file:line hit and a Fix: line; P1 asserts "not /quick" only via exact-output expect; P2 keeps no quick/ path (fable)

## Parts

- P1: US-1.AC1, US-1.AC2, US-1.AC3, US-1.AC4, US-1.AC5, US-1.AC6, US-2.AC1, US-2.AC2, US-2.AC3, US-2.AC4; files: skills/build/scripts/wf, skills/build/scripts/test/wf-test.sh
- P2: US-3.AC2, US-3.AC3; files: skills/direct/scripts/check-refs, skills/direct/scripts/test/check-refs-test.sh, skills/quick/scripts/check-refs, skills/quick/scripts/test/check-refs-test.sh
- P3: US-4.AC1, US-4.AC2; files: install.sh, test/install-test.sh
- P4: US-3.AC1; files: skills/quick/SKILL.md, skills/direct/SKILL.md, README.md, CLAUDE.md, install.sh, DECISIONS.md, skills/direct/scripts/test/no-quick-test.sh

## Rulings
- 2026-11-28, P1 (direct): skills/build/scripts/test/wf-test.sh may change: the gate --quick cases become --task with the new /direct wording and the bad-mode usage line lists --task, per US-2.AC1-AC4
- 2026-11-28, P2 (direct): skills/direct/scripts/test/check-refs-test.sh may change: moved from skills/quick/scripts/test/; drops the /direct step 7 case, citer is direct/SKILL.md in every expected line, missing-skill case removes spec/SKILL.md, per spec Decisions "Citation check"
- 2026-11-28, P2 (direct): skills/quick/scripts/test/check-refs-test.sh may change: moved to skills/direct/scripts/test/; drops the /direct step 7 case, citer is direct/SKILL.md in every expected line, missing-skill case removes spec/SKILL.md, per spec Decisions "Citation check"
