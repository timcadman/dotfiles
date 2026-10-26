#!/bin/bash
# Notes a skill already points at are left out: the skill loads them when relevant.
skills_dir="$HOME/dotfiles/claude/skills"

print_with_heading() {
  local f="$1" d
  d=$(grep -m10 -E '^(#{1,6}[[:space:]]|#[[:space:]])' "$f" 2>/dev/null | sed -E 's/^#+[[:space:]]*//' | grep -m1 -E '[[:alpha:]]')
  echo "- $f"
  [ -n "$d" ] && echo "    $d"
}

is_covered_by_skill() {
  grep -qF "$(basename "$1")" "$skills_dir"/*/SKILL.md 2>/dev/null
}

{
  echo "== STARTUP BRIEFING (auto-injected by SessionStart hook) =="
  echo
  echo "These files are NOT auto-loaded. When work touches a repo or topic below, READ the relevant file before acting — do not wait to be pointed to it."
  echo
  echo "CLAUDE.md files (read when working in that repo):"
  find "$HOME/git-repos" -maxdepth 4 -iname 'CLAUDE.md' -not -path '*/node_modules/*' 2>/dev/null | sort | while read -r f; do
    print_with_heading "$f"
  done
  echo
  echo "Notes not covered by a skill (~/dotfiles/claude/notes/ — plans, reviews, trackers):"
  find "$HOME/dotfiles/claude/notes" -path '*/recipe-drafts' -prune -o -type f \( -name '*.md' -o -name '*.R' -o -name '*.sh' \) -print 2>/dev/null | sort | while read -r f; do
    is_covered_by_skill "$f" || print_with_heading "$f"
  done
} | jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}'
