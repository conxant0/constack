#!/usr/bin/env bash
# afk-loop-test.sh: drives afk-loop with a fake claude (no tokens). Prints FAIL lines, exit 1 on any.
set -u
s=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
mkdir -p "$d/bin"; printf '#!/bin/sh\n' > "$d/bin/osascript"
# fake claude: /build marks the first runnable ticket done (or does nothing when MODE=stuck,
# blocks it when MODE=block); /final-review FAILs once with a fix ticket, then PASSes.
cat > "$d/bin/claude" <<'C'
#!/usr/bin/env bash
idx=docs/work/x/index.md; wf=$WF
case "$2" in
  "/build"*)
    t=$("$wf" frontier $idx | head -1)
    case "$MODE" in stuck) ;; block) "$wf" set $idx "$t" "blocked: ask-user: q" >/dev/null ;;
      *) "$wf" done $idx "$t" "$(git rev-parse HEAD)" >/dev/null ;; esac ;;
  "/final-review"*)
    if grep -q F01 $idx; then echo "Verdict: PASS" > docs/work/x/review.md
    else echo "Verdict: FAIL" > docs/work/x/review.md
      sed -i '' 's/^| T02 .*/&\n| F01 | fix | none | todo |/' $idx; fi
    git add -A; git commit -qm review ;;
esac
echo '{"result":"ok","session_id":"none"}'
C
chmod +x "$d/bin/"*
repo() { # fresh repo with a 2-ticket index
  rm -rf "$d/r"; mkdir -p "$d/r/docs/work/x"; cd "$d/r"; git init -q
  echo spec > docs/work/x/spec.md
  printf '# X\n\nBranch: b\nBase: origin/staging\nTest command: `true`\n\n| Ticket | Title | Blocked by | Status |\n|---|---|---|---|\n| T01 | a | none | todo |\n| T02 | b | T01 | todo |\n\n## Rulings\n' > docs/work/x/index.md
  git add -A; git commit -qm init
}
check() { # check <name> <want exit> <want output substring> <MODE>
  repo; out=$(MODE=$4 WF=$s/wf PATH=$d/bin:$PATH HOME=$d "$s/afk-loop" docs/work/x/index.md 2>&1); rc=$?
  if [ $rc != "$2" ] || ! grep -qF "$3" <<<"$out"; then printf 'FAIL %s: exit %s\n%s\n' "$1" $rc "$out"; fail=1; fi
}
check "fail then pass" 0 "afk-loop: PASS" ok
check "blocked stops"  1 "afk-loop: blocked, run /unblock: T01 blocked: ask-user: q" block
check "unblock cmd"    1 "/unblock $d/r/docs/work/x/index.md\"" block
check "stuck stops"    1 "afk-loop: build made no progress" stuck
[ $fail = 0 ] && echo "afk-loop: all tests pass"; exit $fail
