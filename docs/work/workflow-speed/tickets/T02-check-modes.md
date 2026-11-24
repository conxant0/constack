# T02 Checks read warn or block from a settings file

Spec: docs/work/workflow-speed/spec.md
Blocked by: T01

## Delivers

- US-6.AC2: Given a check set to `block` in the settings and a finding, when that check runs, then it prints FAIL and exits non-zero; set to `warn`, it prints a warning and the finding alone does not change the exit status.
- US-6.AC12: Given no settings file, or one that does not list a check, when that check runs, then it uses its shipped mode (delivers blocks, the others warn).
- US-6.AC13: Given a settings value other than `warn` or `block`, when that check runs, then it prints an ERROR line naming the value, with a `Fix:` line, and exits 2.

## Files

- create: skills/build/checks.conf
- modify: skills/build/scripts/wf
- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/scripts/test/check-red-green-test.sh
- test: skills/build/scripts/test/modes-test.sh

## Interfaces

- Consumes: `check-red-green.sh <worktree> <base-sha> "<verify>" [<ticket.md> [<ticket-start-sha>]]` and the `FAIL delivers <AC id>: ...` line from T01
- Consumes: `fx_repo`, `fx_commit`, `fx_ticket`, `FX_VERIFY` from T01 (skills/build/scripts/test/lib-fixture.sh)
- Produces: `wf mode <delivers|wording|guard-patch|earlier-tests>` in skills/build/scripts/wf: prints `warn` or `block`, exit 0. Unknown check name: `usage: wf mode delivers|wording|guard-patch|earlier-tests`, exit 2. Bad value: `ERROR <conf path>: <check>=<value> is not warn or block. Fix: set <check>=warn or <check>=block in <conf path>.`, exit 2.
- Produces: settings lookup: `$CHECKS_CONF` when set (the test seam), else `<dir of wf>/../checks.conf` (skills/build/checks.conf). Lines `<check>=<warn|block>`; blank and `#` lines ignored. Built-in defaults for a missing file or missing name: `delivers=block`, `wording=warn`, `guard-patch=warn`, `earlier-tests=warn`.
- Produces: skills/build/checks.conf shipping exactly those four lines (plus a `#` comment saying a check flips to block after 3 features with at most 1 false alarm, per spec Decisions).
- Produces: a finding line is `<WARN|FAIL> <check> <subject>: <text>. Fix: <fix>`: `FAIL` and exit 1 in block mode, `WARN` and no exit change in warn mode. T01's delivers line becomes `WARN delivers ...` in warn mode, same text otherwise.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL modes-test: $*"; fail=1; }`, sources `lib-fixture.sh`, `s=$(cd "$(dirname "$0")/.." && pwd)`. Shared setup: a repo `$r` with only `test(US-1.AC1): red` and a green commit, and a ticket `$t` delivering US-1.AC1 and US-1.AC2 (exactly the US-2.AC1 fixture in delivers-test.sh), so the delivers check has one finding for US-1.AC2. Ends `[ $fail = 0 ] && echo "OK modes-test"; exit $fail`.

### US-6.AC2
File: skills/build/scripts/test/modes-test.sh
```bash
fix=' Fix: add the red commit for US-1.AC2 (or a guard with a Mutation patch if the code already does it); a prefactor'"'"'s Delivers says none.'
printf 'delivers=block\n' > "$d/block.conf"
out=$(CHECKS_CONF=$d/block.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 1 ] || bad "AC2 block exit $rc, want 1"
grep -q "^FAIL delivers US-1.AC2: .*\.$fix\$" <<<"$out" || bad "AC2 block line: $out"
! grep -q '^WARN' <<<"$out" || bad "AC2 block printed a WARN: $out"
printf '# comment\n\ndelivers=warn\n' > "$d/warn.conf"
out=$(CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 0 ] || bad "AC2 warn exit $rc, want 0"
grep -q "^WARN delivers US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in .*\.$fix\$" <<<"$out" || bad "AC2 warn line: $out"
! grep -q '^FAIL' <<<"$out" || bad "AC2 warn printed a FAIL: $out"
```
(`$fix` holds a `.` and `(`; compare with `grep -F` on the Fix part if the regex trips on it.)

### US-6.AC12
File: skills/build/scripts/test/modes-test.sh
```bash
for conf in "$d/missing.conf" "$d/other.conf"; do
  printf 'wording=block\n' > "$d/other.conf"
  out=$(CHECKS_CONF=$conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
  [ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC12 [$conf] delivers did not block (exit $rc): $out"
done
for c in wording guard-patch earlier-tests; do
  [ "$(CHECKS_CONF=$d/missing.conf "$s/wf" mode $c)" = warn ] || bad "AC12 $c default is not warn (no file)"
  [ "$(CHECKS_CONF=$d/other.conf "$s/wf" mode $c)" = "$([ $c = wording ] && echo block || echo warn)" ] || bad "AC12 $c with other.conf"
done
[ "$(CHECKS_CONF=$d/missing.conf "$s/wf" mode delivers)" = block ] || bad "AC12 delivers default is not block"
```

### US-6.AC13
File: skills/build/scripts/test/modes-test.sh
```bash
printf 'delivers=maybe\n' > "$d/bad.conf"
out=$(CHECKS_CONF=$d/bad.conf "$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$t"); rc=$?
[ $rc = 2 ] || bad "AC13 exit $rc, want 2"
grep -qxF "ERROR $d/bad.conf: delivers=maybe is not warn or block. Fix: set delivers=warn or delivers=block in $d/bad.conf." <<<"$out" || bad "AC13 line: $out"
! grep -q '^FAIL delivers' <<<"$out" || bad "AC13 still ran the check: $out"
for c in wording guard-patch earlier-tests; do
  printf '%s=maybe\n' "$c" > "$d/bad-$c.conf"
  out=$(CHECKS_CONF=$d/bad-$c.conf "$s/wf" mode $c 2>&1); rc=$?
  [ $rc = 2 ] && [ "$out" = "ERROR $d/bad-$c.conf: $c=maybe is not warn or block. Fix: set $c=warn or $c=block in $d/bad-$c.conf." ] || bad "AC13 $c (exit $rc): $out"
done
```

## Approach

- The mode is one value (`warn` or `block`) held in one variable per check, read once through `wf mode`; never a boolean pair.
- check-red-green.sh resolves `delivers` mode only when a ticket argument is given, before the red/guard loop, and calls `"$here/wf" mode delivers` where `here` is the script's own absolute dir (made absolute before the `cd`). A non-zero `wf mode` exit: print its output and exit 2.
- Print findings through one function, e.g. `finding <mode> <check> <subject> <text> <fix>`, so every WARN and FAIL line has the same shape and a ` Fix: `.
- Add `mode` to wf's header comment and its catch-all usage line.
- Ruling 2026-11-24 (slice): skills/build/scripts/test/check-red-green-test.sh may change: its Fix lint pattern widens from `echo "(FAIL|ERROR)` to `echo "(FAIL|ERROR|WARN)` (stricter, nothing removed).

## Constraints

- Project CLAUDE.md "No implicit state machines": the mode is one explicit status (`warn` | `block`) computed in one named place (`wf mode`).
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Spec Decisions: a check in `warn` mode never stops an AFK run and never blocks a merge.
- macOS bash 3.2: no associative arrays, no `mapfile`.

## Verify

`bash skills/build/scripts/test/modes-test.sh && bash skills/build/scripts/test/delivers-test.sh && bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Writing the warning log (T03).
- US-6.AC1, the shipped modes across all four checks (T13).
- The wording, guard-patch and earlier-tests checks themselves (T06 to T10).
