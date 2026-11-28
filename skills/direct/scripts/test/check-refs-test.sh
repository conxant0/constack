#!/usr/bin/env bash
# check-refs-test.sh: runs check-refs on copies of the real skills, then on renumbered ones. Exit 1 on any FAIL.
set -u
here=$(cd "$(dirname "$0")/.." && pwd); skills=$(cd "$here/../.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
expect() { # expect <name> <exit> <output>
  local out rc; out=$("$here/check-refs" "$d" 2>&1); rc=$?
  [ "$rc" = "$2" ] && [ "$out" = "$3" ] || { printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$1" "$rc" "$out" "$2" "$3"; fail=1; }
}
fresh() { rm -rf "${d:?}"/*; for s in spec direct; do mkdir -p "$d/$s"; cp "$skills/$s/SKILL.md" "$d/$s/"; done; }

fresh
expect "real skills" 0 ""

fresh; perl -i -pe 's/^3\. \*\*Every AC is testable/3. **Something new/' "$d/spec/SKILL.md"
ln=$(grep -n '^3\. \*\*Something new' "$d/spec/SKILL.md" | cut -d: -f1)
expect "spec rule 3 replaced" 1 "$d/spec/SKILL.md:$ln: item 3 under \"## Hard rules\" no longer starts \"**Every AC is testable\", which $d/direct/SKILL.md cites. Fix: point $d/direct/SKILL.md at the item's new number, or restore it."

fresh; perl -i -pe 's/spec checks:/checks found:/g' "$d/spec/SKILL.md"
ln=$(grep -n '^3\. \*\*Write\*\*' "$d/spec/SKILL.md" | cut -d: -f1)
expect "spec step 3 lost spec checks line" 1 "$d/spec/SKILL.md:$ln: item 3 under \"## Steps\" no longer mentions \"spec checks:\", which $d/direct/SKILL.md relies on. Fix: update $d/direct/SKILL.md to match, or restore it."

fresh; rm "$d/spec/SKILL.md"
expect "missing skill" 2 "$d/spec/SKILL.md: cannot read"

[ $fail = 0 ] && echo "OK check-refs-test"
exit $fail
