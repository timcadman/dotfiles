#!/bin/bash
IN=$(cat)
printf '%s' "$IN" | jq -e '.tool_input.dangerouslyDisableSandbox == true' >/dev/null || exit 0
cmd=$(printf '%s' "$IN" | jq -r '.tool_input.command // ""')
printf '%s' "$cmd" | grep -qE 'gradlew|start_servers|run_benchmark|ds_unsandboxed' && exit 0
jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Unsandboxed Bash is restricted to the Armadillo launch (gradlew/start_servers). Run other commands sandboxed."}}'
exit 0
