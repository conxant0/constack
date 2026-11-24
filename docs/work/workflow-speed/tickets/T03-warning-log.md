# T03 Warnings are appended once to the feature's warning log

Spec: docs/work/workflow-speed/spec.md
Blocked by: T02

## Delivers

- US-6.AC3: Given a check run for a ticket, in warning mode, prints a warning, when it runs, then one line with the check name, the ticket id and the warning text is appended to the feature folder's warning log.
- US-6.AC4: Given the same warning line is already in the log, when the check prints it again on a re-run, then the log does not get a second copy.
- US-6.AC5: Given a check set to `block` prints a FAIL, when it runs, then nothing is written to the warning log.
- US-6.AC10: Given two checks that each print a different warning at the same time, when both have finished, then the warning log holds both lines.

## Files

- modify: skills/build/scripts/wf
- modify: skills/build/scripts/check-red-green.sh
- test: skills/build/scripts/test/warn-log-test.sh

## Interfaces

- Consumes: `wf mode <check>`, `CHECKS_CONF`, and the `WARN <check> <subject>: <text>. Fix: <fix>` line shape from T02
- Consumes: `check-red-green.sh <worktree> <base-sha> "<verify>" [<ticket.md> [<ticket-start-sha>]]` from T01
- Consumes: `fx_repo`, `fx_commit`, `fx_ticket`, `FX_VERIFY` from T01 (skills/build/scripts/test/lib-fixture.sh)
- Produces: `wf warn-log <feature-dir> <check> <ticket-id> "<subject>: <text>"` in skills/build/scripts/wf: appends the line `<check> <ticket-id> <subject>: <text>` to `<feature-dir>/check-warnings.log` unless that exact line is already there. Exit 0; wrong argument count: `usage: wf warn-log <feature-dir> <check> <ticket-id> "<subject>: <text>"`, exit 2.
- Produces: check-red-green.sh, given a ticket, calls `wf warn-log` for every WARN line it prints. Feature dir = `dirname(dirname(<ticket>))`; ticket id = the ticket file's basename up to the first `-`. The logged text is the printed line minus the leading `WARN `, minus the check name, minus the trailing `. Fix: ...`.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL warn-log-test: $*"; fail=1; }`, sources `lib-fixture.sh`, `s=$(cd "$(dirname "$0")/.." && pwd)`, and `printf 'delivers=warn\n' > "$d/warn.conf"; printf 'delivers=block\n' > "$d/block.conf"`. Helper `mkcase <repo> <ticket path> <AC delivered> <AC missing>`: `fx_repo`, a red commit for the delivered AC, a green commit, `fx_ticket` listing both ACs; it sets `base` and `head`. Ends `[ $fail = 0 ] && echo "OK warn-log-test"; exit $fail`.

### US-6.AC3
File: skills/build/scripts/test/warn-log-test.sh
```bash
mkcase "$d/r1" "$d/feat/tickets/T01-x.md" US-1.AC1 US-1.AC2
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md" >/dev/null
[ "$(cat "$d/feat/check-warnings.log")" = "delivers T01 US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${base:0:8}..${head:0:8}" ] \
  || bad "AC3 log: $(cat "$d/feat/check-warnings.log" 2>&1)"
```

### US-6.AC4
File: skills/build/scripts/test/warn-log-test.sh
```bash
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r1" "$base" "$FX_VERIFY" "$d/feat/tickets/T01-x.md" >/dev/null
[ "$(wc -l < "$d/feat/check-warnings.log" | tr -d ' ')" = 1 ] || bad "AC4 re-run duplicated: $(cat "$d/feat/check-warnings.log")"
# dedupe is by the exact line: a different warning from the same check and ticket still lands
"$s/wf" warn-log "$d/feat" delivers T01 "US-1.AC3: another warning"
[ "$(wc -l < "$d/feat/check-warnings.log" | tr -d ' ')" = 2 ] || bad "AC4 a different line from the same ticket was dropped: $(cat "$d/feat/check-warnings.log")"
```

### US-6.AC5 (guard)
File: skills/build/scripts/test/warn-log-test.sh
```bash
mkcase "$d/r2" "$d/featb/tickets/T01-x.md" US-1.AC1 US-1.AC2
out=$(CHECKS_CONF=$d/block.conf "$s/check-red-green.sh" "$d/r2" "$base" "$FX_VERIFY" "$d/featb/tickets/T01-x.md"); rc=$?
[ $rc = 1 ] && grep -q '^FAIL delivers US-1.AC2: ' <<<"$out" || bad "AC5 block run did not FAIL (exit $rc): $out"
[ ! -s "$d/featb/check-warnings.log" ] || bad "AC5 block mode wrote the log: $(cat "$d/featb/check-warnings.log")"
```
Mutation to prove it: make check-red-green.sh call `wf warn-log` for FAIL lines too; the test fails on the log.

### US-6.AC10
File: skills/build/scripts/test/warn-log-test.sh
```bash
mkcase "$d/r3" "$d/featc/tickets/T01-a.md" US-1.AC1 US-1.AC2; b3=$base h3=$head
mkcase "$d/r4" "$d/featc/tickets/T02-b.md" US-2.AC1 US-2.AC5; b4=$base h4=$head
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r3" "$b3" "$FX_VERIFY" "$d/featc/tickets/T01-a.md" >/dev/null &
CHECKS_CONF=$d/warn.conf "$s/check-red-green.sh" "$d/r4" "$b4" "$FX_VERIFY" "$d/featc/tickets/T02-b.md" >/dev/null &
wait
log=$d/featc/check-warnings.log
grep -qxF "delivers T01 US-1.AC2: no \"test(US-1.AC2): red\" or guard commit in ${b3:0:8}..${h3:0:8}" "$log" || bad "AC10 T01 line missing: $(cat "$log")"
grep -qxF "delivers T02 US-2.AC5: no \"test(US-2.AC5): red\" or guard commit in ${b4:0:8}..${h4:0:8}" "$log" || bad "AC10 T02 line missing: $(cat "$log")"
[ "$(wc -l < "$log" | tr -d ' ')" = 2 ] || bad "AC10 want 2 lines: $(cat "$log")"
# many writers at once, each a different line: every line lands whole
mkdir -p "$d/featd"
for i in $(seq 1 40); do "$s/wf" warn-log "$d/featd" wording "T$i" "x.py:A: line $i" & done; wait
[ "$(wc -l < "$d/featd/check-warnings.log" | tr -d ' ')" = 40 ] || bad "AC10 40 writers: $(wc -l < "$d/featd/check-warnings.log") lines, want 40"
[ "$(sort -u "$d/featd/check-warnings.log" | wc -l | tr -d ' ')" = 40 ] || bad "AC10 40 writers: broken or duplicate lines"
[ "$(grep -c '^wording T[0-9]* x.py:A: line [0-9]*$' "$d/featd/check-warnings.log")" = 40 ] || bad "AC10 40 writers: malformed lines"
```

## Approach

- `wf warn-log` uses no lock: `grep -Fxq -- "$line" "$log" 2>/dev/null || printf '%s\n' "$line" >> "$log"`, one `printf` per line (spec Decisions). Two writers racing on the very same line may both append it (measured: 3 of 20 and 5 of 20 runs with 40 same-line writers; spec Out of Scope); no AC covers that, so it is not tested.
- Log only when a ticket argument was given and the mode is `warn`; a FAIL is never logged.
- `wf warn-log` creates the feature dir's log file if missing; it does not create the feature dir.

## Constraints

- Spec Decisions: the warning log lives in the lead's feature folder, the one holding the ticket, never in an implementer's worktree, and is never committed.
- Project CLAUDE.md: every check prints a `Fix:`.
- macOS bash 3.2: no `flock`.

## Verify

`bash skills/build/scripts/test/warn-log-test.sh && bash skills/build/scripts/test/modes-test.sh && bash skills/build/scripts/test/delivers-test.sh`

## Out of scope

- The local ignore entry and the gate exemption (T04).
- `wf check-review` and review.md's `Check warnings` section (T05).
- Logging from `wf done` (T09).
