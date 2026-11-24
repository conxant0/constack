# T10 wf done: red-commit rewrites, brand-new files, block mode

Spec: docs/work/workflow-speed/spec.md
Blocked by: T09

## Delivers

- US-5.AC4: Given a ticket that adds a brand-new test file in an ordinary commit, when `wf done` runs for it, then it prints no warning for that file.
- US-5.AC6: Given T2's red commit removes or rewrites a line in a test file T1's red commit touched, with no matching `may change:` line, when `wf done` runs for T2, then it prints a warning naming the file and T2, with a `Fix:` line.
- US-5.AC7: Given T2's red commit only adds lines to that file, when `wf done` runs for T2, then it prints no warning for that file.
- US-5.AC8: Given the check is set to `block` and has a finding, when `wf done` runs, then it prints FAIL, exits 1 and does not record the ticket done, and its `Fix:` line says to undo the merge and send the finding to the implementer.

## Files

- modify: skills/build/scripts/earlier-tests.sh
- test: skills/build/scripts/test/earlier-tests-block-test.sh
- test: skills/build/scripts/test/earlier-tests-test.sh (fixture only, see Ruling)

## Interfaces

- Consumes: `lead <dir>` and `merge_ticket <dir> <branch> <subject> <path> <content>...` from T09 (skills/build/scripts/test/lib-lead.sh)
- Consumes: the earlier-tests check in `earlier_tests` (skills/build/scripts/earlier-tests.sh; its `B`, `S`, `P`, ruling lookup, warn line and Fix) from T09; `wf mode earlier-tests` and `CHECKS_CONF` from T02
- Produces: a red/guard commit in `S..<sha>` that deletes a file in `P` or has deletions > 0 on it (numstat) gives, once per file: `earlier-tests <file>: <id> commit <sha8> (red or guard) removed or rewrote lines` (same warn Fix and logging as T09).
- Produces: block mode prints the finding as `FAIL earlier-tests <subject>: <text>. Fix: undo the merge (git reset --hard <merge sha8>^1), wf set <index path> <id> "blocked: earlier tests: <file>", and send this line to the implementer.`, exits 1, leaves the index untouched (no status change, no commit) and writes nothing to the log.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `wf=$(cd "$(dirname "$0")/.." && pwd)/wf`, sources `lib-lead.sh` (for `lead` and `merge_ticket`, T09); `bad() { echo "FAIL earlier-tests-block-test: $*"; fail=1; }`; `printf 'earlier-tests=warn\n' > "$d/w.conf"; printf 'earlier-tests=block\n' > "$d/b.conf"`. Every block starts with T1 merged: `test(US-1.AC1): red` adding `tests/t1.sh` with two lines `test -f app.txt` and `true`. Ends `[ $fail = 0 ] && echo "OK earlier-tests-block-test"; exit $fail`.

### US-5.AC4 (guard)
File: skills/build/scripts/test/earlier-tests-block-test.sh
```bash
lead "$d/a"; merge_ticket "$d/a" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/a" t2 'feat: T2 code' tests/new.sh 'true')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/a/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/new.sh' <<<"$out" || bad "AC4 warned on a brand-new file: $out"
```
Mutation to prove it: make `P` also include every `test_re` path in `git ls-tree -r <sha>`; the test then fails.

### US-5.AC6
File: skills/build/scripts/test/earlier-tests-block-test.sh
```bash
for kind in rewrite delete; do
  lead "$d/b-$kind"; merge_ticket "$d/b-$kind" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
  git -C "$d/b-$kind" checkout -q -b t2
  if [ $kind = rewrite ]; then printf 'test -f app.txt\nfalse\n' > "$d/b-$kind/tests/t1.sh"; else git -C "$d/b-$kind" rm -q tests/t1.sh; fi
  git -C "$d/b-$kind" add -A; git -C "$d/b-$kind" commit -qm 'test(US-1.AC2): red'; c=$(git -C "$d/b-$kind" rev-parse HEAD)
  git -C "$d/b-$kind" checkout -q main; git -C "$d/b-$kind" merge -q --no-ff t2 -m "merge t2"; m=$(git -C "$d/b-$kind" rev-parse HEAD)
  out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/b-$kind/docs/work/f/index.md" T02 "$m")
  grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} (red or guard) removed or rewrote lines. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC6 [$kind] line: $out"
done
```

### US-5.AC7 (guard)
File: skills/build/scripts/test/earlier-tests-block-test.sh
```bash
lead "$d/c"; merge_ticket "$d/c" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/c" t2 'test(US-1.AC2): red' tests/t1.sh $'test -f app.txt\ntrue\ntest -s app.txt')
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/c/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/t1.sh' <<<"$out" || bad "AC7 warned on an add-only red edit: $out"
```
Mutation to prove it: treat any red/guard commit touching a file in `P` as a rewrite (ignore numstat deletions); the test fails.

### US-5.AC8
File: skills/build/scripts/test/earlier-tests-block-test.sh
```bash
lead "$d/e"; merge_ticket "$d/e" t1 'test(US-1.AC1): red' tests/t1.sh $'test -f app.txt\ntrue' >/dev/null
m=$(merge_ticket "$d/e" t2 'feat: T2 code' tests/t1.sh 'true'); c=$(git -C "$d/e" rev-parse "$m^2")
idx=$d/e/docs/work/f/index.md
out=$(CHECKS_CONF=$d/b.conf "$wf" done "$idx" T02 "$m"); rc=$?
[ $rc = 1 ] || bad "AC8 exit $rc, want 1"
grep -qxF "FAIL earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: undo the merge (git reset --hard ${m:0:8}^1), wf set $idx T02 \"blocked: earlier tests: tests/t1.sh\", and send this line to the implementer." <<<"$out" || bad "AC8 line: $out"
grep -q '^| T02 | b | T01 | todo |' "$idx" || bad "AC8 recorded done: $(grep '^| T02' "$idx")"
[ "$(git -C "$d/e" rev-parse HEAD)" = "$m" ] || bad "AC8 committed after FAIL"
[ ! -s "$d/e/docs/work/f/check-warnings.log" ] || bad "AC8 logged a FAIL"
```

## Approach

- Ruling 2026-11-24 (lead): `skills/build/scripts/test/earlier-tests-test.sh` may change: in the "ticket's own red or guard commit" block (lines 52-56), the T2 red and guard commits keep every existing line of tests/t1.sh and tests/base.sh and only add their new line (e.g. `$'test -f app.txt\ntest -s app.txt'`), since US-5.AC6 now warns on red commits that rewrite lines; the no-WARN assertion stays unchanged.

- Extend T09's `earlier_tests` in earlier-tests.sh; with several findings, print all of them, then in block mode return 1 (wf's `|| exit 1` stops before `set_status`). Do not edit wf.
- `--no-renames` on `git diff-tree`, so a rename shows as a delete plus an add.

## Constraints

- Spec Decisions: in `block` mode a finding is handled like a failed post-merge suite: the merge is undone and the finding goes to the implementer.
- Project CLAUDE.md "No implicit state machines": the mode is the one `warn`|`block` value from `wf mode`.
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.

## Verify

`bash skills/build/scripts/test/earlier-tests-block-test.sh && bash skills/build/scripts/test/earlier-tests-test.sh && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Undoing the merge inside `wf done` (the lead does it from the Fix line).
- US-6.AC1 (T13).
