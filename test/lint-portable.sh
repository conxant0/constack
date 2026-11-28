#!/usr/bin/env bash
# lint-portable.sh [repo]: fails on shell lines that run on only one of BSD (macOS) and GNU (Linux) sed.
# Scans tracked *.sh files and tracked files that start with #!, skipping whole-line comments.
# Prints <file>:<line>: <problem>. Fix: ..., exit 1 on any.
set -u
root=${1:-$(cd "$(dirname "$0")/.." && pwd)}
S='se[d]' # bracketed so this file does not match its own patterns
# an option cluster ending in i, then a space, an empty quoted suffix or the line end; or --in-place with no =SUFFIX
re="(^|[^[:alnum:]_.-])$S([[:space:]]+-[^[:space:]]+)*[[:space:]]+(-[[:alpha:]]*i(''|\"\")?([[:space:]]|$)|--in-place([[:space:]]|$))"
fix="Fix: give -i a backup suffix and remove it after (\`sed -i.bak '<script>' <file> && rm <file>.bak\`, or sedi in skills/build/scripts/test/lib-fixture.sh); \`sed -i ''\` is BSD only and a bare \`-i\` is GNU only."
fail=0
while IFS= read -r f; do
  [ -f "$root/$f" ] || continue
  case $f in *.sh) ;; *) [ "$(head -c 2 "$root/$f")" = '#!' ] || continue ;; esac
  hits=$(grep -nE "$re" "$root/$f" | grep -vE '^[0-9]+:[[:space:]]*#') || continue
  while IFS= read -r h; do
    echo "$f:${h%%:*}: in-place sed with no backup suffix. $fix"; fail=1
  done <<<"$hits"
done < <(git -C "$root" ls-files)
exit $fail
