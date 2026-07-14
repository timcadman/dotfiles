# Global Preferences

- **At the start of every session, before acting:** read `CLAUDE.md` in the current project AND in every other working/sandboxed directory (additional working directories are separate repos whose `CLAUDE.md` is NOT auto-loaded into context), and review your auto-memory (`MEMORY.md` index + any relevant memory files). Run/setup mechanics and sandbox exceptions (e.g. how to run a benchmark, which commands may run unsandboxed) frequently live in a sibling repo's `CLAUDE.md`, a note under `~/dotfiles/claude/notes/`, or a memory — check those before concluding something can't be done or inventing a workaround.
- Do not add "Co-Authored-By" lines to commit messages
- Commit messages should be short
- Always explain code changes before making them
- Do not hack or add workarounds. Only make principled changes based on adequate understanding of the problem. When something breaks, trace the root cause before attempting fixes.
- Do not make decisions without asking for confirmation first. Stop and understand the problem fully before suggesting or implementing anything.
- Do not create new files unless explicitly asked to.
- Never run destructive commands (rm, remove.packages, etc.) without explicit permission. Suggest the command and let the user run it.
- Do not make minor whitespace changes (trailing spaces, blank lines, etc.) when editing files. Only change what is necessary for the task.
- Do not add comments to files (code, tests, config, etc.) unless explicitly asked to.
- Do not present speculation as fact. If you don't have evidence for a claim, say so or don't make the claim.
- All Claude preferences live in this dotfiles repo (`~/dotfiles/claude/`); `~/.claude/*` are symlinks to it. Always edit the dotfiles source — never write `~/.claude/CLAUDE.md` or `~/.claude/settings.json` directly.

## PR summaries

When asked to write a PR summary/description, keep it concise and always use these three sections, in this order:

- **Background** — why the change is needed (the problem/context), in 1-3 sentences.
- **What's changed** — the concrete changes, as a short bullet list.
- **How to test** — comprehensive and copy-pasteable: exact commands for the automated checks, plus any sample input a reviewer needs (e.g. an inline CSV/JSON/code block) so they can reproduce end-to-end without constructing test data themselves.

Write the whole description in raw Markdown (headings, bullet lists, code fences) so it can be pasted straight into GitHub. No filler, no restating the diff line by line.

## Reusable notes
Setup mechanics, sandbox exceptions, and guides live under `~/dotfiles/claude/notes/`
(DataSHIELD work in `notes/datashield/`). A `SessionStart` hook injects a manifest of these
files into context each session — read the relevant one before redoing setup work.
