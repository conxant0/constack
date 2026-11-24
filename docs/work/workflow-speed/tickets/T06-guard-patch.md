# T06 Guard patch applied: OK, still passes, does not apply, missing

Spec: docs/work/workflow-speed/spec.md
Blocked by: T03

## Delivers

- US-4.AC1: Given a guard commit whose body holds a fenced unified diff under `Mutation:` that makes its tests fail, when the red-green check runs, then it prints an OK guard line.
- US-4.AC2: Given a guard commit whose patch applies but its tests still pass with it applied, when the red-green check runs, then it prints a warning naming the guard and AC, with a `Fix:` line.
- US-4.AC3: Given a guard commit whose patch does not apply, when the red-green check runs, then it prints a warning saying the patch does not apply, with a `Fix:` line.
- US-4.AC4: Given a guard commit with a prose `Mutation:` line and no patch, when the red-green check runs, then it prints a guard-patch warning saying the patch is missing, with a `Fix:` line.

## Files

- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/scripts/test/lib-fixture.sh
- modify: skills/build/references/implementer.md
- modify: skills/final-review/references/test-only-fix.md
- modify: skills/direct/SKILL.md
- test: skills/build/scripts/test/guard-patch-test.sh

## Interfaces

- Consumes: `wf mode guard-patch`, `CHECKS_CONF` and the finding line shape `<WARN|FAIL> <check> <subject>: <text>. Fix: <fix>` from T02; `wf warn-log` from T03 (a WARN is logged only when a ticket argument was given)
- Consumes: `fx_repo`, `fx_commit`, `fx_ticket`, `FX_VERIFY` from T01 (skills/build/scripts/test/lib-fixture.sh)
- Produces: `fx_guard <dir> <AC id> <test path> <test content> <body file>` in skills/build/scripts/test/lib-fixture.sh: writes the test file, `git add -A`, commits with subject `test(<AC id>): guard` and the body file's text via `git commit --cleanup=verbatim -F` (subject line plus a blank line plus the body), prints the new sha.
- Produces: `mkguard <repo> <body file>` in skills/build/scripts/test/lib-fixture.sh: when `<repo>/.git` is missing, `fx_repo <repo>` and `fx_commit <repo> 'chore: other' other.txt a`; then sets the globals `base=$(git -C <repo> rev-parse HEAD)` and `sha=$(fx_guard <repo> US-1.AC1 tests/g1.sh 'grep -qx 1 app.txt' <body file>)`.
- Produces: `patch_of <repo> <file> <new content>` in skills/build/scripts/test/lib-fixture.sh: writes the new content to `<repo>/<file>`, prints `git -C <repo> diff -- <file>`, then `git -C <repo> checkout -- <file>`.
- Produces: guard body shape: the prose line `Mutation: <file>: <what changed> -> <failing line>`, directly followed by a fence opened by a line of exactly three backticks plus `diff` and closed by a line of exactly three backticks, holding `git diff -- <production files>` taken while the break is in place.
- Produces: after the unchanged `OK   guard <ac> <sha8>: <Mutation line>` line, at most one guard-patch finding line, subject `<ac> <sha8>`:
  - no fence: `guard-patch <ac> <sha8>: Mutation has no patch. Fix: re-do the break, save git diff -- <file>, and put it in the guard commit body in a diff fence under the Mutation: line (git commit --amend --cleanup=verbatim -F <file>).`
  - `git apply --check` fails: `guard-patch <ac> <sha8>: Mutation patch does not apply at the guard commit. Fix: regenerate it with git diff at that commit and commit with --cleanup=verbatim (the default cleanup strips blank lines and trailing spaces).`
  - applied and the guard's tests still pass: `guard-patch <ac> <sha8>: tests still pass with the Mutation patch applied. Fix: strengthen the test until this patch makes it fail, or pick the break the AC forbids.`
  - applied and the tests fail: no extra line.
  Each prints as `WARN ...` in warn mode, `FAIL ...` with exit 1 in block mode.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL guard-patch-test: $*"; fail=1; }`, sources `lib-fixture.sh`, `s=$(cd "$(dirname "$0")/.." && pwd)`, `printf 'guard-patch=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf`. Uses `mkguard` and `patch_of` from lib-fixture.sh (this ticket's Produces). Ends `[ $fail = 0 ] && echo "OK guard-patch-test"; exit $fail`.

### US-4.AC1 (guard)
File: skills/build/scripts/test/guard-patch-test.sh
```bash
fx_repo "$d/r1"; fx_commit "$d/r1" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails'; echo '```diff'; patch_of "$d/r1" app.txt 3; echo '```'; } > "$d/b1"
mkguard "$d/r1" "$d/b1"   # mkguard re-runs fx_repo only when the repo is missing
out=$("$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC1 exit $rc, want 0: $out"
grep -qxF "OK   guard US-1.AC1 ${sha:0:8}: Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails" <<<"$out" || bad "AC1 OK line: $out"
! grep -q 'guard-patch' <<<"$out" || bad "AC1 printed a guard-patch finding: $out"
```
Mutation to prove it: print the "tests still pass with the Mutation patch applied" line whenever a patch is present; the test fails on `! grep guard-patch`.

### US-4.AC2
File: skills/build/scripts/test/guard-patch-test.sh
```bash
fx_repo "$d/r2"; fx_commit "$d/r2" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: other.txt: a -> b -> nothing'; echo '```diff'; patch_of "$d/r2" other.txt b; echo '```'; } > "$d/b2"
mkguard "$d/r2" "$d/b2"
out=$("$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC2 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: tests still pass with the Mutation patch applied. Fix: strengthen the test until this patch makes it fail, or pick the break the AC forbids." <<<"$out" || bad "AC2 line: $out"
grep -q "^OK   guard US-1.AC1 ${sha:0:8}: " <<<"$out" || bad "AC2 OK guard line gone: $out"
```

### US-4.AC3
File: skills/build/scripts/test/guard-patch-test.sh
```bash
fx_repo "$d/r3"; fx_commit "$d/r3" 'chore: other' other.txt a >/dev/null
{ echo 'Mutation: app.txt: 7 -> 3 -> tests/g1.sh fails'; echo '```diff'; patch_of "$d/r3" app.txt 3 | sed 's/^-1$/-7/'; echo '```'; } > "$d/b3"
mkguard "$d/r3" "$d/b3"
out=$("$s/check-red-green.sh" "$d/r3" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC3 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation patch does not apply at the guard commit. Fix: regenerate it with git diff at that commit and commit with --cleanup=verbatim (the default cleanup strips blank lines and trailing spaces)." <<<"$out" || bad "AC3 line: $out"
[ "$(cat "$d/r3/app.txt")" = 1 ] || bad "AC3 app.txt changed"
```

### US-4.AC4
File: skills/build/scripts/test/guard-patch-test.sh
```bash
fx_repo "$d/r4"; fx_commit "$d/r4" 'chore: other' other.txt a >/dev/null
echo 'Mutation: app.txt: 1 -> 3 -> tests/g1.sh fails' > "$d/b4"
mkguard "$d/r4" "$d/b4"
out=$("$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 0 ] || bad "AC4 warn mode changed the exit: $rc"
grep -qxF "WARN guard-patch US-1.AC1 ${sha:0:8}: Mutation has no patch. Fix: re-do the break, save git diff -- <file>, and put it in the guard commit body in a diff fence under the Mutation: line (git commit --amend --cleanup=verbatim -F <file>)." <<<"$out" || bad "AC4 line: $out"
grep -q "^OK   guard US-1.AC1 ${sha:0:8}: Mutation: app.txt" <<<"$out" || bad "AC4 OK guard line gone: $out"
# with a ticket, the warning is logged (US-6.AC3 for this check)
fx_ticket "$d/gp/tickets/T05-g.md" '- US-1.AC1: Given a, when b, then c'
"$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY" "$d/gp/tickets/T05-g.md" >/dev/null
grep -qxF "guard-patch T05 US-1.AC1 ${sha:0:8}: Mutation has no patch" "$d/gp/check-warnings.log" || bad "guard-patch WARN not logged: $(cat "$d/gp/check-warnings.log" 2>&1)"
# block mode turns it into FAIL and exit 1 (US-6.AC2 for this check)
printf 'guard-patch=block\n' > "$d/gb.conf"
out=$(CHECKS_CONF=$d/gb.conf "$s/check-red-green.sh" "$d/r4" "$base" "$FX_VERIFY"); rc=$?
[ $rc = 1 ] && grep -q "^FAIL guard-patch US-1.AC1 ${sha:0:8}: Mutation has no patch\. Fix: " <<<"$out" || bad "guard-patch block (exit $rc): $out"
```

## Approach

- Run the patch step at the detached guard commit, after today's on-arrival pass and Mutation-line checks, and only when both passed.
- Extract the first fence after the `Mutation:` line: lines after one exactly ```` ```diff ```` up to the next line exactly ```` ``` ````, into a temp file outside the worktree.
- `git apply --check` then `git apply`; run the same `narrowed()` command; restore with `git apply -R`. Change the EXIT trap to `git checkout -q -f "$branch"` (T07 adds removing created paths and proves the restore).
- Resolve `guard-patch` mode once at the start through `wf mode guard-patch` (every run, with or without a ticket).
- Prose writers (spec Decisions "Guard patch writers"): implementer.md's Guard AC paragraph, test-only-fix.md step 3, and direct/SKILL.md step 4's Guard bullet each say: keep the break in place, save `git diff -- <production files>`, restore, and commit the test with `git commit --cleanup=verbatim -F <message file>` whose body is the `Mutation:` line followed by that diff in a ```` ```diff ```` fence; never `-m` for the patch.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Spec Decisions: a check in `warn` mode never stops an AFK run and never blocks a merge.
- DECISIONS.md: red and guard commits touch test files only.
- Prose edits follow the writing-for-agents skill.
- macOS bash 3.2.

## Verify

`bash skills/build/scripts/test/guard-patch-test.sh && bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/delivers-test.sh`

## Out of scope

- US-4.AC5, AC6, AC7 (T07): the no-Mutation FAIL, the restore proof, a patch that changes a test file.
- Final review's reading of the patch (T05).
- Patch mutations for /encode-comments tests.
