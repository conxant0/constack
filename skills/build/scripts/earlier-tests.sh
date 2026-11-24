earlier_tests() { # <index.md> <id> <merge sha>: warn when the ticket changed an earlier ticket's or Base's test file outside a red or guard commit
  local dir base b s p c f msg seen=
  dir=$(dirname "$1")
  base=$(base_ref "$1")
  [ -n "$base" ] && git -C "$dir" rev-parse -q --verify "$base^{commit}" >/dev/null || return 0
  b=$(git -C "$dir" merge-base "$base" "$3") || return 0
  if git -C "$dir" rev-parse -q --verify "$3^2" >/dev/null; then
    s=$(git -C "$dir" rev-parse "$3^1")
  else
    s=$(git -C "$dir" log --format='%H%x09%s' "$3" | awk -F'\t' -v d="docs(build): $2 doing" '$2 == d { print $1; exit }')
    [ -n "$s" ] || s=$b
  fi
  p=$(for c in $(git -C "$dir" log --format='%H%x09%s' "$b..$s" | awk -F'\t' '$2 ~ /^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$/ { print $1 }'); do
    git -C "$dir" diff-tree --no-commit-id --name-only --no-renames -r "$c"
  done)
  for c in $(git -C "$dir" log --no-merges --reverse --format='%H%x09%s' "$s..$3" | awk -F'\t' '$2 !~ /^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$/ { print $1 }'); do
    while IFS= read -r f; do
      printf '%s\n' "$p" | grep -qxF -- "$f" || continue
      printf '%s\n' "$seen" | grep -qxF -- "$f" && continue
      seen=$(printf '%s\n%s' "$seen" "$f")
      msg="$f: $2 commit ${c:0:8} changed it outside a red or guard commit"
      echo "WARN earlier-tests $msg. Fix: the lead adds \"Ruling <date> (lead): $f may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line."
      "$0" warn-log "$dir" earlier-tests "$2" "$msg"
    done < <(git -C "$dir" diff-tree --no-commit-id --numstat --no-renames -r "$c" | cut -f3-)
  done
}
