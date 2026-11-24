# T12 review-lanes wording lane in its own copy

Spec: docs/work/workflow-speed/spec.md
Blocked by: T11

## Delivers

- US-1.AC2: Given a branch that changes a sentence in a string constant, when the script lanes run, then the wording check runs in its own copy of the branch at HEAD: the review's working tree shows no changed tracked file at any moment of the full suite's run, and the full suite's result matches a run with no wording check beside it.
- US-1.AC5: Given a branch whose tests need an ignored path the worktree include file lists (a virtual environment or an env file), when the script lanes run the wording check in its own copy, then the copy has that path and the wording check reports sentences instead of stopping with exit 2.

## Files

- modify: skills/build/scripts/review-lanes
- modify: skills/final-review/SKILL.md
- test: skills/build/scripts/test/review-lanes-wording-test.sh

## Interfaces

- Consumes: `review-lanes <index.md> <base-ref> [--only wording] [--wording-tests "<shell command>"]`, its setup (include paths, temp dir, trap) and header shape from T11
- Consumes: `mutate-copy [--base REF] FILE.py... -- TEST COMMAND` from skills/build/scripts/mutate-copy
- Produces: lane wording. Files = `git diff --name-only --diff-filter=AM <base-ref>...HEAD -- '*.py'` minus `test_re` matches. None: `PASS`, no copy. Otherwise `git worktree add --detach <tmp>/wording HEAD`, symlink every include path (env files too), and run there `mutate-copy --base <base-ref> <files> -- bash -c "<--wording-tests value, default the Test command>"`.
- Produces: wording header status `PASS` (exit 0), `SURVIVED` (exit 1) or `COULD-NOT-RUN` (any other exit). Body: mutate-copy's `SURVIVED` lines and its count line; for `COULD-NOT-RUN`, mutate-copy's last line, then `Fix: re-run review-lanes <index> <base-ref> --only wording --wording-tests "<the tests covering those files, with -x and --deselect per snapshot file>"`.
- Produces: `--only wording` runs the wording lane alone (prints only its block).

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL review-lanes-wording-test: $*"; fail=1; }`, `s=$(cd "$(dirname "$0")/.." && pwd)`, `py=${1:-python3}`; `"$py" -c 'import pytest' 2>/dev/null || { echo "SKIP review-lanes-wording-test: no python with pytest"; exit 0; }`; `export TMPDIR=$d/tmp PYTHONDONTWRITEBYTECODE=1; mkdir -p "$TMPDIR"`. Helper `pyrepo <dir> <extra assert>`: `git init -q`, user config; `mod.py` = `MSG = "Old sentence."`; `tests/test_mod.py` = `import os, sys; sys.path.insert(0, os.getcwd()); import mod` plus `def test_msg():` asserting `"short" in mod.MSG.lower() or "old" in mod.MSG.lower()` and the `<extra assert>` line; `run.sh` = `for i in 1 2 3 4; do echo "$(pwd -P) [$(git status --porcelain --untracked-files=no | tr '\n' ';')]" >> "$STATUS_LOG"; sleep 0.5; done; <py> -m pytest -q -p no:cacheprovider tests`; `docs/work/f/index.md` with ``Test command: `bash run.sh` ``; commit `init` (sets `base`); then `mod.py` = `MSG = "Keep it short."`, commit `feat: wording`. Ends `[ $fail = 0 ] && echo "OK review-lanes-wording-test"; exit $fail`.

### US-1.AC2
File: skills/build/scripts/test/review-lanes-wording-test.sh
```bash
pyrepo "$d/a" '    pass'; root=$(cd "$d/a" && pwd -P)
export STATUS_LOG=$d/status.log
out=$("$s/review-lanes" "$d/a/docs/work/f/index.md" "$base"); rc=$?
grep -q '^LANE wording: \(PASS\|SURVIVED\) ' <<<"$out" || bad "AC2 wording lane did not run: $out"
grep -q '1 sentences: ' <<<"$out" || bad "AC2 wording lane checked no sentence (copy not at HEAD?): $out"
mine=$(grep -F "$root [" "$STATUS_LOG")
[ "$(wc -l <<<"$mine" | tr -d ' ')" -ge 4 ] || bad "AC2 full lane sampled too little: $mine"
! grep -vxF "$root []" <<<"$mine" | grep -q . || bad "AC2 review tree had changed tracked files: $mine"
grep -q "/wording \[" "$STATUS_LOG" || bad "AC2 wording lane did not run in its own copy: $(cat "$STATUS_LOG")"
# the full lane's result matches a plain run of the Test command
(cd "$d/a" && bash run.sh >/dev/null 2>&1); plain=$([ $? = 0 ] && echo PASS || echo FAIL)
grep -q "^LANE full: $plain " <<<"$out" || bad "AC2 full lane differs from a plain run ($plain): $out"
[ -z "$(git -C "$d/a" status --porcelain --untracked-files=no)" ] || bad "AC2 review tree left changed"
```

### US-1.AC5
File: skills/build/scripts/test/review-lanes-wording-test.sh
```bash
for need in venv env; do
  if [ $need = venv ]; then ign='.venv/'; path=.venv/marker; else ign='.env'; path=.env; fi
  pyrepo "$d/b-$need" "    assert os.path.exists('$path')"
  printf '%s\n' "$ign" > "$d/b-$need/.gitignore"; printf '%s\n' "$ign" > "$d/b-$need/.worktreeinclude"
  git -C "$d/b-$need" add .gitignore .worktreeinclude; git -C "$d/b-$need" commit -qm include
  mkdir -p "$d/b-$need/.venv"; echo x > "$d/b-$need/$path"
  out=$(STATUS_LOG=$d/s2.log "$s/review-lanes" "$d/b-$need/docs/work/f/index.md" "$base" --only wording); rc=$?
  grep -q '^LANE wording: \(PASS\|SURVIVED\) ' <<<"$out" || bad "AC5 [$need] wording lane: $out"
  ! grep -q 'COULD-NOT-RUN' <<<"$out" || bad "AC5 [$need] could not run: $out"
  grep -q '1 sentences: ' <<<"$out" || bad "AC5 [$need] no sentence reported: $out"
done
# control: without the include file the copy lacks .env, so the lane cannot run
pyrepo "$d/c-env" "    assert os.path.exists('.env')"; echo x > "$d/c-env/.env"
out=$(STATUS_LOG=$d/s3.log "$s/review-lanes" "$d/c-env/docs/work/f/index.md" "$base" --only wording)
grep -q '^LANE wording: COULD-NOT-RUN ' <<<"$out" && grep -q 'Fix: re-run review-lanes .* --only wording --wording-tests ' <<<"$out" || bad "AC5 control: missing include path did not give COULD-NOT-RUN: $out"
```

## Approach

- mutate-copy edits files in place, so it must only ever run inside `<tmp>/wording`; never in root.
- `--wording-tests` replaces only the wording lane's command; the full and clean lanes always use the Test command.
- skills/final-review/SKILL.md step 4's **Copy** paragraph: the wording check is review-lanes' wording lane; on `COULD-NOT-RUN` re-run it with `--only wording --wording-tests "<tests covering those files, -x, a --deselect per snapshot file>"`; never run mutate-copy in the review's own tree.

## Constraints

- Spec Decisions: the wording check's copy gets every path the worktree include file lists, env files included; it covers sentences in module-level string constants in Python source files new or changed against the base.
- Project CLAUDE.md: every check prints a `Fix:`.
- Prose edits follow the writing-for-agents skill.
- macOS bash 3.2.

## Verify

`bash skills/build/scripts/test/review-lanes-wording-test.sh python3 && bash skills/build/scripts/test/review-lanes-test.sh`

## Out of scope

- The per-ticket wording check in the red-green check (T08).
- Changing mutate-copy.
