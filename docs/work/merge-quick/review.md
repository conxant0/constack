# One build command: /direct takes a spec or a one-line task: final review

Verdict: PASS
Spec: docs/work/merge-quick/spec.md
Range: origin/main...9e49a4b5c69c1c182b8b356e592beb34b211fd6e
Mode: full
Date: 2026-11-28

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | 578d962 | yes | `entry: existing spec` expects exit 0 and exactly `spec` |
| US-1.AC2 | a772453 | yes | cwd holds no file named fix; expects exit 0 and exactly `task` |
| US-1.AC3 | c122435 | yes | expects exit 1 and the exact line naming `docs/x/nope.md` with the Fix |
| US-1.AC4 | 02a61ad, guard 1d5943a | yes | quoted task + AFK, task + slug + AFK, unquoted ending AFK all exit 1 with the exact Fix; the guard's Mutation patch (keep every word, not the last) fails `entry: unquoted AFK not last` |
| US-1.AC5 | cd795f9 | yes | no argv, empty, whitespace and `""` each exit 1 with the exact Fix |
| US-1.AC6 | guard 1fb4f52 | yes | true since the P1 entry check landed (earlier AC greens in the same part); the Mutation patch (spec branch refuses a last word AFK) fails `entry: spec then AFK` |
| US-2.AC1 | caf089a | yes | exact line: `4 ACs, a one-line task takes at most 3 for /direct` plus the grilled-path Fix; no `/quick` |
| US-2.AC2 | guard 7acb799 | yes | true since the `--task` rename in P1 (US-2.AC1 green); the Mutation patch (cap 3 to 2) fails `gate --task 3 ACs` |
| US-2.AC3 | 808f205 | yes | 3-AC draft expects exit 1 and exactly the draft line naming `/direct` with its Fix |
| US-2.AC4 | 5964455 | yes | `--quick` expects exit 2 and the usage line listing `--task`, not `--quick` |
| US-3.AC1 | 5f9a622 | yes | no-quick-test greps skills/, README.md, CLAUDE.md, install.sh for `/quick` and fails on a `skills/quick` folder |
| US-3.AC2 | guard e9d71e6 | yes | `real skills` expects exit 0 and empty output; Mutation patch (wrong lead for rule 4) fails it |
| US-3.AC3 | ca4d647, guard ac6a78b | yes | `spec rule 3 replaced` expects exit 1, the item, `direct/SKILL.md` as citer and the Fix |
| US-4.AC1 | 04a6452 | yes | dangling in-checkout links in skills/ and hooks/ are gone, one `pruned <link>` each, exit 0 |
| US-1.AC7 | d542ab3 | yes | quoted task starting with an existing file, starting with a missing `.md`, and with a space after the opening quote each expect exit 0 and exactly `task`; dropping the quote rule (`[ -z "$q" ]`) or the post-quote trim fails one of them |
| US-4.AC2 | guard cb2e55f | yes | outside, relative and real folder stay, no `pruned` line; Mutation patch (prune any dangling link) fails `keep: outside link removed` |

Rows other than US-1.AC7 re-read at HEAD: since the last review (433ff82) only `entry()` in wf and wf-test.sh changed (`git diff 433ff82 HEAD -- skills install.sh test`); the AC1-AC6 tests still exercise the same exits (unquoted spec, quoted task, missing `.md`, task + AFK, no argument, spec + AFK).

Copy: `LANE wording: PASS` (no Python files changed). `wf red`: no lines.

## Full suite

Test command from the index (all suites under `skills/*/scripts/test/` and `test/install-test.sh`).

Run plainly, `review-lanes docs/work/merge-quick/index.md origin/main`:

```
LANE full: FAIL start=1795856512 end=1795856533
  FAIL skills/build/scripts/test/afk-loop-test.sh
  FAIL skills/build/scripts/test/check-mutation-test.sh
  FAIL skills/build/scripts/test/wf-test.sh
LANE clean: FAIL start=1795856512 end=1795856533 unset=<vendor token>,PUBLIC_BASE_URL
  FAIL skills/build/scripts/test/afk-loop-test.sh
  FAIL skills/build/scripts/test/check-mutation-test.sh
  FAIL skills/build/scripts/test/wf-test.sh
LANE wording: PASS start=1795856512 end=1795856512
```

Re-run with a BSD-sed shim first on PATH and GIT_AUTHOR_NAME/EMAIL plus GIT_COMMITTER_NAME/EMAIL exported (the lane result of record per the earlier ruling; spec Out of Scope covers the GNU sed / git identity fixture failures, same at origin/main):

```
LANE full: PASS start=1795856533 end=1795856558
LANE clean: PASS start=1795856533 end=1795856558 unset=<vendor token>,PUBLIC_BASE_URL
LANE wording: PASS start=1795856533 end=1795856533
```

## Out of Scope

none. `wf scope` lists the 14 changed source/doc files as unplanned because /direct writes no ticket files; each is named in a Parts `files:` line in the index except TODOS.md, which the earlier final-review ruling added with its Out of Scope line. The AC7 change touches only `entry()` (wf:591-596) and wf-test.sh. Each Out of Scope line checked: cap stays 3; no `/quick` stub or `--quick` alias; prune only absolute in-checkout targets directly in skills/ and hooks/ (install.sh:24-25); no skillshare code; `/spec`, `/slice`, `/build` and `/direct`'s Orchestrated section unchanged.

## Structure

`wf size`: none
none

## Security

none. Finder: NO FINDINGS. Coverage: all 17 files in `git diff --stat origin/main...HEAD` (install.sh, wf, direct/SKILL.md, direct/check-refs and the deleted quick files as source; the 4 tests and docs read; index.md and review.md skipped as bookkeeping). Spot-checked callers: `skills/direct/SKILL.md:24` passes `$ARGUMENTS` to `WF entry` through a quoted heredoc (`<<'ARG'`); `skills/build/scripts/afk-loop:70` sends `/direct $spec AFK`, both as the report says.

Safe because: install.sh's prune removes only a dangling link directly inside `~/.claude/skills` or `~/.claude/hooks` whose stored target is absolute and starts with `<checkout>/`, so it never deletes a real file, a live link, a sibling checkout's link or a nested entry. Proof: `bash /tmp/claude-1000/-home-lumbab-Developer-merge-quick/9196956b-e2b8-44bc-ac9d-bdcd46b6c955/scratchpad/prune-proof.sh /home/lumbab/Developer/merge-quick` (runs the real install.sh with HOME set to a temp dir) ->

```
rc=0
pruned /tmp/tmp.smIsXhityy/.claude/skills/dead-in
pruned /tmp/tmp.smIsXhityy/.claude/hooks/dead-hook
gone    skills/dead-in
gone    hooks/dead-hook
present skills/sibling
present skills/relative
present skills/nest/deep
present skills/live
present skills/real/keep.txt
target README.md intact
```

## Behaviour

none

### Notes

- skills/build/scripts/wf:595: `/direct ~/Developer/.../spec.md` (`~` path, not expanded through the quoted heredoc) is refused as `is not a file` although it exists; neither
- skills/build/scripts/wf:592: `/direct 'notes.md is stale'` (single-quoted task, only `"` counts as a quote) is refused as `'notes.md is not a file` with a Fix to quote it; neither
- skills/direct/SKILL.md:31: re-running `/direct "<task>" <slug>` after the approval prints `task` and rewrites the spec and asks again, never reaching step 2's resume; older
- (dropped: `/direct README.md has a typo`, unquoted task starting with an existing file, prints `spec`: the spec's Decisions "Entry rule" chose "unquoted, an existing file means spec")

## Verify

not run: no verify skill

## Check warnings

none

## Fix tickets

none

## OPEN

none
