# T11 review-lanes runs the full and clean suites together

Spec: docs/work/workflow-speed/spec.md
Blocked by: T00

## Delivers

- US-1.AC1: Given a branch whose final-review gate passed, when the review's script lanes run, then the full suite and the clean-checkout suite run at the same time (their run windows overlap) and each records pass or its failing test names.
- US-1.AC3: Given a worktree whose env file sets a variable one test needs, when the script lanes run the clean-checkout suite, then that test fails there and the lanes' output names the test and the variable.
- US-1.AC4: Given the script lanes have finished, pass or fail, when the review lists its worktrees, then no copy the lanes made is left.

## Files

- create: skills/build/scripts/review-lanes
- modify: install.sh
- modify: skills/final-review/SKILL.md
- test: skills/build/scripts/test/review-lanes-test.sh

## Interfaces

- Consumes: `test_re` from T00 (skills/build/scripts/test-re.sh)
- Produces: `review-lanes <index.md> <base-ref> [--only wording] [--wording-tests "<shell command>"]` in skills/build/scripts/review-lanes (executable bash). `<base-ref>` is BASE, or PREV on a delta run. This ticket builds the full and clean lanes and a wording lane that prints `LANE wording: PASS start=<n> end=<n>` when no non-test `.py` file changed in `<base-ref>...HEAD`; T12 fills in the rest of the wording lane and the two options.
- Produces: setup. Root = the index's git toplevel. Test command = the index's `Test command:` value with backticks stripped; missing: `ERROR <index>: no "Test command:" line. Fix: add the full suite command to the index (slice assets/index-template.md).`, exit 2. Include paths = `git ls-files -oi --exclude-from=.worktreeinclude --directory` in root (none when the file is missing). Env files = include paths whose basename starts `.env`. Copies live under `mktemp -d "${TMPDIR:-/tmp}/review-lanes.XXXXXX"`.
- Produces: lane full = `bash -c "<Test command>"` in root. Lane clean = `git worktree add --detach <tmp>/clean HEAD`, symlink each non-env include path into it, then `env -u <NAME>... bash -c "<Test command>"` there; names from `^(export )?NAME=` lines of the env files plus each line of `~/.claude/checks/clean-suite-env` when it exists. Lanes start together as background jobs, each writing its own output file; after `wait` the blocks print in the order full, clean, wording.
- Produces: block header `LANE <full|clean|wording>: <PASS|FAIL> start=<epoch seconds> end=<epoch seconds>`; the clean header adds ` unset=<NAME,NAME>` (names only, never values). A FAIL suite's body (indented two spaces) is its output lines matching `^(FAILED|ERROR|FAIL)[ :]`, at most 40, else its last 20 lines.
- Produces: exit 0 when every lane is PASS, 1 otherwise, 2 when it could not start. A trap on EXIT, INT and TERM runs `git worktree remove --force` on each copy, removes the temp dir and runs `git worktree prune`.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL review-lanes-test: $*"; fail=1; }`, `s=$(cd "$(dirname "$0")/.." && pwd)`, `export TMPDIR=$d/tmp; mkdir -p "$TMPDIR"`. Helper `mkrepo <dir> <with-env:yes|no>`: `git init -q`, user config; `run.sh` = `sleep 2; f=0; for t in tests/*.sh; do bash "$t" || { echo "FAILED $t"; f=1; }; done; exit $f`; `tests/ok.sh` = `true`; `docs/work/f/index.md` with ``Test command: `bash run.sh` ``; with env: `.gitignore` = `.env`, `.worktreeinclude` = `.env`, an untracked `.env` = `NEEDED=1`, and `tests/env.sh` = `[ -f .env ] && . ./.env; [ "${NEEDED:-}" = 1 ]`; commit `init`. Helper `field <out> <lane> <key>` prints `<key>=`'s value from that lane's header. Ends `[ $fail = 0 ] && echo "OK review-lanes-test"; exit $fail`.

### US-1.AC1
File: skills/build/scripts/test/review-lanes-test.sh
```bash
mkrepo "$d/a" yes; base=$(git -C "$d/a" rev-parse HEAD)
out=$(NEEDED=1 "$s/review-lanes" "$d/a/docs/work/f/index.md" "$base"); rc=$?
[ $rc = 1 ] || bad "AC1 exit $rc, want 1 (clean lane fails)"
grep -q '^LANE full: PASS start=[0-9]* end=[0-9]*$' <<<"$out" || bad "AC1 full header: $out"
grep -q '^LANE clean: FAIL start=[0-9]* end=[0-9]* unset=NEEDED$' <<<"$out" || bad "AC1 clean header: $out"
grep -qx '  FAILED tests/env.sh' <<<"$out" || bad "AC1 failing test not named: $out"
fs=$(field "$out" full start) fe=$(field "$out" full end) cs=$(field "$out" clean start) ce=$(field "$out" clean end)
[ "$fs" -lt "$ce" ] && [ "$cs" -lt "$fe" ] || bad "AC1 windows do not overlap: full $fs-$fe, clean $cs-$ce"
# the full lane records its failing test names too
mkrepo "$d/f" no; echo false > "$d/f/tests/bad.sh"; git -C "$d/f" add -A; git -C "$d/f" commit -qm bad
out2=$("$s/review-lanes" "$d/f/docs/work/f/index.md" "$(git -C "$d/f" rev-parse HEAD)"); rc=$?
[ $rc = 1 ] && grep -q '^LANE full: FAIL ' <<<"$out2" || bad "AC1 full lane FAIL not recorded (exit $rc): $out2"
for l in full clean; do
  awk -v l="$l:" '/^LANE /{on=($2==l)} on' <<<"$out2" | grep -qx '  FAILED tests/bad.sh' || bad "AC1 $l lane did not name tests/bad.sh: $out2"
done
```
(`out2`, so the AC3 block below still reads the first run's `$out`.)

### US-1.AC3
File: skills/build/scripts/test/review-lanes-test.sh
```bash
# NEEDED=1 is exported by the caller, so only the lane's env -u makes the test fail; the full lane reads .env and passes
grep -q '^LANE clean: FAIL .* unset=NEEDED$' <<<"$out" && grep -qx '  FAILED tests/env.sh' <<<"$out" || bad "AC3 test or variable not named: $out"
! grep -q 'NEEDED=1' <<<"$out" || bad "AC3 printed the value"
grep -q '^LANE full: PASS ' <<<"$out" || bad "AC3 full lane did not pass with the env file"
```

### US-1.AC4
File: skills/build/scripts/test/review-lanes-test.sh
```bash
# after the failing run above
[ "$(git -C "$d/a" worktree list | wc -l | tr -d ' ')" = 1 ] || bad "AC4 fail run left worktrees: $(git -C "$d/a" worktree list)"
[ -z "$(ls "$TMPDIR" | grep '^review-lanes\.')" ] || bad "AC4 fail run left temp dirs"
# and after a passing run
mkrepo "$d/b" no; base=$(git -C "$d/b" rev-parse HEAD)
out=$("$s/review-lanes" "$d/b/docs/work/f/index.md" "$base"); rc=$?
[ $rc = 0 ] && grep -q '^LANE clean: PASS ' <<<"$out" || bad "AC4 pass run (exit $rc): $out"
[ "$(git -C "$d/b" worktree list | wc -l | tr -d ' ')" = 1 ] || bad "AC4 pass run left worktrees: $(git -C "$d/b" worktree list)"
[ -z "$(ls "$TMPDIR" | grep '^review-lanes\.')" ] || bad "AC4 pass run left temp dirs"
```

## Approach

- Each lane writes `start`, `end`, status and output into its own file under the temp dir; the parent prints the blocks after `wait`, so output never interleaves.
- `.worktreeinclude` paths are symlinked, not copied (spec Decisions).
- install.sh: add `review-lanes` to the `chmod +x` list.
- skills/final-review/SKILL.md (spec Decisions "Final-review order"): steps 3 and 3b become one step: right after the gate, dispatch the security finder and the behaviour finder, run `${CLAUDE_SKILL_DIR}/../build/scripts/review-lanes <index> <BASE>` with `run_in_background` (PREV on a delta run), then do the lead's own steps (`wf red`, test judging, `wf scope` and Out of Scope, `wf size` and structure). Record each lane's header and body in review.md's Full suite section. The live check (6b) runs in the review's own tree once review-lanes has exited. Everything joins before the security coverage check, filters and proof, then the behaviour sort, then the write-up and step 8.
- Ruling 2026-11-24 (lead): review-lanes-test.sh may change: add `export HOME=$d/home; mkdir -p "$HOME"` to the test header right after `export TMPDIR=...`, so the real ~/.claude/checks/clean-suite-env does not leak into `unset=`. No assertion changes.

## Constraints

- Spec Decisions: the clean-checkout copy gets none of the env files; names are printed, never values.
- Project CLAUDE.md: every check prints a `Fix:`; each ERROR line has one.
- install.sh: every new script goes in the `chmod +x` list (code map).
- Prose edits follow the writing-for-agents skill.
- macOS bash 3.2: no `wait -n`, no `mapfile`.

## Verify

`bash skills/build/scripts/test/review-lanes-test.sh && bash test/install-test.sh`

## Out of scope

- The wording lane's copy, mutate-copy run, `--only` and `--wording-tests` (T12).
- Check warnings in final review (T05).
