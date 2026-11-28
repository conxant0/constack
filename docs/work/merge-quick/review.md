# One build command: /direct takes a spec or a one-line task: final review

Verdict: PASS
Spec: docs/work/merge-quick/spec.md
Range: origin/main...433ff8266f9bf33a18f8e4caa388df4525a5331b
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
| US-4.AC2 | guard cb2e55f | yes | outside, relative and real folder stay, no `pruned` line; Mutation patch (prune any dangling link) fails `keep: outside link removed` |

Copy: `LANE wording: PASS` (no Python files changed). `wf red`: no lines.

## Full suite

Test command from the index (all suites under `skills/*/scripts/test/` and `test/install-test.sh`).

Run plainly, `review-lanes docs/work/merge-quick/index.md origin/main`:

```
LANE full: FAIL start=1795854591 end=1795854615
  FAIL skills/build/scripts/test/afk-loop-test.sh
  FAIL skills/build/scripts/test/check-mutation-test.sh
  FAIL skills/build/scripts/test/wf-test.sh
LANE clean: FAIL start=1795854591 end=1795854615 unset=<vendor token>,PUBLIC_BASE_URL
  FAIL skills/build/scripts/test/afk-loop-test.sh
  FAIL skills/build/scripts/test/check-mutation-test.sh
  FAIL skills/build/scripts/test/wf-test.sh
LANE wording: PASS start=1795854591 end=1795854591
```

The same three suites fail at origin/main in a detached worktree run plainly; every other suite passes there. Cause (index Rulings): fixtures use BSD `sed -i ''` (GNU sed 4.9 on this PC) and afk-loop-test's temp repos have no git identity.

Re-run with a BSD-sed shim first on PATH and GIT_AUTHOR_NAME/EMAIL plus GIT_COMMITTER_NAME/EMAIL exported:

```
LANE full: PASS start=1795855056 end=1795855081
LANE clean: PASS start=1795855056 end=1795855081 unset=<vendor token>,PUBLIC_BASE_URL
LANE wording: PASS start=1795855056 end=1795855056
```

Plain wf-test.sh prints one more FAIL line at HEAD than at base (55 vs 54): the `gate --task` cases, including the new US-2.AC3 3-AC draft case, fail plainly only because the `sed -i ''` fixture lines before them never ran; on this PC the green evidence for US-2.AC1 to AC3 is the shim run above.

Plain-run red lanes: Decided (fable): the red-without-shim lanes do not fail this branch; the shim-plus-identity run is the lane result of record, no fix ticket, Out of Scope line plus TODOS.md entry (failure is older than the branch, spec never asked about it; Preference 2).

## Out of Scope

none. `wf scope` lists all 13 changed source files as unplanned, because it reads ticket files and /direct writes none. Each one is named in a Parts `files:` line in the index (P1: wf, wf-test.sh; P2: direct and quick check-refs and their tests; P3: install.sh, install-test.sh; P4: quick/SKILL.md, direct/SKILL.md, README.md, CLAUDE.md, install.sh, DECISIONS.md, no-quick-test.sh). Checked each Out of Scope line: the cap stays 3 (wf:363); no `/quick` stub or `--quick` alias (no-quick-test, US-2.AC4); prune only matches `"$src"/*` absolute targets directly in skills/ and hooks/ (install.sh:24-25); no skillshare code; `/spec`, `/slice`, `/build` are unchanged, and the `/direct` diff touches only the frontmatter, intro and steps 1-2 (hunks `@@ -1,13` and `@@ -19,8`), not the Orchestrated section.

## Structure

`wf size`: none
none

## Security

none. Finder: NO FINDINGS. Coverage: all 15 files in `git diff --name-only origin/main...HEAD` (wf, install.sh, direct/check-refs, direct/SKILL.md and the deleted quick files as source; the 4 tests and 5 docs read). Spot-checked caller: `skills/direct/SKILL.md:24` passes `$ARGUMENTS` to `WF entry` through a quoted heredoc (`<<'ARG'`), as the report says; `skills/build/scripts/afk-loop:70` sends `/direct $spec AFK`.

Safe because: install.sh's prune removes only a dangling link directly inside `~/.claude/skills` or `~/.claude/hooks` whose stored target is absolute and starts with `<checkout>/`, so it never deletes a real file, a live link, a sibling checkout's link or a nested entry. Proof: `bash /tmp/claude-1000/-home-lumbab-Developer-merge-quick/94274452-542b-4490-ac5d-9967bc828f1f/scratchpad/prune-proof.sh /home/lumbab/Developer/merge-quick` (runs the real install.sh with HOME set to a temp dir) ->

```
rc=0
pruned /tmp/tmp.ZC3ehPfS31/.claude/skills/dead-in
pruned /tmp/tmp.ZC3ehPfS31/.claude/hooks/dead-hook
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

- skills/build/scripts/wf:595: `/direct "README.md needs an install section"` (quoted task whose first word is an existing file) prints `spec`, then `gate --direct` lists spec errors for README.md; dropped as a finding because the spec's Decisions "Entry rule" chose "after any opening quote: an existing file means `spec`"; neither
- skills/build/scripts/wf:595: `/direct ~/x/docs/work/f/spec.md` (`~` path, not expanded through the quoted heredoc) is refused as `is not a file` although it exists; neither
- skills/build/scripts/wf:593: `/direct "docs/work/my feature/spec.md"` (spec path with a space) is classed `task`; with AFK it is refused as a task; neither
- skills/build/scripts/wf:591: `/direct " fix the login typo"` (space after the opening quote) prints `no argument`; neither

## Verify

not run: no verify skill

## Check warnings

none

## Fix tickets

none

## OPEN

none
