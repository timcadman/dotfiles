---
name: code-standards
description: Limits on function size, naming, comments, idiom, refactor proof and change scope. Use before writing, editing or refactoring code in any language (R, Python, shell, Java, JS).
---

# Code standards (all languages)

These are limits, not aspirations. Where a number is given, treat exceeding
it as requiring a stated reason in the response — not as a soft target.

- **One function, one job.** Max ~30 lines. Past that, either decompose
  into named helpers with a thin orchestrator, or say in the response why
  it is genuinely one job. Flat declarative blocks (one field or case per
  line — a long recode, a field-by-field reconciliation) are exempt:
  splitting those makes them worse.
- **A function's purpose must be guessable from its name and signature
  alone — the "cover the body" test.** Read only the name and parameters;
  if you can't state in one sentence what it does and returns, rename it
  or split it. If that sentence needs "and" more than once, it's not one
  job — see the line-count rule above.
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

## Scope of a change

- **Clean up only your own orphans.** Remove imports, variables and
  functions that your change made unused. Mention pre-existing dead code;
  don't delete it.
- **Don't "improve" adjacent code, comments or formatting** as a side
  effect. Every changed line traces back to the request.
- **Turn the task into a check you can run.** A bug fix starts with a
  failing test (testthat in R) that reproduces it, then makes it pass.
- **For multi-step work, state the plan with a verification per step**
  before starting, and run each check before moving on.

For deciding whether to add a layer, an abstraction or state at all, read
the `laziness` skill.
