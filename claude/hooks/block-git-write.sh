#!/bin/bash
# Anchored at a command position so `git log --grep commit` or an echo mentioning git push still runs.
# Commit prompts rather than denies, so it needs the user's approval even in auto mode.
cmd=$(jq -r '.tool_input.command // ""')
git_at_command='(^|[;&|(`] *)([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*git( +-[cC] +[^;&|]+)? +'
if printf '%s' "$cmd" | grep -qE "${git_at_command}(push|revert)( |$)"; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"Blocked by local hook: git push/revert is prohibited here. Ask the user to run it themselves."}}'
elif printf '%s' "$cmd" | grep -qE "${git_at_command}commit( |$)"; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:"git commit needs the user'"'"'s explicit approval."}}'
fi
exit 0
