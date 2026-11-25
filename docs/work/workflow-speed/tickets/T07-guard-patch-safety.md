# T07 Guard patch: no Mutation, clean restore, test-file patch

Spec: docs/work/workflow-speed/spec.md
Blocked by: T06

## Delivers

- US-4.AC5: Given a guard commit with no `Mutation:` line at all, when the red-green check runs, then it prints a FAIL line and exits 1, as it does today.
- US-4.AC6: Given any guard patch check, when the red-green check finishes, then the worktree has no changed file and is back on the branch it started on.
- US-4.AC7: Given a guard commit whose patch changes a test file, when the red-green check runs, then it prints a guard-patch warning saying the patch must change production code only, with a `Fix:` line.

## Files

- modify: skills/build/scripts/check-red-green.sh
- test: skills/build/scripts/test/guard-patch-safety-test.sh

## Interfaces

- Consumes: `fx_guard <dir> <AC id> <test path> <test content> <body file>`, `mkguard <repo> <body file>` and `patch_of <repo> <file> <new content>` from T06, and `fx_repo`, `fx_commit`, `FX_VERIFY` from T01 (skills/build/scripts/test/lib-fixture.sh)
- Consumes: the guard-patch finding lines and the guard body shape from T06
- Produces: guard-patch finding `guard-patch <ac> <sha8>: Mutation patch changes a test file (<path>). Fix: the patch must change production code only; break the code, not the test.` when `git apply --numstat` lists a path matching `test_re`; the patch is then not applied.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, sources `lib-fixture.sh` (for `mkguard` and `patch_of`), `s=$(cd "$(dirname "$0")/.." && pwd)`, `printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf`, `bad() { echo "FAIL guard-patch-safety-test: $*"; fail=1; }`. Ends `[ $fail = 0 ] && echo "OK guard-patch-safety-test"; exit $fail`.

### US-4.AC5 (guard)
File: skills/build/scripts/test/guard-patch-safety-test.sh
```bash
printf 'no mutation here\n' > "$d/b5"
mkguard "$d/r5" "$d/b5"
out=$("$s/check-red-green.sh" "$d/r5" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 1 ] || bad "AC5 exit $rc, want 1"
grep -qxF "FAIL guard US-1.AC1 ${sha:0:8}: no \"Mutation: \" line in the commit body. Fix: break the code the way the AC forbids, see the test fail, restore, and add \"Mutation: <change> -> <failure>\" to the guard commit body." <<<"$out" || bad "AC5 line: $out"
! grep -q 'guard-patch' <<<"$out" || bad "AC5 also printed a guard-patch line: $out"
```
Mutation to prove it: in check-red-green.sh, make the empty-`mut` branch print the OK guard line instead of FAIL; the test fails on the exit code and the line.

### US-4.AC6 (guard)
File: skills/build/scripts/test/guard-patch-safety-test.sh
```bash
fx_repo "$d/r6"; fx_commit "$d/r6" 'chore: other' other.txt a >/dev/null
# case kill: the patch makes the test fail
{ echo 'Mutation: app.txt: 1 -> 3 -> fails'; echo '```diff'; patch_of "$d/r6" app.txt 3; echo '```'; } > "$d/k"
# case new file: the patch adds a production file and the tests still pass
echo x > "$d/r6/new.txt"; git -C "$d/r6" add -N new.txt
{ echo 'Mutation: new.txt: added -> nothing'; echo '```diff'; git -C "$d/r6" diff -- new.txt; echo '```'; } > "$d/n"
git -C "$d/r6" rm -q --cached new.txt; rm "$d/r6/new.txt"
# case no apply
sed 's/^-1$/-7/' "$d/k" > "$d/x"
for b in k n x; do
  mkguard "$d/r6-$b" "$d/$b"; br=$(git -C "$d/r6-$b" symbolic-ref --short HEAD)
  "$s/check-red-green.sh" "$d/r6-$b" "$base" "$FX_VERIFY" >/dev/null
  [ -z "$(git -C "$d/r6-$b" status --porcelain)" ] || bad "AC6 [$b] left changes: $(git -C "$d/r6-$b" status --porcelain)"
  [ "$(git -C "$d/r6-$b" symbolic-ref -q --short HEAD)" = "$br" ] || bad "AC6 [$b] not back on $br"
done
```
Mutation to prove it: drop the `git apply -R` restore and the created-path removal; case [n] fails on the leftover new.txt.

### US-4.AC7
File: skills/build/scripts/test/guard-patch-safety-test.sh
```bash
fx_repo "$d/r7"; fx_commit "$d/r7" 'chore: other' other.txt a >/dev/null
mkdir -p "$d/r7/tests"; printf 'grep -qx 1 app.txt\n' > "$d/r7/tests/g1.sh"; git -C "$d/r7" add tests/g1.sh
{ echo 'Mutation: tests/g1.sh: 1 -> 9 -> fails'; echo '```diff'; printf 'grep -qx 9 app.txt\n' > "$d/r7/tests/g1.sh"; git -C "$d/r7" diff -- tests/g1.sh; echo '```'; } > "$d/b7"
git -C "$d/r7" rm -q -f --cached tests/g1.sh; rm "$d/r7/tests/g1.sh"
mkguard "$d/r7" "$d/b7"
out=$("$s/check-red-green.sh" "$d/r7" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC7 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation patch changes a test file (tests/g1.sh). Fix: the patch must change production code only; break the code, not the test." <<<"$out" || bad "AC7 line: $out"
! grep -q 'tests still pass\|does not apply' <<<"$out" || bad "AC7 applied the test patch: $out"
```
The AC7 fixture's diff must be taken against the committed test content; if `git diff` prints nothing for the staged-then-edited file, use `git add tests/g1.sh` with the original content, edit, then `git diff -- tests/g1.sh` (index vs worktree).

## Approach

- Check `git apply --numstat <patch>` paths against `test_re` before `git apply --check`; a test path ends the patch step with the AC7 line.
- Restore: `git apply -R <patch>`, then remove any path the patch created (from `git apply --numstat`/`--summary` "create mode" lines); the EXIT trap does `git checkout -q -f "$branch"` and removes those created paths, so an early exit is also clean.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- DECISIONS.md: red and guard commits touch test files only; a guard's mutation breaks production code.
- macOS bash 3.2.

## Verify

`bash skills/build/scripts/test/guard-patch-safety-test.sh && bash skills/build/scripts/test/guard-patch-test.sh && bash skills/build/scripts/test/check-red-green-test.sh python3`

## Out of scope

- The wording check (T08).
- Changing the text of today's no-Mutation FAIL line.
