---
name: dsbase-refactor
description: Rules for refactoring dsBase/dsBaseClient function pairs (perf-batch refactors), converting errors to cli, standardising argument names, and reviewing those PRs. Use when editing R/ in dsBase or dsBaseClient, or reviewing a dsBase/dsBaseClient PR.
---

# dsBase / dsBaseClient refactor

The source of truth is in `~/dotfiles/claude/notes/datashield/`. Never commit copies of these files into dsBase or dsBaseClient.

| Task | Read |
|---|---|
| Refactor a function pair (client `ds.X` + server `XDS`) | `REFACTOR_GUIDE.md` |
| Review a refactor PR pair | `dsbase-refactor-pr-review-checklist.md` |
| Convert `stop()`/`warning()` to `cli` | `CLI_ERRORS_GUIDE.md` |
| Rename or re-describe arguments | `ARG_NAMING_STANDARDIZATION.md` |
| Extract duplicated client logic | `DSBASECLIENT_DEDUP_PLAN.md` |
| Open findings from earlier reviews | `refactor-full-review.md`, `batch-9-review.md` |

- Review the server and client PRs of a batch together, against the batch's base branch.
- Test against Armadillo with the matching refactored dsBase installed, not DSLite. The `datashield-local-servers` skill says how.
- Keep the diff minimal: no body-variable renames, no restyling, no bundled clean-ups.
