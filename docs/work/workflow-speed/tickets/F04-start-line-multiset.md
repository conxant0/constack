# F04 earlier-tests compares red commits with the ticket's real start, counting repeated lines

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Acceptance criteria rows US-5.AC6 (repeated line removed, no warning: `bash /tmp/fr2-80119/beh/dup-line.sh`) and US-5.AC7 (add-only red warned after a sibling merged into the file: `bash /tmp/fr2-80119/beh/stale-branch.sh`)

## Delivers

- US-5.AC6: Given T2's red commit removes or rewrites a line that a test file T1's red commit touched had when T2 started, with no matching `may change:` line, when `wf done` runs for T2, then it prints a warning naming the file and T2, with a `Fix:` line.
- US-5.AC7: Given T2's red commit only adds lines to that file, when `wf done` runs for T2, then it prints no warning for that file.

## Files

- modify: skills/build/scripts/earlier-tests.sh
- test: skills/build/scripts/test/earlier-tests-block-test.sh

## Interfaces

- Consumes: `earlier_tests <index> <id> <sha>` in skills/build/scripts/earlier-tests.sh (its `s`, `p`, `kind` loop); `lead`, `merge_ticket` from skills/build/scripts/test/lib-lead.sh
- Produces: no signature change. Warn text and Fix unchanged.

## Tests

### US-5.AC6
File: skills/build/scripts/test/earlier-tests-block-test.sh (append before the final line)
```bash
lead "$d/dup"
t1=$'t_a() {\n  run a\n  [ "$out" = ok ] || bad\n}\nt_b() {\n  run b\n  [ "$out" = ok ] || bad\n}'
merge_ticket "$d/dup" t1 'test(US-1.AC1): red' tests/t1.sh "$t1" >/dev/null
t2=$'t_a() {\n  run a\n  [ "$out" = ok ] || bad\n}\nt_b() {\n  run b\n}\nt_c() {\n  run c\n}'
m=$(merge_ticket "$d/dup" t2 'test(US-2.AC1): red' tests/t1.sh "$t2")
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$d/dup/docs/work/f/index.md" T02 "$m")
c=$(git -C "$d/dup" rev-parse "$m^2")
grep -qxF "WARN earlier-tests tests/t1.sh: T02 commit ${c:0:8} (red or guard) removed or rewrote lines. Fix: the lead adds \"Ruling <date> (lead): tests/t1.sh may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line." <<<"$out" || bad "AC6 [repeated line] removal of one of two identical lines not flagged: $out"
```

### US-5.AC7
File: skills/build/scripts/test/earlier-tests-block-test.sh (append before the final line)
```bash
lead "$d/sib"; r=$d/sib
printf 'a\nb\nc\nd\ne\nf\n' > "$r/tests/base.sh"; git -C "$r" commit -qam base2; git -C "$r" tag -f base >/dev/null
git -C "$r" checkout -qb t2; printf 'a\nb\nc\nd\ne\nf\nT2\n' > "$r/tests/base.sh"; git -C "$r" commit -qam 'test(US-2.AC1): red'
git -C "$r" checkout -q main
git -C "$r" checkout -qb t1; printf 'T1\na\nb\nc\nd\ne\nf\n' > "$r/tests/base.sh"; git -C "$r" commit -qam 'test(US-1.AC1): red'
git -C "$r" checkout -q main; git -C "$r" merge -q --no-ff t1 -m 'merge t1'
git -C "$r" merge -q --no-ff t2 -m 'merge t2'; m=$(git -C "$r" rev-parse HEAD)
out=$(CHECKS_CONF=$d/w.conf "$wf" done "$r/docs/work/f/index.md" T02 "$m")
! grep -q 'earlier-tests tests/base.sh' <<<"$out" || bad "AC7 [sibling merged first] warned on an add-only red: $out"
```

## Approach

- Compare each red/guard commit's copy of the file with the file at T2's real start: for a merge, `git merge-base "$3^1" "$3^2"`, not `$3^1` (a sibling merged in between is not T2's removal).
- Count repeated lines: a start line is missing when the commit holds fewer copies of it than the start did (e.g. `diff <(sort start) <(sort commit) | grep '^<'`), not when its text is absent everywhere.
- Existing AC6, AC7 and AC9 cases stay green unchanged.

## Constraints

- Spec Decisions: a ruling line `... <path> may change:` still exempts the file.
- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.

## Verify

`bash skills/build/scripts/test/earlier-tests-block-test.sh && bash skills/build/scripts/test/earlier-tests-test.sh && bash skills/build/scripts/test/shipped-modes-test.sh`

## Out of scope

- A later red in one ticket weakening that ticket's own earlier test (US-5 is about later tickets).
- Reordered lines with the same count of each line (not a removal or rewrite).
