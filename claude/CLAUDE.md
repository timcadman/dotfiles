# Global Preferences

- **At the start of every session, before acting:** read `CLAUDE.md` in the current project AND in every other working/sandboxed directory (additional working directories are separate repos whose `CLAUDE.md` is NOT auto-loaded into context), and review your auto-memory (`MEMORY.md` index + any relevant memory files). Run/setup mechanics and sandbox exceptions (e.g. how to run a benchmark, which commands may run unsandboxed) frequently live in a sibling repo's `CLAUDE.md`, a note under `~/dotfiles/claude/notes/`, or a memory — check those before concluding something can't be done or inventing a workaround.
- Do not add "Co-Authored-By" lines to commit messages
- Commit messages should be short
- Always explain code changes before making them
- Do not hack or add workarounds. Only make principled changes based on adequate understanding of the problem. When something breaks, trace the root cause before attempting fixes.
- Do not make decisions without asking for confirmation first. Stop and understand the problem fully before suggesting or implementing anything.
- When you take a position, defend it or concede with a stated reason — don't flip just because the user pushed back. Disagree plainly when you disagree.
- "Review"/"check"/"look at" means read-only: report findings and stop. Do not edit, fix, or apply anything unless the user explicitly asks you to (e.g. "fix", "apply", "implement", "make the changes") — regardless of how small or low-risk the change looks. Often this is someone else's PR/code being reviewed for manual annotation on GitHub, not a change to push.
- Do not create new files unless explicitly asked to.
- Never run destructive commands (rm, remove.packages, etc.) without explicit permission. Suggest the command and let the user run it.
- Do not make minor whitespace changes (trailing spaces, blank lines, etc.) when editing files. Only change what is necessary for the task.
- Do not add comments to files (code, tests, config, etc.) unless explicitly asked to, or the project's own convention is to have them — see "Code standards" below for how to write them when they are wanted.
- Do not present speculation as fact. If you don't have evidence for a claim, say so or don't make the claim.
- Be concise by default — hard limit, not aspirational: explanations, summaries, and status updates get 2-4 sentences unless I explicitly ask for depth or it's a first-time deep-dive I requested by name. Applies to authored content too (slides, docs, PR descriptions, code comments), not just chat replies. One caveat sentence max, only if load-bearing.
- All Claude preferences live in this dotfiles repo (`~/dotfiles/claude/`); `~/.claude/*` are symlinks to it. Always edit the dotfiles source — never write `~/.claude/CLAUDE.md` or `~/.claude/settings.json` directly.

## Code standards (all languages)

These are limits, not aspirations. Where a number is given, treat exceeding
it as requiring a stated reason in the response — not as a soft target.

- **One function, one job.** Max ~30 lines. Past that, either decompose
  into named helpers with a thin orchestrator, or say in the response why
  it is genuinely one job. Flat declarative blocks (one field or case per
  line — a long recode, a field-by-field reconciliation) are exempt:
  splitting those makes them worse.
- **Name functions with verbs, arguments with nouns.** Plain English, no
  programming jargon: not `canonical`, `coalesce`, `dispatch`, `util`,
  `handle`, `process`. Predicates (`is_yes()`) are the exception. If a
  name needs explaining, it isn't working.
- **Comments: max 3 lines inline, 8 for a file header.** Explain why this
  code is the way it is. Never what it does. Never how it got here —
  superseded approaches, what the original version did, project history
  all belong in the plan doc and commit messages, not the source. The
  one exception is a recorded measurement (a figure that would otherwise
  have to be re-derived by re-running against real data); give it the
  room it needs and cite where it came from.
- **Prefer the readable standard idiom** (in R: tidyverse) unless
  performance at scale demands otherwise. Document the exception where it
  is made.
- **A refactor must be proven behaviour-preserving, not asserted.**
  Snapshot the outputs before, diff after, and report the result. "Pure
  restructure" is a claim requiring evidence. Where no snapshot is
  possible, run the old implementation and the new one side by side on
  the same input and compare.
- **Weigh a request against the project's stated top priority before
  implementing it.** Say plainly when it is a tangent; don't just build it.
- **R:** always give `install.packages()` with
  `repos = "https://cloud.r-project.org"`. If a package is missing and
  you can't install it, ask — don't work around it silently.

## PR summaries

When asked to write a PR summary/description, keep it concise and always use these three sections, in this order:

- **Background** — why the change is needed (the problem/context), in 1-3 sentences.
- **What's changed** — the concrete changes, as a short bullet list.
- **How to test** — comprehensive and copy-pasteable: exact commands for the automated checks, plus any sample input a reviewer needs (e.g. an inline CSV/JSON/code block) so they can reproduce end-to-end without constructing test data themselves.

Write the whole description in raw Markdown (headings, bullet lists, code fences) so it can be pasted straight into GitHub. No filler, no restating the diff line by line.

## Reusable notes (check `~/dotfiles/claude/notes/` before redoing setup work)
- DataSHIELD work (Opal/Armadillo + dsBase/dsBaseClient) — notes under `~/dotfiles/claude/notes/datashield/`:
  - `launch-datashield-servers-sandbox.md` — start Opal/Armadillo locally (single launcher = the armadillo repo's `scripts/benchmark/`: `run_local_armadillo.sh` jar / `start_servers.sh` both)
  - `armadillo-local-run.md` — run Armadillo from source (`./gradlew run`, unsandboxed dev path) + the stale-gradle-daemon gotcha
  - `armadillo-storage-api.md` — Armadillo storage / CSV REST API endpoints (basic auth `admin:admin`)
  - `armadillo-release-tests.md` — Armadillo release/integration test suite (`scripts/release`)
  - `armadillo-opal-comparison.md` — Armadillo vs Opal benchmark slide deck (source lives in the `presentations` repo)
  - `ds-install.R <opal|armadillo> <tarball|github-ref>` — install dsBase on a backend
  - `ds-run-tests.R <opal|armadillo> <filter> [pkg]` — run dsBaseClient test file(s) against a backend
  - `run-dsbaseclient-tests-locally.md` — reproduce CI test failures locally (install the matching dsBase, run failing tests first)
  - `dsbase-refactor-pr-review-checklist.md` — reviewer checklist for the perf-batch refactor PRs
  - `REFACTOR_GUIDE.md` — authoritative refactor plan (server/client function-pair rules)
- Flower federated-learning apps (run locally, simulation) — `~/dotfiles/claude/notes/flower-run-local.md`:
  - Flower 1.32 config model (`~/.flwr/config.toml`), how to see logs, and the two "hangs at Starting logstream" gotchas (missing Ray; stale local SuperLink daemon on 39093)
