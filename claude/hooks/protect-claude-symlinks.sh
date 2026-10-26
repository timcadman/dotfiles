#!/bin/bash
path=$(jq -r '.tool_input.file_path // ""')
if printf '%s' "$path" | grep -qE '/[.]claude/(CLAUDE[.]md|settings([.]local)?[.]json)$'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"~/.claude/* are symlinks to the dotfiles repo. Edit the source at ~/dotfiles/claude/ instead (e.g. ~/dotfiles/claude/CLAUDE.md or ~/dotfiles/claude/settings.json)."}}'
fi
exit 0
