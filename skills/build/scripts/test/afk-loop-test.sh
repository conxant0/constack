#!/usr/bin/env bash
# afk-loop-test.sh: drives afk-loop with a fake claude (no tokens). Prints FAIL lines, exit 1 on any.
set -u
unset HERDR_ENV HERDR_PANE_ID  # run inside herdr, afk-loop would report to the real pane
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
# inside herdr, each session reports working plus a $step token; outside herdr nothing is sent; a failing herdr never stops the loop
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$HERDR_CALLS"; exit ${HERDR_EXIT:-0}\n' > "$d/bin/herdr"; chmod +x "$d/bin/herdr"
export HERDR_CALLS=$d/herdr-calls; rm -f "$HERDR_CALLS"
HERDR_ENV=1 HERDR_PANE_ID=w9:p1 check "herdr steps" 0 "afk-loop: PASS" ok
grep -q -- '^pane report-agent w9:p1 --source afk-loop --agent claude --seq [0-9]\{19\} --state working$' "$HERDR_CALLS" ||
  { echo "FAIL no working report with a ns seq: $(head -1 "$HERDR_CALLS"). Fix: herdr_step in afk-loop must call report-agent with --seq time_ns"; fail=1; }
steps=$(sed -n 's/^pane report-metadata w9:p1 --source afk-loop --token step=//p' "$HERDR_CALLS" | tr '\n' ',')
[ "$steps" = "[1] /build,[2] /build,[3] /encode-comments,[4] /final-review,[5] /build,[6] /encode-comments,[7] /final-review," ] ||
  { echo "FAIL step tokens: $steps. Fix: run() in afk-loop must call herdr_step \"[\$n] <command>\" once per session"; fail=1; }
rm -f "$HERDR_CALLS"; check "no herdr outside it" 0 "afk-loop: PASS" ok
[ -e "$HERDR_CALLS" ] && { echo "FAIL herdr called without HERDR_ENV=1. Fix: herdr_step must return early unless HERDR_ENV=1 and HERDR_PANE_ID are set"; fail=1; }
HERDR_EXIT=1 HERDR_ENV=1 HERDR_PANE_ID=w9:p1 check "failing herdr" 0 "afk-loop: PASS" ok
rm -f "$d/bin/herdr"
[ $fail = 0 ] && echo "afk-loop: all tests pass"; exit $fail
