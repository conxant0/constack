#!/usr/bin/env bash
set -u
root=$(cd "$(dirname "$0")/../../../.." && pwd)
q=quick
needle="/$q"
fail=0
hits=$(cd "$root" && grep -rnF -- "$needle" skills README.md CLAUDE.md install.sh 2>/dev/null)
if [ -n "$hits" ]; then
  printf '%s\n' "$hits"
  echo "Fix: remove each mention of $needle above, or name /direct \"<one-line task>\" instead."
  fail=1
fi
if [ -e "$root/skills/$q" ]; then
  echo "skills/$q: still exists"
  echo "Fix: git rm -r skills/$q; /direct \"<one-line task>\" replaces it."
  fail=1
fi
[ $fail = 0 ] && echo "OK no-quick-test"
exit $fail
