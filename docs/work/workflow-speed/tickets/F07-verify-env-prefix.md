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
File: skills/build/scripts/test/wording-test.sh (append before the final line, after the US-3.AC4 block, reusing its `real` and `sub`)

The three forms, each with a fixture whose code reads the prefix:
- `env -u TOKEN $sub`: run the check with `TOKEN=1` exported; msg.py sets `X = 2 if "TOKEN" not in os.environ else 3`.
- `DEV_MODE=true $sub`: msg.py sets `X = 2 if os.environ.get("DEV_MODE") == "true" else 3`.
- `PY=$sub && DEV_MODE=true OTHER=1 \$PY`: msg.py sets X from both `DEV_MODE` and `OTHER`.

For each form:
1. (a) Red commit plus a green that adds `MSG = "Keep it short."` with X right under the prefix, ticket T01. Run `check-red-green.sh <repo> <base> "$V" <ticket>`. Assert rc 0, a line matching `^WARN wording pkg/msg.py:MSG: SURVIVED Keep it short\.\. Fix: `, and no `could not run`.
2. (b) A repo where msg.py already has the prefix-dependent X. Add one guard commit `test(US-1.AC2): guard` whose test asserts `msg.X == 2`. Its body carries a fenced Mutation diff that breaks X, committed with `--cleanup=verbatim`. Run the check over `<base>..guard` with the same `$V`. Assert rc 0, a line starting `OK   guard US-1.AC2`, and no `FAIL guard`.
3. Before the fix, every form must fail (a) or (b). Reproduced by the review probe: `bash $TMPDIR/fr-71220/beh/probe.sh <scripts dir>` blocks 1a, 1b, 1c.

`venv/` stays untracked: add it to each fixture's `.git/info/exclude`.

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
