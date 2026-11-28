# F01 The final gate names a merged part still doing

Spec: docs/work/direct-parts/spec.md
Blocked by: none
Fixes: review.md ## Behaviour, skills/direct/SKILL.md:40 (the orchestrated flow never marks its last part done)

## Delivers

- US-3.AC7: Given a build index with parts P1 done and P2 doing, no tickets folder, and a commit with the subject "merge P2: b" on the branch, when the final gate runs, then it exits 1, names P2, does not say to run the ticket build, and its Fix line says to finish the no-ticket build (lead check, quality review, full suite) and then mark P2 done with that merge commit.

## Files

- modify: skills/build/scripts/wf
- modify: skills/direct/SKILL.md
- test: skills/build/scripts/test/final-gate-parts-test.sh

## Interfaces

- Consumes: `wf gate <spec|index.md> --final` and `frontier <index.md>` from skills/build/scripts/wf
- Produces: `wf gate <spec> --final` prints, for an index with a `## Parts` section and no `tickets/` folder, one line per `doing` part whose `merge <part>:` commit is in Base..HEAD: `<index>:<row line>: <part> is merged (<sha, 8 chars>) but still doing. Fix: finish the no-ticket build (lead check, quality review, full suite), then run wf done <index> <part> <sha>.` in place of the `not every ticket is done (run /build)` line. Every other reply is unchanged.

## Tests

### US-3.AC7
File: skills/build/scripts/test/final-gate-parts-test.sh
```bash
#!/usr/bin/env bash
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
r=$d/r; mkdir -p "$r"; git -C "$r" init -q -b main; git -C "$r" config user.email t@t; git -C "$r" config user.name t
echo a > "$r/app.txt"; git -C "$r" add -A; git -C "$r" commit -qm base
git -C "$r" checkout -qb feature/x; mkdir -p "$r/docs/work/x"; x=$r/docs/work/x
printf '# X\n\nStatus: approved\nBranch: feature/x\nBase: main\n' > "$x/spec.md"
printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: feature/x\nBase: main\nTest command: `true`\n\n| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | done abc12345 |\n| P2 | b | P1 | doing |\n\n## Open questions\n\nnone\n\n## Parts\n\n- P1: US-1.AC1; files: a.sh\n- P2: US-1.AC2; files: b.sh\n' > "$x/index.md"
git -C "$r" add -A; git -C "$r" commit -qm 'docs(direct): x index'
git -C "$r" checkout -qb helper; echo b > "$r/b.sh"; git -C "$r" add -A; git -C "$r" commit -qm 'feat(US-1.AC2): green'
git -C "$r" checkout -q feature/x; git -C "$r" merge -q --no-ff helper -m 'merge P2: b'
sha=$(git -C "$r" rev-parse --short=8 HEAD)
[ ! -e "$x/tickets" ] || { echo "FAIL US-3.AC7 fixture has a tickets folder"; fail=1; }
out=$("$wf" gate "$x/spec.md" --final 2>&1); rc=$?
want="$x/index.md:11: P2 is merged ($sha) but still doing. Fix: finish the no-ticket build (lead check, quality review, full suite), then run wf done $x/index.md P2 $sha."
[ "$rc" = 1 ] && [ "$out" = "$want" ] || { printf 'FAIL US-3.AC7: exit %s, got:\n%s\nwant (exit 1):\n%s\n' "$rc" "$out" "$want"; fail=1; }
case $out in *"/build"*) echo "FAIL US-3.AC7 the reply names the ticket build: $out"; fail=1 ;; esac
[ $fail = 0 ] && echo "OK final-gate-parts-test"; exit $fail
```

## Approach

- The gate change is the check; the skill edit is what stops the state from being the normal end of a run. Both ship in this ticket: in `skills/direct/SKILL.md` Orchestrated step 8, after the suite passes and before removing the helpers' worktrees, add `WF done <index> <last part> <its merge sha>`.
- A ticket index, a parts index with a `tickets/` folder, and a `doing` part with no `merge <part>:` commit keep today's line, word for word.

## Constraints

- Every check prints a `Fix:` saying how to repair what it flags, and the check's own test asserts the `Fix:` text (CLAUDE.md, Code rules).
- The existing "gate --final not done" and "gate --final all done" cases in skills/build/scripts/test/wf-test.sh stay as they are and stay green.
- No change to `skills/build` or `skills/slice` prompts (spec, Out of Scope).

## Verify

`bash skills/build/scripts/test/final-gate-parts-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- One shared reader for a Parts line (declined in review.md, Structure).
- `wf scope` reading Parts lines, and the other notes under review.md ## Behaviour.
