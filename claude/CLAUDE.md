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
- Run one command per shell invocation. Avoid chaining (`;`, `&&`, `||`) and `cd` — use absolute paths or `git -C <repo>`, and issue independent commands as separate (parallel) tool calls. Some projects enforce this with a hook that rejects chained/`cd` commands.
- All Claude preferences live in this dotfiles repo (`~/dotfiles/claude/`); `~/.claude/*` are symlinks to it. Always edit the dotfiles source — never write `~/.claude/CLAUDE.md` or `~/.claude/settings.json` directly.

## PR summaries

When asked to write a PR summary/description, keep it concise and always use these three sections, in this order:

- **Background** — why the change is needed (the problem/context), in 1-3 sentences.
- **What's changed** — the concrete changes, as a short bullet list.
- **How to test** — comprehensive and copy-pasteable: exact commands for the automated checks, plus any sample input a reviewer needs (e.g. an inline CSV/JSON/code block) so they can reproduce end-to-end without constructing test data themselves.

Write the whole description in raw Markdown (headings, bullet lists, code fences) so it can be pasted straight into GitHub. No filler, no restating the diff line by line.

## Reusable notes (check `~/dotfiles/claude/notes/` before redoing setup work)
- DataSHIELD work (Opal/Armadillo + dsBase/dsBaseClient) — notes under `~/dotfiles/claude/notes/datashield/`:
  - `launch-datashield-servers-sandbox.md` — start Opal/Armadillo locally (esp. under the sandbox)
  - `start-datashield.sh` — launcher for one or both servers
  - `ds-install.R <opal|armadillo> <tarball|github-ref>` — install dsBase on a backend
  - `ds-run-tests.R <opal|armadillo> <filter> [pkg]` — run dsBaseClient test file(s) against a backend
  - `run-dsbaseclient-tests-locally.md` — reproduce CI test failures locally (install the matching dsBase, run failing tests first)
  - `dsbase-refactor-pr-review-checklist.md` — reviewer checklist for the perf-batch refactor PRs
  - `REFACTOR_GUIDE.md` — authoritative refactor plan (server/client function-pair rules)
