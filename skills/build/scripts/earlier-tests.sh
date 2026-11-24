earlier_tests() {
  local dir base b s p c f msg ok kind add del md seen= red_re='^test\\(US-[0-9]+\\.AC[0-9]+[a-z]?\\): (red|guard)$'
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
  p=$(for c in $(git -C "$dir" log --format='%H%x09%s' "$b..$s" | awk -F'\t' -v re="$red_re" '$2 ~ re { print $1 }'); do
    git -C "$dir" diff-tree --no-commit-id --name-only --no-renames -r "$c"
  done
  git -C "$dir" ls-tree -r --full-tree --name-only "$b" | grep -E "$test_re")
  md=$(mode earlier-tests) || { echo "$md"; return 1; }
  ok=$({ cat "$dir/tickets/$2"-*.md 2>/dev/null
    awk -v id="$2" '/^## Rulings/ { r=1; next } /^## / { r=0 } r && $1 == "-" && $2 ~ /,$/ && $3 == id' "$1"
  } | awk '/may change:/ { sub(/may change:.*/, ""); gsub(/`/, ""); for (i=1; i<=NF; i++) print $i }')
  for c in $(git -C "$dir" log --no-merges --reverse --format='%H%x09%s' "$s..$3" | awk -F'\t' -v re="$red_re" '{ print $1 ($2 ~ re ? ":red" : ":other") }'); do
    kind=${c#*:}; c=${c%:*}
    while IFS=$'\t' read -r add del f; do
      printf '%s\n' "$p" | grep -qxF -- "$f" || continue
      [ $kind = other ] || [ "$del" != 0 ] || ! git -C "$dir" cat-file -e "$c:$f" 2>/dev/null || continue
      printf '%s\n' "$seen" "$ok" | grep -qxF -- "$f" && continue
      seen=$(printf '%s\n%s' "$seen" "$f")
      if [ $kind = other ]; then msg="$f: $2 commit ${c:0:8} changed it outside a red or guard commit"
      else msg="$f: $2 commit ${c:0:8} (red or guard) removed or rewrote lines"; fi
      if [ $md = block ]; then
        echo "FAIL earlier-tests $msg. Fix: undo the merge (git reset --hard ${3:0:8}^1), wf set $1 $2 \"blocked: earlier tests: $f\", and send this line to the implementer."
        continue
      fi
      echo "WARN earlier-tests $msg. Fix: the lead adds \"Ruling <date> (lead): $f may change: <what>\" to the ticket if build rule 8 allows the change; otherwise final review grades this line."
      "$0" warn-log "$dir" earlier-tests "$2" "$msg"
    done < <(git -C "$dir" diff-tree --no-commit-id --numstat --no-renames -r "$c")
  done
  [ $md = warn ] || [ -z "$seen" ]
}
