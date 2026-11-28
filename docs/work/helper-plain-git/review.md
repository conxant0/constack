# Helpers run git in forms an isolated worktree accepts: final review

Verdict: PASS
Spec: docs/work/helper-plain-git/spec.md
Range: origin/main...5b15a016cb55f6a2060533394d6682a9ddfbd2b9
Mode: delta since 7b71457
Date: 2026-11-28

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | fa49f49 | yes | Guard fa49f49: lint-helper-git-test.sh:8 now needs one line holding `no \`cd\``, `no \`git -C\``, `no \`$( )\``, `no \`{ }\``, "split", "refused" and "instead of sending it again" in each of helper.md and implementer.md. Its Mutation (dropping "no" before the four forms in helper.md:15, the change that survived last round) makes the test print FAIL AC1. |
| US-1.AC2 | 1ac8fb9 | yes | Re-judged (test file changed in PREV..HEAD; lines 13-21 unchanged): checks each guard step holds `git diff --output=<file>`, `Write tool`, `cat <head> <diff> <tail> > <message file>` and no `{ `. |
| US-1.AC3 | 73cfdb0 | yes | Re-judged (test file changed in PREV..HEAD; lines 23-47 unchanged): checks the three fixtures exit 1 with file:line, form and `Fix:`, the plain `&&` chain is not flagged, and the repo run prints nothing with exit 0. |

## Full suite

`test/run-all.sh <python with pytest>`: pass

LANE full: PASS start=1795871272 end=1795871359
LANE clean: PASS start=1795871272 end=1795871359 unset=<db token, redacted>,PUBLIC_BASE_URL
LANE wording: PASS start=1795871272 end=1795871272

## Out of Scope

none. `wf scope` again lists every changed file except F01's test file, because it does not read a /direct index's Parts. Checked by hand: the delta 7b71457..HEAD changes only skills/build/scripts/test/lint-helper-git-test.sh (F01's Files) and this folder's docs. The full-branch scope check carried from 7b71457 still holds: P1's five files plus this folder; the retro-log files belong to the retro-log feature, which passed its own review.

## Structure

`wf size`: none
none

## Security

none. Finder coverage (delta, BASE 7b71457): all 5 changed files listed; the one non-doc file, lint-helper-git-test.sh, read in full with its caller. Spot-checked caller: test/run-all.sh:11 runs `skills/*/scripts/test/*-test.sh` through `bash "$t"`, as the report says.

Safe because: lint-helper-git uses the text it scans only as grep and echo data and never runs it. Proof (re-run at HEAD; the fix diff does not touch the linter): `printf 'Run \`git log $(touch PWNED)\` and \`{ touch PWNED; git log; }\` and \`git -C $(touch PWNED) log\`.\n' > inj.md && bash skills/build/scripts/lint-helper-git inj.md; ls PWNED` -> four flagged lines, rc=1, `ls: cannot access 'PWNED': No such file or directory`.

## Behaviour

none

### Notes

- skills/build/scripts/test/lint-helper-git-test.sh:8-9: a rule line that forbids all four forms in other words (e.g. "Never use `cd`, `git -C`, `$( )` or `{ }`") gets the headline "no line forbids ...", which is false there; the Fix line under it names the exact wording, and following it passes. neither
- skills/build/scripts/lint-helper-git:30 and :34: a missing file passed in, or a missing helper.md or implementer.md, prints a bash error and exits 0. neither (carried from 7b71457)
- skills/build/scripts/lint-helper-git:10: a last line with no trailing newline is not scanned. neither (carried from 7b71457)
- skills/build/scripts/lint-helper-git:25: commands inside a fenced block are not scanned. The spec's Decisions scan backticked commands only. neither (carried from 7b71457)
- skills/build/scripts/lint-helper-git:18, :20, :21: a `{ }` group after `do` or `then`, `(cd wt && git log -1)` and `git -c k=v -C wt log` are not flagged. neither (carried from 7b71457)
- skills/build/scripts/lint-helper-git:37-39: if the `5. **Copy check` heading is renamed, the scan runs into lead-only steps and flags them with the helper Fix, not the missing heading. neither (carried from 7b71457)

## Verify

not run: no verify skill

## Check warnings

none

## Fix tickets

none

## OPEN

none
