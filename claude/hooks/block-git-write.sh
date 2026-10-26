#!/bin/bash
# Anchored at a command position so `git log --grep commit` or an echo mentioning git push still runs.
cmd=$(jq -r '.tool_input.command // ""')
if printf '%s' "$cmd" | grep -qE '(^|[;&|(`] *)([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*git( +-[cC] +[^;&|]+)? +(commit|push|revert)( |$)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Blocked by local hook: git commit/push/revert is prohibited here. Ask the user to run it themselves."}}'
fi
exit 0
