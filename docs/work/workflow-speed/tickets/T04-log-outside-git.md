# T04 Warning log survives resets and the gate ignores it

Spec: docs/work/workflow-speed/spec.md
Blocked by: T03

## Delivers

- US-6.AC8: Given a warning log with lines and a merge that is then undone with a hard reset, when the reset has finished, then the warning log still holds every line.
- US-6.AC9: Given the warning log is the only uncommitted change in the tree, when the gate runs, then it prints nothing about uncommitted changes.

## Files

- modify: skills/build/scripts/wf
- test: skills/build/scripts/test/warn-log-git-test.sh

## Interfaces

- Consumes: `wf warn-log <feature-dir> <check> <ticket-id> "<subject>: <text>"` from T03
- Consumes: `wf gate <spec|index.md> [--build|--final|--slice|--direct]` from skills/build/scripts/wf (`gate()`)
- Produces: `wf warn-log` also makes sure the line `check-warnings.log` is in `$(git -C <feature-dir> rev-parse --path-format=absolute --git-common-dir)/info/exclude` (appended once, creating `info/` if needed) before it writes. Outside a git repo it skips this silently.
- Produces: `gate()` drops `git status --porcelain` lines whose path basename is `check-warnings.log` before deciding the tree is dirty.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL warn-log-git-test: $*"; fail=1; }`, `wf=$(cd "$(dirname "$0")/.." && pwd)/wf`. Setup: a lead repo `L=$d/lead` on branch `feature/x` (`git init -q -b feature/x`, user config), holding a committed `docs/work/f/index.md` with lines `Branch: feature/x` and `Base: main`, and a committed `app.txt`. Ends `[ $fail = 0 ] && echo "OK warn-log-git-test"; exit $fail`.

### US-6.AC8 (guard)
File: skills/build/scripts/test/warn-log-git-test.sh
```bash
f=$L/docs/work/f
"$wf" warn-log "$f" delivers T01 "US-1.AC2: one"
"$wf" warn-log "$f" wording T02 "a.py:X: SURVIVED two"
git -C "$L" checkout -q -b t1; echo 2 > "$L/app.txt"; git -C "$L" commit -qam change
git -C "$L" checkout -q feature/x; git -C "$L" merge -q --no-ff t1 -m "merge T01"
git -C "$L" reset -q --hard HEAD^1
[ "$(cat "$f/check-warnings.log")" = $'delivers T01 US-1.AC2: one\nwording T02 a.py:X: SURVIVED two' ] || bad "AC8 log after reset: $(cat "$f/check-warnings.log" 2>&1)"
[ -z "$(git -C "$L" ls-files "$f/check-warnings.log")" ] || bad "AC8 the log is tracked"
```
Mutation to prove it: make `wf warn-log` run `git -C <feature-dir> add -f check-warnings.log && git commit -qm log` after writing; the reset then drops the lines and the test fails.

### US-6.AC9
File: skills/build/scripts/test/warn-log-git-test.sh
```bash
out=$("$wf" gate "$L/docs/work/f/index.md"); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || bad "AC9 gate with a warn-log written log (exit $rc): $out"
[ -z "$(git -C "$L" status --porcelain)" ] || bad "AC9 git status still shows the log: $(git -C "$L" status --porcelain)"
grep -qxF check-warnings.log "$(git -C "$L" rev-parse --path-format=absolute --git-common-dir)/info/exclude" || bad "AC9 no ignore entry"
# a log the writer did not create (no ignore entry) is skipped by the gate too
M=$d/lead2; git init -q -b feature/x "$M"; git -C "$M" config user.email t@t; git -C "$M" config user.name t
mkdir -p "$M/docs/work/f"; printf 'Branch: feature/x\nBase: main\n' > "$M/docs/work/f/index.md"; git -C "$M" add -A; git -C "$M" commit -qm init
printf 'delivers T01 US-1.AC2: x\n' > "$M/docs/work/f/check-warnings.log"
out=$("$wf" gate "$M/docs/work/f/index.md"); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || bad "AC9 gate with a hand-written log (exit $rc): $out"
# any other untracked file still counts
echo x > "$M/other.txt"
out=$("$wf" gate "$M/docs/work/f/index.md"); rc=$?
[ $rc = 1 ] && grep -qF "uncommitted changes" <<<"$out" || bad "AC9 gate ignored other.txt (exit $rc): $out"
```

## Approach

- The ignore entry goes in the repo's common git dir (`git rev-parse --git-common-dir`), so every worktree of that repo shares it; never edit the tracked `.gitignore`.
- In `gate()`, filter the porcelain output with `grep -vE '(^|/)check-warnings\.log$'` on the path column; the existing "gate dirty" assertion in wf-test.sh must stay green unchanged.

## Constraints

- Spec Decisions: the log is never committed; the gate does not count it as an uncommitted change; no clean-tree check anywhere counts it.
- Project CLAUDE.md: every check prints a `Fix:` (the gate's existing lines are unchanged here).
- macOS bash 3.2.

## Verify

`bash skills/build/scripts/test/warn-log-git-test.sh && bash skills/build/scripts/test/warn-log-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- `wf check-review` and review.md (T05).
- Changing `.gitignore`, `afk-loop`, `/pr` or `/unblock`.
