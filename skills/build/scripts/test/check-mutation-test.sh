#!/usr/bin/env bash
set -u
PY=${1:-python3}
tool=$(cd "$(dirname "$0")/.." && pwd)/check-mutation
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
cd "$d" && git init -q . && git config user.email t@t && git config user.name t
mkdir -p tests docs/work/x/mutations
cat > calc.py <<'EOF'
GREETING = "Hello there."
LIMIT = 3


def allowed(n):
    """Say whether n may pass."""
    if n < 0:
        return False
    return n <= LIMIT


def hello(name):
    return f"{GREETING} Welcome, {name}."
EOF
cat > tests/test_calc.py <<'EOF'
import os, sys, unittest
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import calc


class T(unittest.TestCase):
    def test_limit(self):
        self.assertTrue(calc.allowed(3))
        self.assertFalse(calc.allowed(4))
EOF
git add -A && git commit -qm base
TESTS="$PY -m unittest discover -s tests"
mkpatch() {
  sed -i '' "$2" calc.py; git diff -- calc.py > "docs/work/x/mutations/$1.diff"; git checkout -q -- calc.py
}
review() {
  printf '# X: final review\n\nVerdict: FAIL\n\n## Acceptance criteria\n\n| AC | Red commit | Test checks the AC | Note |\n|---|---|---|---|\n| US-1.AC1 | abc | yes | |\n| US-1.AC2 | def | no | %s |\n' "$2" > "docs/work/x/$1.md"
}
expect() {
  local out rc; out=$("$tool" "$d/docs/work/x/$4.md" 2>&1); rc=$?
  if [ "$rc" != "$2" ] || [ "$out" != "$3" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$1" "$rc" "$out" "$2" "$3"; fail=1
  fi
  [ -z "$(git status --porcelain)" ] || { printf 'FAIL %s: tree not clean after the run:\n%s\n' "$1" "$(git status --porcelain)"; fail=1; }
}
at() { echo "$d/docs/work/x/$1.md:10: US-1.AC2"; }

mkpatch wording 's/Hello there\./Hi there./;s/may pass/is allowed/;s/Welcome, /Hi, /'
review wording "Mutation: mutations/wording.diff; $TESTS"
review missing "Mutation: mutations/missing.diff; $TESTS"
mkpatch stale 's/^LIMIT = 3/LIMIT = 9/'; sed -i '' 's/^-LIMIT = 3/-LIMIT = 7/' docs/work/x/mutations/stale.diff
review stale "Mutation: mutations/stale.diff; $TESTS"
review nocmd "Mutation: mutations/wording.diff"
git add -A && git commit -qm fixture

expect "AC4: wording-only patch" 1 "$(at wording): the patch mutations/wording.diff changes only wording. Fix: wording is the wording check's job (mutate-copy); grade the row yes." wording
expect "missing patch" 2 "$(at missing): no patch mutations/missing.diff beside the review. Fix: save the production change there with git diff, then re-run." missing
expect "patch that does not apply" 2 "$(at stale): the patch mutations/stale.diff does not apply. Fix: re-make it with git diff against this branch's HEAD, then re-run." stale
expect "Note with no test command" 2 "$(at nocmd): the Note names no test command. Fix: write it as \"Mutation: <patch>; <test command>\"." nocmd
echo '# local' >> calc.py
out=$("$tool" "$d/docs/work/x/wording.md" 2>&1); rc=$?
[ $rc = 2 ] && [ "$out" = "$(at wording): calc.py has uncommitted changes. Fix: commit or stash them, then re-run." ] || { printf 'FAIL dirty file: exit %s, got:\n%s\n' "$rc" "$out"; fail=1; }
git checkout -q -- calc.py

mkpatch caught 's/^LIMIT = 3/LIMIT = 4/'
review caught "Mutation: mutations/caught.diff; $TESTS"
mkpatch missed 's/if n < 0:/if n < -1:/'
review missed "Mutation: mutations/missed.diff; $TESTS"
review pyshape "Mutation: mutations/caught.diff; if ! grep -q '^LIMIT = 3' calc.py; then printf '=== FAILURES ===\n___ test_limit ___\nFAILED tests/test_calc.py::test_limit - AssertionError\n1 failed\n'; exit 1; fi"
review lastline "Mutation: mutations/caught.diff; if ! grep -q '^LIMIT = 3' calc.py; then echo boom; echo last; exit 3; fi"
review broken "Mutation: mutations/missed.diff; echo no such module; exit 1"
git add -A && git commit -qm fixture2
CAUGHT=": the tests already catch this change. Fix: grade the row yes."
out=$("$tool" "$d/docs/work/x/caught.md" 2>&1); rc=$?
case "$out" in "$(at caught): FAIL: test_limit "*"$CAUGHT") ok=$rc ;; *) ok=x ;; esac
[ "$ok" = 1 ] || { printf 'FAIL AC5: a patch the tests catch: exit %s, got:\n%s\n' "$rc" "$out"; fail=1; }
[ -z "$(git status --porcelain)" ] || { printf 'FAIL AC5: tree not clean after the run:\n%s\n' "$(git status --porcelain)"; fail=1; }
expect "AC5: pytest-shaped output names the failing test" 1 "$(at pyshape): FAILED tests/test_calc.py::test_limit - AssertionError$CAUGHT" pyshape
expect "AC5: no FAIL line, the last line" 1 "$(at lastline): last$CAUGHT" lastline
expect "a logic patch the tests miss" 0 "" missed
expect "a command that fails without the patch" 2 "$(at broken): the test command fails before the patch is applied: no such module. Fix: correct the command in the Note so it passes on this branch, then re-run." broken

[ $fail = 0 ] && echo "OK check-mutation-test"
exit $fail
