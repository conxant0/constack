#!/usr/bin/env bash
# afk-loop-test.sh: drives afk-loop with a fake claude (no tokens). Prints FAIL lines, exit 1 on any.
set -u
s=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
mkdir -p "$d/bin"; printf '#!/bin/sh\n' > "$d/bin/osascript"
# fake claude: /build marks the first runnable ticket done (or does nothing when MODE=stuck,
# blocks it when MODE=block); /final-review FAILs once with a fix ticket, then PASSes
# (MODE=badpass: a PASS whose OPEN is not none, which wf check-review rejects).
cat > "$d/bin/claude" <<'C'
#!/usr/bin/env bash
idx=docs/work/x/index.md; wf=$WF
printf '%s\n' "$*" >> "$CALLS"
case "$2" in
  "/build"*)
    t=$("$wf" frontier $idx | head -1)
    case "$MODE" in stuck) ;; block) "$wf" set $idx "$t" "blocked: ask-user: q" >/dev/null ;;
      *) "$wf" done $idx "$t" "$(git rev-parse HEAD)" >/dev/null ;; esac ;;
  "/final-review"*)
    pass=$(printf 'Verdict: PASS\nSpec: docs/work/x/spec.md\nRange: origin/main...%s\n\n## OPEN\n\nnone\n' "$(git rev-parse HEAD)")
    if [ "$MODE" = badpass ]; then printf '%s\n' "$pass" | sed 's/^none$/q?/' > docs/work/x/review.md
    elif grep -q F01 $idx; then printf '%s\n' "$pass" > docs/work/x/review.md
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
  printf '# X\n\nBranch: b\nBase: origin/main\nTest command: `true`\n\n| Ticket | Title | Blocked by | Status |\n|---|---|---|---|\n| T01 | a | none | todo |\n| T02 | b | T01 | todo |\n\n## Rulings\n' > docs/work/x/index.md
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
check "bad PASS stops" 1 "afk-loop: review.md says PASS but wf check-review disagrees: docs/work/x/review.md:7: OPEN is not none" badpass
# every headless session gets AskUserQuestion removed; /encode-comments <Base> AFK runs right before each /final-review
export CALLS=$d/calls; rm -f "$CALLS"; check "calls logged" 0 "afk-loop: PASS" ok
grep -v -q -- '--disallowedTools.*AskUserQuestion' "$CALLS" && { echo "FAIL a session ran without AskUserQuestion disallowed"; fail=1; }
order=$(sed -E 's#^-p (/[a-z-]+).*#\1#' "$CALLS" | grep -v '^/build' | tr '\n' ' ')
[ "$order" = "/encode-comments /final-review /encode-comments /final-review " ] || { echo "FAIL session order: $order"; fail=1; }
grep -q -- '-p /encode-comments origin/main AFK' "$CALLS" || { echo "FAIL encode-comments not given the index Base"; fail=1; }
grep -q -- '--disallowedTools AskUserQuestion --output-format' "$CALLS" || { echo "FAIL no overlay file: want only AskUserQuestion disallowed"; fail=1; }
# ~/.claude/checks/afk-disallowed-tools adds tools, one per line; comments and blank lines skipped
mkdir -p "$d/.claude/checks"; printf '# paid\nmcp__paid-a\n\nmcp__paid-b  # by hand\n' > "$d/.claude/checks/afk-disallowed-tools"
rm -f "$CALLS"; check "overlay tools" 0 "afk-loop: PASS" ok
grep -v -q -- '--disallowedTools mcp__paid-a mcp__paid-b AskUserQuestion --output-format' "$CALLS" && { echo "FAIL a session ran without the overlay tools disallowed: $(head -1 "$CALLS")"; fail=1; }
rm -f "$d/.claude/checks/afk-disallowed-tools"
repo; printf '\n## Parts\n\n- T01: US-1.AC1; files: a.sh\n- T02: US-1.AC2; files: b.sh\n' >> docs/work/x/index.md; git commit -qam parts
rm -f "$CALLS"; MODE=stuck WF=$s/wf PATH=$d/bin:$PATH HOME=$d "$s/afk-loop" docs/work/x/index.md >/dev/null 2>&1
first=$(head -1 "$CALLS" 2>/dev/null)
case $first in "-p /direct docs/work/x/spec.md AFK "*) ;; *) echo "FAIL US-5.AC1 first session: $first"; fail=1 ;; esac
! grep -q -- '-p /build' "$CALLS" 2>/dev/null || { echo "FAIL US-5.AC1 started a ticket build: $(grep -- '-p /build' "$CALLS" | head -1)"; fail=1; }
repo; printf '\n## Parts\n\n- T01: US-1.AC1; files: a.sh\n- T02: US-1.AC2; files: b.sh\n' >> docs/work/x/index.md
mkdir docs/work/x/tickets; echo t > docs/work/x/tickets/T01-a.md; git add -A; git commit -qm 'parts and tickets'
rm -f "$CALLS"; MODE=stuck WF=$s/wf PATH=$d/bin:$PATH HOME=$d "$s/afk-loop" docs/work/x/index.md >/dev/null 2>&1
first=$(head -1 "$CALLS" 2>/dev/null)
case $first in "-p /build docs/work/x/index.md AFK "*) ;; *) echo "FAIL parts index with a tickets folder, first session: $first"; fail=1 ;; esac
[ $fail = 0 ] && echo "afk-loop: all tests pass"; exit $fail
