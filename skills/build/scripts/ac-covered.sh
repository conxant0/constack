ac_uncovered() {
  AC_SUBJECTS=$1 awk '
    BEGIN { n=split(ENVIRON["AC_SUBJECTS"], s, "\n"); for (i=1; i<=n; i++) have[s[i]]=1 }
    /^- US-[0-9]+[.]AC[0-9]+[a-z]?:/ { id=$2; sub(/:$/, "", id)
      if (!(("test(" id "): red") in have) && !(("test(" id "): guard") in have)) { print FNR, id; bad=1 } }
    END { exit bad }' "$2"
}
