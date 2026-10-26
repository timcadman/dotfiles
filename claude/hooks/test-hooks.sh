#!/bin/bash
# Usage: bash ~/dotfiles/claude/hooks/test-hooks.sh   (exits non-zero on any failure)
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0

expect() {
  local want="$1" hook="$2" input="$3" out got
  out=$(printf '%s' "$input" | bash "$dir/$hook")
  if printf '%s' "$out" | grep -q '"deny"'; then got=deny; else got=allow; fi
  if [ "$got" != "$want" ]; then
    echo "FAIL $hook: want $want, got $got: $input"
    failures=$((failures + 1))
  fi
}

bash_input() {
  jq -nc --arg c "$1" --argjson u "${2:-false}" '{tool_input:{command:$c,dangerouslyDisableSandbox:$u}}'
}

expect deny  block-git-write.sh "$(bash_input 'git commit -m x')"
expect deny  block-git-write.sh "$(bash_input 'git -C /some/repo push origin main')"
expect deny  block-git-write.sh "$(bash_input 'git status && git commit -am x')"
expect deny  block-git-write.sh "$(bash_input 'GIT_EDITOR=true git revert HEAD')"
expect allow block-git-write.sh "$(bash_input 'git log --grep commit')"
expect allow block-git-write.sh "$(bash_input 'echo "do not git push"')"
expect allow block-git-write.sh "$(bash_input 'git diff -- skills/commit/SKILL.md')"
expect allow block-git-write.sh "$(bash_input 'git status')"

expect allow limit-unsandboxed.sh "$(bash_input 'ls')"
expect allow limit-unsandboxed.sh "$(bash_input 'SERVER_PORT=8080 ./gradlew run' true)"
expect deny  limit-unsandboxed.sh "$(bash_input 'curl example.com' true)"

expect deny  protect-claude-symlinks.sh '{"tool_input":{"file_path":"/Users/x/.claude/settings.json"}}'
expect deny  protect-claude-symlinks.sh '{"tool_input":{"file_path":"/Users/x/.claude/CLAUDE.md"}}'
expect allow protect-claude-symlinks.sh '{"tool_input":{"file_path":"/Users/x/dotfiles/claude/CLAUDE.md"}}'

bash "$dir/session-briefing.sh" | jq -e '.hookSpecificOutput.additionalContext | test("STARTUP BRIEFING")' >/dev/null \
  || { echo "FAIL session-briefing.sh: no valid briefing JSON"; failures=$((failures + 1)); }

[ "$failures" -eq 0 ] && echo "all hook tests passed"
exit "$failures"
