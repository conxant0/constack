#!/usr/bin/env bash
# require-model.sh: PreToolUse hook on Agent, registered by build/SKILL.md frontmatter (rule 3).
# Blocks a dispatch with no model: settings env CLAUDE_CODE_SUBAGENT_MODEL=sonnet would run it on Sonnet.
m=$(python3 -c 'import json, sys; print((json.load(sys.stdin).get("tool_input") or {}).get("model") or "")' 2>/dev/null)
[ -n "$m" ] && exit 0
echo "Blocked: this Agent call has no model (/build rule 3). Fix: re-send the same call with model set: opus, or the ticket's Model: line." >&2
exit 2
