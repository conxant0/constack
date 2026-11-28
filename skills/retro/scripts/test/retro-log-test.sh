#!/usr/bin/env bash
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
export CLAUDE_CONFIG_DIR=$d/cfg
wt=$d/work/feat
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
proj=$CLAUDE_CONFIG_DIR/projects
err() { printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"t","is_error":true,"content":"%s"}]}}\n' "$2" "$3" >> "$1"; }
typed() { printf '{"type":"user","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' "$2" "$3" >> "$1"; }
section() { awk -v h="## $2" '/^## /{on=($0==h); next} on' <<<"$1"; }
check() { [ "$2" = "$3" ] || { printf 'FAIL %s: got:\n%s\nwant:\n%s\n' "$1" "$2" "$3"; fail=1; }; }
fresh() { rm -rf "$CLAUDE_CONFIG_DIR"; main=$proj/$(enc "$wt"); mkdir -p "$main"; }

sid=11111111-2222-3333-4444-555555555555
fresh
err "$main/$sid.jsonl" 2026-01-01T00:00:01Z "worktree agent-a1c refused, exit 1"
err "$main/$sid.jsonl" 2026-01-01T00:00:02Z "only once here"
mkdir -p "$main/$sid/subagents"
err "$main/$sid/subagents/agent-x.jsonl" 2026-01-01T00:00:03Z "worktree agent-b2d refused, exit 2"
scratch=$proj/$(enc "/tmp/claude-1000/$(enc "$wt")/$sid/scratchpad/manual")
mkdir -p "$scratch"
err "$scratch/s.jsonl" 2026-01-01T00:00:04Z "worktree agent-e5f refused, exit 3"
other=$proj/$(enc "$d/work/other"); mkdir -p "$other"
err "$other/o.jsonl" 2026-01-01T00:00:05Z "worktree agent-z9z refused, exit 4"
out=$("$here/retro-log" "$wt" 2>&1)
rep=$(section "$out" "Repeated errors")
check "one group of 3" "$(grep -c . <<<"$rep")" 1
[[ $rep == "3x "*worktree*refused* ]] || { printf 'FAIL group line: %s\n' "$rep"; fail=1; }
[[ ${rep#3x } != *[0-9]* ]] || { printf 'FAIL ids and numbers not stripped: %s\n' "$rep"; fail=1; }
[[ $out != *"only once"* ]] || { printf 'FAIL single error shown\n'; fail=1; }

fresh
for w in alpha beta gamma delta epsilon zeta; do
  err "$main/$sid.jsonl" 2026-01-01T00:00:01Z "$w broke"; err "$main/$sid.jsonl" 2026-01-01T00:00:02Z "$w broke"
done
err "$main/$sid.jsonl" 2026-01-01T00:00:03Z "alpha broke"
rep=$(section "$("$here/retro-log" "$wt" 2>&1)" "Repeated errors")
check "top five" "$(grep -c . <<<"$rep")" 5
check "most first" "$(head -1 <<<"$rep")" "3x alpha broke"

fresh
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "go"
typed "$main/$sid.jsonl" 2026-01-01T00:00:02Z "go"
typed "$main/$sid.jsonl" 2026-01-01T00:00:03Z "<task-notification>helper done</task-notification>"
typed "$main/$sid.jsonl" 2026-01-01T00:00:04Z "do the manual check via a subagent"
typed "$main/$sid.jsonl" 2026-01-01T00:00:05Z "do the manual check via a subagent!"
mkdir -p "$main/$sid/subagents"
typed "$main/$sid/subagents/agent-x.jsonl" 2026-01-01T00:00:03Z "helper prompt: build P1"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "typed messages" "$msgs" "go
do the manual check via a subagent"

rm -rf "$CLAUDE_CONFIG_DIR"
out=$("$here/retro-log" "$d/work/none" 2>&1); rc=$?
check "no logs" "$rc $out" "0 no logs on this machine"

fresh
err "$main/$sid.jsonl" 2026-01-01T00:00:01Z "worktree agent-a1c refused, exit 1"
out=$("$here/retro-log" "$d/work/none" 2>&1); rc=$?
check "no logs beside other features" "$rc $out" "0 no logs on this machine"

first=$(awk '/^## /{on=($0=="## Steps"); next} on && /^[0-9]+\. /{print; exit}' "$here/../SKILL.md")
[[ $first == "1. "*'${CLAUDE_SKILL_DIR}/scripts/retro-log'* ]] || { printf 'FAIL retro step 1 does not run the script: %s\nFix: make step 1 under "## Steps" in %s run ${CLAUDE_SKILL_DIR}/scripts/retro-log with the feature worktree path.\n' "$first" "$here/../SKILL.md"; fail=1; }

fresh
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "go"
printf '{"type":"user","timestamp":"2026-01-01T00:00:02Z","isCompactSummary":true,"isVisibleInTranscriptOnly":true,"message":{"role":"user","content":"This session is being continued from a previous conversation."}}\n' >> "$main/$sid.jsonl"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "compaction summary skipped" "$msgs" "go"

fresh
q() { printf '{"type":"attachment","timestamp":"%s","attachment":{"type":"queued_command","prompt":"%s","origin":{"kind":"%s"}}}\n' "$2" "$3" "$4" >> "$1"; }
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "start"
q "$main/$sid.jsonl" 2026-01-01T00:00:02Z "do the manual check via a subagent" human
q "$main/$sid.jsonl" 2026-01-01T00:00:03Z "helper hand-back report" peer
q "$main/$sid.jsonl" 2026-01-01T00:00:04Z "task finished" task-notification
typed "$main/$sid.jsonl" 2026-01-01T00:00:05Z "ship it"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "queued human message in time order" "$msgs" "start
do the manual check via a subagent
ship it"

fresh
for w in alpha beta gamma delta epsilon zeta; do
  err "$main/$sid.jsonl" 2026-01-01T00:00:01Z "$w broke"; err "$main/$sid.jsonl" 2026-01-01T00:00:02Z "$w broke"
done
err "$main/$sid.jsonl" 2026-01-01T00:00:03Z "zeta broke"
rep=$(section "$("$here/retro-log" "$wt" 2>&1)" "Repeated errors")
check "top five by count, most frequent logged last" "$(head -1 <<<"$rep")" "3x zeta broke"

fresh
p1='\n\n<pasted_content id=\"7ee0\">Sam: can you send me the setup page?</pasted_content id=\"7ee0\">\n\ndo the manual check via a subagent'
p2='\n\n<pasted_content id=\"8ff1\">set up the mount</pasted_content id=\"8ff1\">'
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "start"
typed "$main/$sid.jsonl" 2026-01-01T00:00:02Z "$p1"
typed "$main/$sid.jsonl" 2026-01-01T00:00:03Z "$p2"
typed "$main/$sid.jsonl" 2026-01-01T00:00:04Z "ship it"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "paste-led messages printed as stored" "$msgs" 'start
<pasted_content id="7ee0">Sam: can you send me the setup page?</pasted_content id="7ee0">

do the manual check via a subagent
<pasted_content id="8ff1">set up the mount</pasted_content id="8ff1">
ship it'

fresh
sdk=99999999-2222-3333-4444-555555555555
typed "$main/$sid.jsonl" 2026-01-01T00:00:01Z "go"
typed "$main/$sid.jsonl" 2026-01-01T00:00:02Z "<command-name>/clear</command-name><command-args></command-args>"
s() { printf '{"type":"user","entrypoint":"sdk-cli","turnOrigin":"sdk","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' "$2" "$3" >> "$1"; }
s "$main/$sdk.jsonl" 2026-01-01T00:00:03Z "<command-name>/final-review</command-name><command-args>docs/work/x/spec.md AFK</command-args>"
s "$main/$sdk.jsonl" 2026-01-01T00:00:04Z "yes, approve as written"
msgs=$(section "$("$here/retro-log" "$wt" 2>&1)" "Typed messages")
check "script-run prompts skipped" "$msgs" "go
/clear"

[ $fail = 0 ] && echo "OK retro-log-test"
exit $fail
