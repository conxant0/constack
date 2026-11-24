# T01 Red-green check fails a Delivers AC with no red or guard commit

Spec: docs/work/workflow-speed/spec.md
Blocked by: T00

## Delivers

- US-2.AC1: Given a ticket whose Delivers line lists US-1.AC2 and a range with no `test(US-1.AC2): red` or `guard` commit, when the red-green check runs with that ticket, then it prints a FAIL line naming US-1.AC2 with a `Fix:` line and exits 1.
- US-2.AC2: Given a ticket whose Delivers line is `none` or `none (<reason>)` (a prefactor, refactor or test-isolation fix), when the red-green check runs with it, then it prints no delivers FAIL line.
- US-2.AC3: Given a ticket that delivers a lettered AC such as US-2.AC7b and a range with its red commit, when the red-green check runs, then it prints no delivers FAIL line for US-2.AC7b.
- US-2.AC4: Given a fix-round run whose range starts at the reviewed head and holds no red or guard commit, and the ticket's `test(US-1.AC2): red` commit sits between the ticket's start and that reviewed head, when the red-green check runs with that ticket and the ticket's start, then it prints no delivers FAIL line for US-1.AC2.

## Files

- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/SKILL.md
- create: skills/build/scripts/test/lib-fixture.sh
- test: skills/build/scripts/test/delivers-test.sh
- create: skills/build/scripts/ac-covered.sh
- modify: skills/build/scripts/wf

## Interfaces

- Consumes: `test_re` from T00 (skills/build/scripts/test-re.sh)
- Produces: `check-red-green.sh <worktree> <base-sha> "<verify>" [<ticket.md> [<ticket-start-sha>]]` in skills/build/scripts/check-red-green.sh. Ticket start defaults to `<base-sha>`. The ticket path is made absolute before the script's `cd`.
- Produces: line `FAIL delivers <AC id>: no "test(<AC id>): red" or guard commit in <start8>..<head8>. Fix: add the red commit for <AC id> (or a guard with a Mutation patch if the code already does it); a prefactor's Delivers says none.` (`<start8>`, `<head8>`: first 8 chars of the shas)
- Produces: in skills/build/scripts/test/lib-fixture.sh (sourced by later tests):
  - `FX_VERIFY='for t in tests/*.sh; do bash "$t" || exit 1; done'`
  - `fx_repo <dir>`: `git init -q`, sets user.email/user.name, writes `app.txt` (`1`) and `tests/base.sh` (`test -f app.txt`), commits `init`. Prints nothing.
  - `fx_commit <dir> <subject> [<path> <content>]...`: writes each path (creating dirs, content plus a newline), `git add -A`, commits with that subject, prints the new sha.
  - `fx_ticket <path> <delivers line>...`: writes a ticket file (creating dirs) with `# <id> x`, `## Delivers`, a blank line, each given line verbatim, then `## Files` with `- test: tests/x.sh`. The id is the basename up to the first `-`.

## Tests

### US-2.AC1
File: skills/build/scripts/test/delivers-test.sh
```bash
. "$(dirname "$0")/lib-fixture.sh"; s=$(cd "$(dirname "$0")/.." && pwd)
r=$d/r1; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
head=$(fx_commit "$r" 'feat: green' app.txt 2)
fx_ticket "$d/feat/tickets/T01-x.md" '- US-1.AC1: Given a, when b, then c' '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] || bad "AC1 exit $rc, want 1"
grep -qxF "FAIL delivers US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${base:0:8}..${head:0:8}. Fix: add the red commit for US-1.AC2 (or a guard with a Mutation patch if the code already does it); a prefactor's Delivers says none." <<<"$out" || bad "AC1 line missing: $out"
! grep -q 'delivers US-1.AC1' <<<"$out" || bad "AC1 flagged the delivered US-1.AC1"
# an AC named outside ## Delivers is not a promise
printf '\n## Out of scope\n\n- US-9.AC9 (T09)\n' >> "$d/feat/tickets/T01-x.md"
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md")
! grep -q 'delivers US-9.AC9' <<<"$out" || bad "AC1 read an AC outside ## Delivers: $out"
# a guard commit satisfies a delivered AC too
r=$d/r1g; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC1): red' tests/ac1.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
printf 'grep -qx 2 app.txt\n' > "$r/tests/g2.sh"; git -C "$r" add -A
git -C "$r" commit -qm 'test(US-1.AC2): guard' -m 'Mutation: app.txt: 2 -> 3 -> tests/g2.sh fails'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-1.AC2' <<<"$out" || bad "AC1 guard commit not accepted (exit $rc): $out"
r=$d/r1; base=$(git -C "$r" rev-list --max-parents=0 HEAD)   # the AC2 block reuses r1
```

### US-2.AC2 (guard)
File: skills/build/scripts/test/delivers-test.sh
```bash
for line in 'none' 'none (prefactor: no behaviour change, existing tests stay green)'; do
  fx_ticket "$d/feat2/tickets/T00-p.md" "$line"
  out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat2/tickets/T00-p.md"); rc=$?
  [ $rc = 0 ] || bad "AC2 [$line] exit $rc, want 0"
  ! grep -q ' delivers ' <<<"$out" || bad "AC2 [$line] printed a delivers line: $out"
done
```
Mutation to prove it: treat a `none` Delivers line as an AC id (print `FAIL delivers none: ...`, exit 1); the test fails on the exit and the line.

### US-2.AC3
File: skills/build/scripts/test/delivers-test.sh
```bash
r=$d/r3; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-2.AC7b): red' tests/ac7b.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
fx_ticket "$d/feat3/tickets/T02-l.md" '- US-2.AC7b: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat3/tickets/T02-l.md"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-2.AC7b' <<<"$out" || bad "AC3 lettered red not matched (exit $rc): $out"
# an unlettered red does not stand in for the lettered AC
r=$d/r3b; fx_repo "$r"; base=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-2.AC7): red' tests/ac7.sh 'grep -qx 2 app.txt' >/dev/null
fx_commit "$r" 'feat: green' app.txt 2 >/dev/null
out=$("$s/check-red-green.sh" "$r" "$base" "$FX_VERIFY" "$d/feat3/tickets/T02-l.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-2.AC7b: ' <<<"$out" || bad "AC3 AC7 red accepted for AC7b (exit $rc): $out"
```

### US-2.AC4
File: skills/build/scripts/test/delivers-test.sh
```bash
r=$d/r4; fx_repo "$r"; start=$(git -C "$r" rev-parse HEAD)
fx_commit "$r" 'test(US-1.AC2): red' tests/ac2.sh 'grep -qx 2 app.txt' >/dev/null
reviewed=$(fx_commit "$r" 'feat: green' app.txt 2)
fx_commit "$r" 'refactor: review fix' other.txt x >/dev/null
fx_ticket "$d/feat4/tickets/T01-f.md" '- US-1.AC2: Given a, when b, then c'
out=$("$s/check-red-green.sh" "$r" "$reviewed" "$FX_VERIFY" "$d/feat4/tickets/T01-f.md" "$start"); rc=$?
[ $rc = 0 ] && ! grep -q 'delivers US-1.AC2' <<<"$out" || bad "AC4 with start (exit $rc): $out"
# without the start, the range is reviewed..HEAD and holds no red commit
out=$("$s/check-red-green.sh" "$r" "$reviewed" "$FX_VERIFY" "$d/feat4/tickets/T01-f.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC4 start default is not base (exit $rc): $out"
```

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL delivers-test: $*"; fail=1; }`, and it ends `[ $fail = 0 ] && echo "OK delivers-test"; exit $fail`. These fixtures need no pytest (`narrowed()` falls back to the verify string for `.sh` tests).

## Approach

- Delivers AC ids: lines under the ticket's `## Delivers` heading (up to the next `## `) matching `^- US-[0-9]+\.AC[0-9]+[a-z]?:`. None (for example `none`, `none (...)`): no delivers line.
- An AC is satisfied by a subject exactly `test(<id>): red` or `test(<id>): guard` in `git log --format=%s <start>..HEAD`; use fixed-string whole-line matching so AC7 never matches AC7b.
- The delivers lines print after the existing red/guard/frozen lines and before the green line; any of them sets exit 1.
- An unreadable ticket: `ERROR cannot read ticket <path>. Fix: pass the ticket path from the index (docs/work/<feature>/tickets/<id>-*.md).`, exit 2. A start that is not a commit or not an ancestor of HEAD: `ERROR ticket start <start> is not an ancestor of HEAD. Fix: pass the BASE the ticket was dispatched from.`, exit 2.
- Update the usage comment at the top of check-red-green.sh with the two optional arguments and a `DELIVERS:` line.
- skills/build/SKILL.md, Loop step 3 `done` and step 4 (Decisions "/build order on an implementer's done"):
  - Step 3: run `check-red-green.sh <WORKTREE> <BASE> "<ticket Verify>" <ticket path> <BASE>` with `run_in_background`, and dispatch the quality reviewer at once.
  - Step 4: dispatch the ticket reviewer when the check reports, with its output. A check FAIL while the quality review runs: wait for both and send the FAIL lines and the quality findings in one message; after that fix the quality reviewer re-reviews the fix diff even if it said pass. A quality `fix` that arrives before the check finishes waits for the check before any message to the implementer. The ticket reviewer does not re-check fix diffs only the quality reviewer asked for.
  - Fix rounds pass `<reviewed head>` as base and the ticket's dispatch BASE as start. A chain's next ticket passes its own BASE as both.
  - Keep step 3's existing "a Delivers AC with no OK red or OK guard line" sentence (spec Out of Scope: removing prompt text a check replaces).
- Ruling 2026-11-24 (lead): the rule "each `- US-n.ACm:` line needs a `test(<id>): red` or `test(<id>): guard` subject in the range" lives once, in a function in the new sourced file skills/build/scripts/ac-covered.sh; check-red-green.sh (Delivers section only) and `wf red` (whole file) both call it. wf's `red` output and exit codes stay byte-identical (wf-test.sh is the check).

## Constraints

- Project CLAUDE.md: every check prints a `Fix:` saying how to repair what it flags; a check's own test asserts the `Fix:` text.
- check-red-green-test.sh lints that every `echo "FAIL` / `echo "ERROR` line in the script contains ` Fix: `.
- DECISIONS.md: build SKILL.md stays at or under about 80 lines.
- Prose edits follow the writing-for-agents skill.
- macOS bash 3.2: no `mapfile`, no `flock`.
- DECISIONS.md: red and guard commits touch test files only.

## Verify

`bash skills/build/scripts/test/delivers-test.sh && bash skills/build/scripts/test/check-red-green-test.sh python3`

## Out of scope

- warn/block modes and the settings file (T02), the warning log (T03).
- The wording check and US-2.AC5 (T08); guard patches (T06, T07).
- Removing any prompt text the check replaces.
