#!/usr/bin/env bash
# mutate-copy-test.sh [python]: probes mutate-copy on a throwaway repo. Prints "ok" or the first failure.
set -u
PY=${1:-python3}
TOOL="$(cd "$(dirname "$0")/.." && pwd)/mutate-copy"
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
cd "$dir" && git init -q . && git config user.email t@t && git config user.name t

cat > copy.py <<'EOF'
PRICE = ("Costs 1 token per row. "
         "Totals are rounded.")
BUILT = PRICE + " More."
EOF
cat > check.py <<'EOF'
import copy, sys
sys.exit(0 if "1 token" in copy.PRICE else 1)
EOF
git add -A && git commit -qm base
before=$(shasum copy.py)

fail() { echo "FAIL: $*"; exit 1; }

out=$("$PY" "$TOOL" copy.py -- "$PY" check.py); rc=$?
[ $rc -eq 1 ] || fail "want exit 1 with a survivor, got $rc: $out"
echo "$out" | grep -q '^KILLED   copy.py:PRICE: Costs 1 token per row.$' || fail "tested sentence not KILLED: $out"
echo "$out" | grep -q '^SURVIVED copy.py:PRICE: Totals are rounded.$' || fail "untested sentence not SURVIVED: $out"
echo "$out" | grep -q '^SKIPPED  copy.py:BUILT' || fail "built constant not SKIPPED: $out"
echo "$out" | grep -q '^2 sentences: 1 killed, 1 survived, 1 constants skipped$' || fail "counts: $out"
[ "$(shasum copy.py)" = "$before" ] || fail "copy.py not restored"

# --base: only the sentence added since the base commit is checked
sed -i.bak 's/Totals are rounded\./Totals are rounded. Ask before a paid step./' copy.py && rm copy.py.bak
git commit -qam "add a sentence"
out=$("$PY" "$TOOL" --base HEAD~1 copy.py -- "$PY" check.py); rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q '^1 sentences: 0 killed, 1 survived' || fail "--base: $rc: $out"
out=$("$PY" "$TOOL" --base HEAD copy.py -- "$PY" check.py); rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '^0 sentences to check' || fail "--base HEAD should check nothing: $rc: $out"

# a test command that fails before any edit is exit 2, never a pile of KILLED lines
out=$("$PY" "$TOOL" copy.py -- "$PY" -c 'raise SystemExit(1)'); rc=$?
[ $rc -eq 2 ] || fail "failing baseline should exit 2, got $rc: $out"

# a test that pins the exact text (a snapshot) is exit 2, never 100% KILLED
cat > exact.py <<'EOF2'
import copy, hashlib, sys
sys.exit(0 if hashlib.md5(copy.PRICE.encode()).hexdigest() == sys.argv[1] else 1)
EOF2
sum=$("$PY" -c 'import copy, hashlib; print(hashlib.md5(copy.PRICE.encode()).hexdigest())')
out=$("$PY" "$TOOL" copy.py -- "$PY" exact.py "$sum"); rc=$?
[ $rc -eq 2 ] && echo "$out" | grep -q 'becomes a tab' || fail "snapshot in the command should exit 2, got $rc: $out"
[ -z "$(git status --porcelain copy.py)" ] || fail "copy.py not restored after the probe"

# an uncommitted file is refused
echo "X = 'a.'" >> copy.py
out=$("$PY" "$TOOL" copy.py -- "$PY" check.py); rc=$?
[ $rc -eq 2 ] || fail "dirty file should exit 2, got $rc: $out"
echo ok
