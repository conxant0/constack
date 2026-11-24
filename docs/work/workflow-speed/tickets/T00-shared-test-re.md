# T00 One shared test-file regex

Spec: docs/work/workflow-speed/spec.md
Blocked by: none

## Delivers

none (prefactor: no behaviour change, existing tests stay green)

## Files

- create: skills/build/scripts/test-re.sh
- modify: skills/build/scripts/check-red-green.sh
- modify: skills/build/scripts/wf

## Interfaces

- Consumes: `test_re` (the regex string) from skills/build/scripts/check-red-green.sh
- Produces: `test_re='<the same regex, character for character>'` in skills/build/scripts/test-re.sh, a file meant to be sourced (no shebang needed, not executable)

## Tests

none (prefactor). The existing suite proves it: `bash skills/build/scripts/test/check-red-green-test.sh python3` and `bash skills/build/scripts/test/wf-test.sh` stay green.

## Approach

- Move the `test_re=...` assignment and its comment line from check-red-green.sh into test-re.sh unchanged.
- check-red-green.sh: `. "$(cd "$(dirname "$0")" && pwd)/test-re.sh"` before its first use of `test_re` (before the `cd "$wt"`).
- wf: source test-re.sh the same way near the top (after `set -u`), and replace the inline copy of the regex inside `check_review()` (the `grep -vE '\.md$|(^|/)docs/|(^|/)(tests?|...)...'` pipeline) with `grep -vE "\.md\$|(^|/)docs/|$test_re"`, so the filtered set is identical.
- `size()` keeps its `*test*` glob (out of scope).

## Constraints

- Project CLAUDE.md "Code rules": no behaviour change in a prefactor; existing tests stay green.
- macOS bash 3.2: no `mapfile`, no `flock`; tests use `sed -i ''` (code map).

## Verify

`bash skills/build/scripts/test/check-red-green-test.sh python3 && bash skills/build/scripts/test/wf-test.sh`

## Out of scope

- Any new check, line or argument (T01 onward).
- Changing what counts as a test file.
- `size()` in wf.
