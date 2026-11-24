# T09 wf done warns on edits to earlier or Base tests

Spec: docs/work/workflow-speed/spec.md
Blocked by: T05, T06

## Delivers

- US-5.AC1: Given ticket T1's red commit touched a test file and a later ticket T2 changes that file outside a red or guard commit, with no ruling line in T2 naming that file before `may change:`, when `wf done` runs for T2, then it prints a warning naming the file and T2, with a `Fix:` line.
- US-5.AC2: Given the same change, and T2 has a ruling line naming that file before `may change:`, when `wf done` runs for T2, then it prints no warning for that file.
- US-5.AC3: Given a test file that existed at Base and a ticket changes it outside a red or guard commit with no matching `may change:` line, when `wf done` runs for that ticket, then it prints a warning naming the file.
- US-5.AC5: Given the check is in warning mode and prints a warning, when `wf done` runs, then the ticket is still recorded done.

## Files

- modify: skills/build/scripts/wf
- modify: skills/build/SKILL.md
- modify: skills/final-review/assets/fix-ticket-template.md
- modify: skills/direct/SKILL.md
- create: skills/build/scripts/test/lib-lead.sh
- test: skills/build/scripts/test/earlier-tests-test.sh

## Interfaces

- Consumes: `test_re` from T00 (skills/build/scripts/test-re.sh); `wf mode earlier-tests` and the finding line shape from T02; `wf warn-log` from T03
- Consumes: `wf done <index.md> <id> <merge sha>` and `base_ref()` from skills/build/scripts/wf
- Produces: `wf done` runs the earlier-tests check before recording done:
  - `B` = `git merge-base <index Base:> <sha>`, computed only when `git rev-parse -q --verify "<Base>^{commit}"` succeeds in the index's repo. When the Base: line is missing or does not resolve, the earlier-tests check is skipped: no line on stdout or stderr, nothing logged, and the ticket is recorded done as today, in warn and in block mode alike. The existing `expect "done" 0 ""` case in wf-test.sh pins this and must pass unedited (spec Out of Scope).
  - Ticket start `S` = `<sha>^1` when `<sha>` has two parents; else the newest commit reachable from `<sha>` whose subject is exactly `docs(build): <id> doing`; else `B`.
  - Protected files `P` = files touched by commits in `B..S` whose subject matches `^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$`, plus paths in `git ls-tree -r --name-only B` matching `test_re`.
  - For each non-merge commit in `S..<sha>` (`git diff-tree --no-commit-id --numstat --no-renames -r`), a non-red/guard commit touching a file in `P` gives, once per file: `earlier-tests <file>: <id> commit <sha8> changed it outside a red or guard commit`.
- Produces: warn-mode line `WARN earlier-tests <file>: <id> commit <sha8> changed it outside a red or guard commit. Fix: the lead adds "Ruling <date> (lead): <file> may change: <what>" to the ticket if build rule 8 allows the change; otherwise final review grades this line.`, logged with `wf warn-log <index dir> earlier-tests <id> "<file>: <id> commit <sha8> changed it outside a red or guard commit"`; then the ticket is recorded done as today.
- Produces: `lead <dir>` and `merge_ticket <dir> <branch> <subject> <path> <content>...` in skills/build/scripts/test/lib-lead.sh (sourced), as the Tests section describes.
- Produces: a file is skipped when a `may change:` line allows it. Lines read: every line of `<index dir>/tickets/<id>-*.md` when it exists, and lines under `## Rulings` in the index that start `- <date>, <id> `. A line allows file F when it contains `may change:` and, with backticks removed, a whitespace-separated token before `may change:` equals F's repo-relative path exactly.

## Tests

The test file's header: `set -u`, `d=$(mktemp -d); trap 'rm -rf "$d"' EXIT`, `fail=0`, `bad() { echo "FAIL earlier-tests-test: $*"; fail=1; }`, `wf=$(cd "$(dirname "$0")/.." && pwd)/wf`, `printf 'earlier-tests=warn\n' > "$d/c.conf"; export CHECKS_CONF=$d/c.conf`. Sources `lib-lead.sh` for `lead` and `merge_ticket` (this ticket's Produces). `lead <dir>`: `git init -q -b main`, user config, commits `app.txt` (`1`), `tests/base.sh` (`test -f app.txt`) and `docs/work/f/index.md` (lines `Branch: main`, `Base: base`, where `base` is a tag `lead` puts on this init commit; rows `| T01 | a | none | done x |` and `| T02 | b | T01 | todo |`, then `## Rulings`), and `docs/work/f/tickets/T02-b.md` (`# T02 b`, `## Approach`, `- none`). `merge_ticket <dir> <branch> <subject> <path> <content>...`: `git checkout -q -b <branch>`, one commit per (subject, path, content) triple, `git checkout -q main`, `git merge -q --no-ff <branch> -m "merge <branch>"`, prints the merge sha. Setup for every block: T1 merged first with `test(US-1.AC1): red` adding `tests/t1.sh` (`test -f app.txt`). Ends `[ $fail = 0 ] && echo "OK earlier-tests-test"; exit $fail`.

### US-5.AC1
File: skills/build/scripts/test/earlier-tests-test.sh
```bash
lead "$d/a"; merge_ticket "$d/a" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
m=$(merge_ticket "$d/a" t2 'feat: T2 code' tests/t1.sh 'true')
c=$(git -C "$d/a" rev-parse "$m^2")
out=$("$wf" done "$d/a/docs/work/f/index.md" T02 "$m"); rc=$?
[ $rc = 0 ] || bad "AC1 exit $rc"
grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC1 line: $out"
grep -qxF "earlier-tests T02 tests/t1.sh: T02 commit ${c:0:8} changed it outside a red or guard commit" "$d/a/docs/work/f/check-warnings.log" || bad "AC1 not logged"
```

### US-5.AC2
File: skills/build/scripts/test/earlier-tests-test.sh
```bash
for where in ticket index; do
  lead "$d/b-$where"; merge_ticket "$d/b-$where" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
  if [ $where = ticket ]; then echo '- Ruling 2026-11-24 (lead): `tests/t1.sh` may change: one more check' >> "$d/b-$where/docs/work/f/tickets/T02-b.md"
  else "$wf" ruling "$d/b-$where/docs/work/f/index.md" "T02 (lead): tests/t1.sh may change: one more check" >/dev/null; fi
  git -C "$d/b-$where" commit -qam ruling >/dev/null 2>&1
  m=$(merge_ticket "$d/b-$where" t2 'feat: T2 code' tests/t1.sh 'true')
  out=$("$wf" done "$d/b-$where/docs/work/f/index.md" T02 "$m")
  ! grep -q 'earlier-tests tests/t1.sh' <<<"$out" || bad "AC2 [$where] warned despite the ruling: $out"
done
# a ruling for another path, or for another ticket, does not allow it
lead "$d/b2"; merge_ticket "$d/b2" t1 'test(US-1.AC1): red' tests/t1.sh 'test -f app.txt' >/dev/null
"$wf" ruling "$d/b2/docs/work/f/index.md" "T01 (lead): tests/t1.sh may change: x" >/dev/null
echo '- Ruling 2026-11-24 (lead): tests/t1.sh.bak may change: x' >> "$d/b2/docs/work/f/tickets/T02-b.md"; git -C "$d/b2" commit -qam r
m=$(merge_ticket "$d/b2" t2 'feat: T2 code' tests/t1.sh 'true')
out=$("$wf" done "$d/b2/docs/work/f/index.md" T02 "$m")
grep -q '^WARN earlier-tests tests/t1.sh: T02 ' <<<"$out" || bad "AC2 a non-matching ruling allowed it: $out"
```

### US-5.AC3
File: skills/build/scripts/test/earlier-tests-test.sh
```bash
lead "$d/c"
m=$(merge_ticket "$d/c" t2 'feat: T2 code' tests/base.sh 'true')
c=$(git -C "$d/c" rev-parse "$m^2")
out=$("$wf" done "$d/c/docs/work/f/index.md" T02 "$m")
grep -q "^WARN earlier-tests tests/base.sh: T02 commit ${c:0:8} changed it outside a red or guard commit\. Fix: " <<<"$out" || bad "AC3 line: $out"
```

### US-5.AC5 (guard)
File: skills/build/scripts/test/earlier-tests-test.sh
```bash
# the AC1 run above warned; the ticket is still recorded done
grep -q '^| T02 | b | T01 | done ' "$d/a/docs/work/f/index.md" || bad "AC5 T02 not done: $(grep '^| T02' "$d/a/docs/work/f/index.md")"
[ "$(git -C "$d/a" log -1 --format=%s)" = "docs(build): T02 done" ] || bad "AC5 done commit missing"
```
Mutation to prove it: exit 1 after printing a WARN in `earlier_tests`, before `set_status`; the test fails on the row and the commit.

## Approach

- Put the check in its own function (e.g. `earlier_tests <index> <id> <sha>`) called from the `done)` case before `set_status`; T10 adds the red/guard rewrite rule and block mode to it.
- `wf done` without a mode file uses the built-in `earlier-tests=warn`.
- Prose (spec Decisions on `may change:`):
  - skills/build/SKILL.md rule 8: `Ruling <date> (lead): <test file path> may change: <what changes>` (path, not test name).
  - fix-ticket-template.md Approach gains: `Ruling <date> (final-review): <test file path> may change: <what>` for a fix that edits an existing test.
  - direct/SKILL.md rule 3: log an allowed change with `WF ruling <index> "T01 (direct): <test file path> may change: <what>"`.

## Constraints

- Spec Decisions: the earlier-tests check stays in `wf done`, after the merge; a `warn` check never blocks a merge.
- Spec Decisions: a test file is whatever the red-green check already treats as one (`test_re`).
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- DECISIONS.md: build SKILL.md stays at or under about 80 lines.
- Prose edits follow the writing-for-agents skill.
- skills/build/SKILL.md rule 5: `index.md` changes only through `wf`.

## Verify

`bash skills/build/scripts/test/earlier-tests-test.sh && bash skills/build/scripts/test/wf-test.sh && bash skills/build/scripts/test/afk-loop-test.sh`

## Out of scope

- Red/guard commits that rewrite lines, brand-new files, block mode (T10).
- US-6.AC1 (T13).
