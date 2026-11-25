# T00 One shared test-file regex, and an empty earlier-tests hook in wf done

Spec: docs/work/workflow-speed/spec.md
Blocked by: none

## Delivers

none (prefactor: no behaviour change, existing tests stay green)

## Files

- create: skills/build/scripts/test-re.sh
- create: skills/build/scripts/earlier-tests.sh
- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/scripts/wf

## Interfaces

- Consumes: `test_re` (the regex string) from skills/build/scripts/check-red-green.sh
- Produces: `test_re='<the same regex, character for character>'` in skills/build/scripts/test-re.sh, a file meant to be sourced (no shebang needed, not executable)
- Produces: `earlier_tests <index.md> <id> <merge sha>` in skills/build/scripts/earlier-tests.sh (sourced by wf, not executable): a function that does nothing and returns 0 (today's behaviour). The `done)` case in wf calls it after the sha check and before `set_status`: `earlier_tests "$1" "$2" "$sha" || exit 1`. T09 and T10 fill in its body; they never edit wf.

## Tests

none (prefactor). The existing suite proves it: `bash skills/build/scripts/test/check-red-green-test.sh python3` and `bash skills/build/scripts/test/wf-test.sh` stay green.

## Approach

- Move the `test_re=...` assignment and its comment line from check-red-green.sh into test-re.sh unchanged.
- check-red-green.sh: `. "$(cd "$(dirname "$0")" && pwd)/test-re.sh"` before its first use of `test_re` (before the `cd "$wt"`).
- wf: source test-re.sh the same way near the top (after `set -u`), and replace the inline copy of the regex inside `check_review()` (the `grep -vE '\.md$|(^|/)docs/|(^|/)(tests?|...)...'` pipeline) with `grep -vE "\.md\$|(^|/)docs/|$test_re"`, so the filtered set is identical.
- `size()` keeps its `*test*` glob (out of scope).
- earlier-tests.sh holds only `earlier_tests() { return 0; }`. wf sources it next to test-re.sh. This hook exists so the earlier-tests tickets (T09, T10) do not share wf with T04 and T05, which would chain them.

## Constraints

- Project CLAUDE.md "Code rules": no behaviour change in a prefactor; existing tests stay green.
- macOS bash 3.2: no `mapfile`, no `flock`; tests use `sed -i ''` (code map).

## Verify

`bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Any new check, line or argument (T01 onward); any body for `earlier_tests` (T09, T10).
- Changing what counts as a test file.
- `size()` in wf.
