# F06 The wording check runs when Verify names python through a command substitution

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Behaviour finding 1 (check-red-green.sh:42 takes `--git-common-dir)/../venv/bin/python3` as the interpreter, so the wording command is a shell syntax error and the lead gets a false could-not-run warning)

## Delivers

- US-3.AC4: Given a ticket whose Verify names its Python interpreter through a command substitution, either directly (`"$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" -m pytest ...`) or through a variable (`PY="$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" && $PY -m pytest ...`), and that adds a sentence its red and guard tests do not check, when the red-green check runs with that ticket, then for each form it prints the SURVIVED warning naming that sentence and no could-not-run line.

## Files

- modify: skills/build/scripts/check-red-green.sh
- test: skills/build/scripts/test/wording-test.sh

## Interfaces

- Consumes: `pytest_cmd <extra flags> <test file list>` in skills/build/scripts/check-red-green.sh (line 42 picks the interpreter out of `$verify` with `grep -oE '[^ ]*/python3?'`); `pyrepo`, `fx_ticket` from skills/build/scripts/test/lib-py.sh and lib-fixture.sh
- Produces: `pytest_cmd` prints a command whose interpreter runs in a shell for both Verify forms; its output for a plain path (`../../venv/bin/python3`, `/abs/venv/bin/python3`) is unchanged

## Tests

### US-3.AC4
File: skills/build/scripts/test/wording-test.sh (append before the final line)
```bash
real=$(command -v "$py")
for form in direct variable; do
  pyrepo "$d/r8-$form" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' $'X = 2\nMSG = "Keep it short."\n'
  mkdir -p "$d/r8-$form/venv/bin"; ln -s "$real" "$d/r8-$form/venv/bin/python3"
  sub='"$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3"'
  if [ $form = direct ]; then V8="cd pkg && $sub -m pytest -q -p no:cacheprovider"
  else V8="cd pkg && PY=$sub && \$PY -m pytest -q -p no:cacheprovider"; fi
  fx_ticket "$d/f8-$form/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$("$s/check-red-green.sh" "$d/r8-$form" "$base" "$V8" "$d/f8-$form/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "AC4 [$form] exit $rc: $out"
  grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED Keep it short\.\. Fix: ' <<<"$out" || bad "AC4 [$form] no SURVIVED line: $out"
  ! grep -q 'could not run' <<<"$out" || bad "AC4 [$form] printed could-not-run: $out"
done
```
`venv/` is untracked in the fixture; if the check's clean-tree test (tracked files only) or mutate-copy objects, add `venv/` to the fixture's `.git/info/exclude`, not to the assertions.

## Approach

- The lead leaves the fix open: either reuse the interpreter expression exactly as the Verify writes it (quotes and substitution kept, a `$PY` assignment carried along), or resolve it once to a real path before building the command. A plain path must print the same command as today (wording-test.sh AC1 and AC2 cases stay green).
- The red commit's own run (`narrowed`, same `pytest_cmd`) is fixed by the same change; no extra AC for it.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Existing assertions in wording-test.sh stay as they are; this ticket only appends.

## Verify

`bash skills/build/scripts/test/wording-test.sh python3 && bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/shipped-modes-test.sh python3`

## Out of scope

- Interpreter forms other than the two in the AC.
- The other Behaviour notes in review.md.
