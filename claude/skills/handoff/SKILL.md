---
name: handoff
description: Compact the current conversation into a handoff document a fresh session can start from.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

# Handoff

Write `handoff-<slug>.md` in `$TMPDIR`, not in the repo, and report its full absolute path.

**Say what only this session knows.** Git, PRs, issues, notes under `~/dotfiles/claude/notes/` and
memory are readable by the next session. Reference them by path or URL; do not copy them.

1. **The task.** One paragraph: what the next session picks up, and where it stands.
2. **Tried and abandoned**, with the reason. The most valuable section, because git cannot show it.
3. **Live blockers.** A permission to grant, a hook that refuses, a server left running, a command
   the user must run.
4. **State by reference.** Repo, branch, base commit, PR numbers, note paths.
5. **Suggested skills**, and why each.
6. **Next move.** One concrete action.

No credential values, no personal data, no security detail.

If the user passed an argument, treat it as the next session's focus and cut everything that does
not serve it.
