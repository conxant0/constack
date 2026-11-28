#!/usr/bin/env bash
# lint-portable-test.sh: runs lint-portable.sh on a throwaway repo with one bad line per form. Prints FAIL lines, exit 1 on any.
set -u
lint=$(cd "$(dirname "$0")" && pwd)/lint-portable.sh
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
S=sed # the forms are built at run time so this file does not trip the lint itself
fix="Fix: give -i a backup suffix and remove it after (\`$S -i.bak '<script>' <file> && rm <file>.bak\`, or sedi in skills/build/scripts/test/lib-fixture.sh); \`$S -i ''\` is BSD only and a bare \`-i\` is GNU only."
r=$d/r; mkdir -p "$r/skills/x/scripts" "$r/test"; git -C "$r" init -q
printf '#!/bin/sh\n%s -i %s s/a/b/ f\n' "$S" "''" > "$r/skills/x/scripts/a.sh"
printf '#!/usr/bin/env bash\necho ok\n  %s -i "s/a/b/" f\n' "$S" > "$r/skills/x/scripts/tool"
printf 'x=1; %s -Ei "s/a/b/" f\n%s --in-place "s/a/b/" f\n%s -n -i"" "s/a/b/" f\n' "$S" "$S" "$S" > "$r/test/b.sh"
printf '%s -i.bak "s/a/b/" f && rm f.bak\n# %s -i %s in a comment line\nsedi "s/a/b/" f\nused -i x\n' "$S" "$S" "''" > "$r/test/ok.sh"
printf '%s -i %s s/a/b/ f\n' "$S" "''" > "$r/notes.md"
printf 'no shebang\n%s -i s/a/b/ f\n' "$S" > "$r/skills/x/scripts/data"
git -C "$r" add -A
out=$("$lint" "$r" 2>&1); rc=$?
want="skills/x/scripts/a.sh:2: in-place $S with no backup suffix. $fix
skills/x/scripts/tool:3: in-place $S with no backup suffix. $fix
test/b.sh:1: in-place $S with no backup suffix. $fix
test/b.sh:2: in-place $S with no backup suffix. $fix
test/b.sh:3: in-place $S with no backup suffix. $fix"
[ $rc = 1 ] || { echo "FAIL bad forms: exit $rc, want 1"; fail=1; }
[ "$out" = "$want" ] || { printf 'FAIL bad forms: got:\n%s\nwant:\n%s\n' "$out" "$want"; fail=1; }
git -C "$r" rm -q --cached skills/x/scripts/a.sh skills/x/scripts/tool test/b.sh
out=$("$lint" "$r" 2>&1); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || { printf 'FAIL clean repo: exit %s, got:\n%s\n' "$rc" "$out"; fail=1; }
out=$("$lint" 2>&1); rc=$?
[ $rc = 0 ] || { printf 'FAIL this repo: exit %s\n%s\n' "$rc" "$out"; fail=1; }
[ $fail = 0 ] && echo "OK lint-portable-test"; exit $fail
