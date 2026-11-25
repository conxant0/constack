# F07 The red-green check keeps the Verify's environment prefix

Spec: docs/work/workflow-speed/spec.md
Blocked by: none
Fixes: review.md Behaviour finding 1. check-red-green.sh:43 `pytest_cmd` builds `cd <root> && <py> -m pytest` and drops an `env -u NAME` or `NAME=value` prefix the Verify puts before its interpreter. The wording check then prints a false could-not-run warning, and a guard that passes its Verify gets `FAIL guard`.

## Delivers

- US-3.AC5: Given a ticket whose Verify runs its Python interpreter behind one or more environment prefix words, in any of three forms (`env -u NAME "$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" -m pytest ...`, `NAME=value "$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" -m pytest ...`, or `PY="$(git rev-parse --path-format=absolute --git-common-dir)/../venv/bin/python3" && NAME=value OTHER=value $PY -m pytest ...`), and whose tests pass only with that prefix, when the red-green check runs with that ticket, then for each form (a) a ticket that adds a sentence its red and guard tests do not check gets the SURVIVED warning naming that sentence and no could-not-run line, and (b) a range holding a guard commit whose test passes under the Verify gets an `OK   guard` line for that commit, no `FAIL guard` line, and exit status 0.

## Files

- modify: skills/build/scripts/check-red-green.sh
- test: skills/build/scripts/test/wording-test.sh

## Interfaces

- Consumes: `pytest_cmd <extra flags> <test file list>` in skills/build/scripts/check-red-green.sh (line 42 picks the interpreter out of `$verify`; F06 made it keep a quoted `"$(...)/python3"`); `pyrepo` from skills/build/scripts/test/lib-py.sh, `fx_ticket` from lib-fixture.sh
- Produces: `pytest_cmd` prints a command that runs the interpreter with the same prefix words the Verify gives it. For a Verify with no prefix, its output is unchanged.

## Tests

### US-3.AC5
File: skills/build/scripts/test/wording-test.sh (append before the final line, after the US-3.AC4 block; reuses its `real` and `sub`)
```bash
for form in envu assign pyvar; do
  case $form in
    envu)   V9="cd pkg && env -u TOKEN $sub -m pytest -q -p no:cacheprovider"
            x='X = 2 if "TOKEN" not in os.environ else 3' ;;
    assign) V9="cd pkg && DEV_MODE=true $sub -m pytest -q -p no:cacheprovider"
            x='X = 2 if os.environ.get("DEV_MODE") == "true" else 3' ;;
    pyvar)  V9="cd pkg && PY=$sub && DEV_MODE=true OTHER=1 \$PY -m pytest -q -p no:cacheprovider"
            x='X = 2 if os.environ.get("DEV_MODE") == "true" and os.environ.get("OTHER") == "1" else 3' ;;
  esac
  pyrepo "$d/r9-$form" pkg/tests/test_msg.py $'def test_x():\n    assert msg.X == 2\n' "import os
$x
MSG = \"Keep it short.\"
"
  mkdir -p "$d/r9-$form/venv/bin"; ln -s "$real" "$d/r9-$form/venv/bin/python3"; echo venv/ >> "$d/r9-$form/.git/info/exclude"
  fx_ticket "$d/f9-$form/tickets/T01-w.md" '- US-1.AC1: Given a, when b, then c'
  out=$(TOKEN=1 "$s/check-red-green.sh" "$d/r9-$form" "$base" "$V9" "$d/f9-$form/tickets/T01-w.md"); rc=$?
  [ $rc = 0 ] || bad "US-3.AC5 [$form] wording exit $rc: $out"
  grep -q '^WARN wording pkg/msg.py:MSG: SURVIVED Keep it short\.\. Fix: ' <<<"$out" || bad "US-3.AC5 [$form] no SURVIVED line: $out"
  ! grep -q 'could not run' <<<"$out" || bad "US-3.AC5 [$form] printed could-not-run: $out"

  g=$d/r9-$form; gb=$(git -C "$g" rev-parse HEAD)
  printf 'import os, sys\nsys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nimport msg\ndef test_g():\n    assert msg.X == 2\n' > "$g/pkg/tests/test_guard.py"
  sed -i.bak 's/^X = .*/X = 0/' "$g/pkg/msg.py"; rm "$g/pkg/msg.py.bak"
  patch=$(git -C "$g" diff -- pkg/msg.py); git -C "$g" checkout -q -- pkg/msg.py
  git -C "$g" add -A
  printf 'test(US-1.AC2): guard\n\nMutation: pkg/msg.py X -> 0 -> test_g fails\n\n```diff\n%s\n```\n' "$patch" | git -C "$g" commit -q --cleanup=verbatim -F -
  out=$(TOKEN=1 "$s/check-red-green.sh" "$g" "$gb" "$V9"); rc=$?
  [ $rc = 0 ] || bad "US-3.AC5 [$form] guard exit $rc: $out"
  grep -q '^OK   guard US-1.AC2 ' <<<"$out" || bad "US-3.AC5 [$form] no OK guard line: $out"
  ! grep -q '^FAIL guard' <<<"$out" || bad "US-3.AC5 [$form] printed FAIL guard: $out"
done
```
Measured by the review: appended to wording-test.sh at 72be583, every form fails both parts (could-not-run instead of SURVIVED; `FAIL guard ... assert 3 == 2`, exit 1). The same block with a no-prefix Verify and `X = 2` passes, so the fixture's guard patch applies and bites.

## Approach

- The lead leaves the fix open. Either keep the words between the last `&&` or `;` and the interpreter, or carry the Verify's prefix assignments into the built command. Without a prefix, the built command must stay the same, so the US-3.AC1, AC2 and AC4 cases in wording-test.sh stay green.
- `narrowed` and `wording` both use `pytest_cmd`, so one change fixes both.

## Constraints

- Project CLAUDE.md: every check prints a `Fix:`; the check's own test asserts the `Fix:` text.
- Existing assertions in wording-test.sh stay as they are; this ticket only appends.

## Verify

`bash skills/build/scripts/test/wording-test.sh python3 && bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/guard-patch-test.sh python3 && bash skills/build/scripts/test/shipped-modes-test.sh python3`

## Out of scope

- Bare `python`, nested substitutions and `"$VAR/bin/python3"` (review.md Behaviour notes, older than the branch).
