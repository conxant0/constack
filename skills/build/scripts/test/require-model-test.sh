#!/usr/bin/env bash
# require-model-test.sh: the hook blocks an Agent call with no model (exit 2, message names the fix) and lets one with a model run.
set -u
h=$(cd "$(dirname "$0")/.." && pwd)/require-model.sh
fail=0
out=$(printf '{"tool_input":{"prompt":"x"}}' | "$h" 2>&1); rc=$?
[ $rc = 2 ] && grep -qF ' Fix: ' <<<"$out" || { printf 'FAIL no model: exit %s (want 2 with " Fix: ")\n%s\n' $rc "$out"; fail=1; }
out=$(printf '{"tool_input":{"prompt":"x","model":"opus"}}' | "$h" 2>&1); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || { printf 'FAIL with model: exit %s (want 0, silent)\n%s\n' $rc "$out"; fail=1; }
[ $fail = 0 ] && echo "OK require-model-test"; exit $fail
