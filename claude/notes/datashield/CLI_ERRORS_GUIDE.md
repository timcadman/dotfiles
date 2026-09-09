# dsBaseClient: Convert Error Messages to `cli`

> Source of truth alongside `REFACTOR_GUIDE.md`, `ARG_NAMING_STANDARDIZATION.md`, and
> `DSBASECLIENT_DEDUP_PLAN.md` in this same folder. Do not commit copies of this file into
> dsBase or dsBaseClient.

Style reference: <https://style.tidyverse.org/errors.html>. This guide adapts that
reference to dsBaseClient's actual current code, not a generic retelling of it.

## Current state (verified, not estimated)

- **294** `stop()` calls across 106 files, **6** `warning()` calls.
- `cli` is already an `Imports` dependency and already exported in `NAMESPACE`
  (`importFrom(cli, cli_abort)`) — no new dependency needed, just more `importFrom` entries
  as `cli_warn`/`cli_inform` get adopted.
- 3 functions in `R/utils.R` already use `cli_abort()` consistently:
  `.verify_datasources()`, `.checkClassConsistency()`, `.check_df_name_provided()`. These
  are the template to match, not a green field.
- **Existing bug to fix, not copy**: `.check_df_name_provided()` calls
  `cli_abort("...", call.=FALSE)` — `call.` (with a period) is base `stop()`'s argument
  name. `cli_abort()`'s argument is `call` (no period, expects an environment/frame or
  `NULL`, not a logical). As written this silently does nothing — the extra arg is
  swallowed into `...` rather than suppressing the calling-function reference in the error.
  Fix while converting; don't propagate this typo into new call sites.

## Tidyverse `cli` conventions to apply

1. **Structure**: one-line problem statement (sentence case, ends with a period) + optional
   `ℹ`/`✖` bullets for detail + optional trailing `ℹ` hint ending in `?`.
2. **"must" vs "can't"**: use "must" when the expected state is unambiguous
   (`"{x} must be a character vector, not {class(x)}."`); use "can't" when it's more about
   an action failing (`"Can't find object {.val {x}} on {.val {study}}."`).
3. **Glue interpolation** (`{var}`) replaces the current `paste0()`/`sprintf()` string
   building used throughout dsBaseClient's `stop()` calls — this is a direct, mechanical
   simplification at every call site that currently does
   `stop(paste0("...", x, "..."))`.
4. **Inline markup**: backtick-equivalent via `{.arg x}` (argument names), `{.val x}`
   (values), `{.cls x}` (classes), `{.fn x}` (function names) — use these instead of manual
   backticks in the string.
5. **Bullets**: `✖` for the specific problem, `ℹ` for context/hints, plain `•` for
   additional detail. Cap at 5 bullets; truncate longer lists rather than dumping
   everything.
6. **`call` argument**: pass `call = NULL` (not `call. = FALSE`) to omit the calling
   function from the error, or leave it as the default (`caller_env()`) to include it —
   decide per-helper based on whether the immediate caller or the user-facing `ds.*`
   function is more useful to show.
7. Sentence case throughout, no more than ~80 chars/line before cli's own wrapping takes
   over, prefer singular ("Column `x`" not "Column(s) `x`, `y`"), avoid the word "variable"
   (ambiguous in this codebase — could mean an R variable, a study variable/column, or a
   DataSHIELD object) in favor of "object", "column", or "argument" as precise.

## Generalize into helpers, not a 1:1 per-file swap

The instruction driving this section: convert *and* generalize in the same pass — where
many functions already raise the same message, that's a signal to route them through one
`cli_abort()`-based helper in `R/utils.R`, not to hand-convert 50+ near-identical `stop()`
calls into 50+ near-identical `cli_abort()` calls.

Verified repeated-message clusters, by occurrence count:

| Message (truncated) | Count | Status |
|---|---|---|
| `"The 'datasources' were expected to be a list of DS..."` | 52 | **Already solved, not yet adopted.** This is the exact message `.verify_datasources()`/`.set_datasources()` already raises via `cli_abort()` (see `DSBASECLIENT_DEDUP_PLAN.md` §1 — 56 functions haven't migrated to `.set_datasources()` yet). Migrating those functions fixes the datasource-boilerplate duplication *and* the error-message conversion in the same edit — don't do these as two separate passes. |
| `"Please provide the name of the input vector!"` | 20 | Not yet generalized — candidate for a new `.check_x_name_provided()` (or extend `.check_df_name_provided()` to take a noun parameter) alongside the existing data.frame-specific helper |
| `"Please provide the name of the input object!"` | 9 | Same shape as above — near-certainly the same underlying "was a required name argument left NULL" check, worded slightly differently by whoever wrote each function. Consolidate with the above rather than treating as separate. |
| `"Please provide the name of a data.frame or matrix!"` | 3 | Already has a helper (`.check_df_name_provided()`) — these 3 are call sites that should adopt it, not new text to write |
| `"x=NULL. Please provide the names of the objects to..."` / `"y=NULL. Please provide the names of the 2nd numeric..."` / similar `x=`/`y=`-prefixed variants | 2-3 each | Same underlying check as above, worded with the literal parameter name baked into the string — once parameterized, these collapse into the same generalized helper |
| `"Please provide a valid regression formula!"` / `"Please provide a valid 'family' argument!"` | 4 / 3 | glm-family-specific (`ds.glm`, `ds.glmSLMA`, `ds.glmerSLMA`, `ds.lmerSLMA`) — candidate for a small `glmChecks`-adjacent helper (that file already exists, see `R/glmChecks.R`) rather than the generic name-required helper above |

**Proposed new/extended helpers in `R/utils.R`:**
- Extend `.check_df_name_provided(df)` → generalize to something like
  `.check_name_provided(x, noun = "data.frame or matrix")` so the ~35 near-duplicate
  "please provide the name of ___" messages (data.frame, vector, object, column, etc.)
  become one parameterized helper instead of N near-identical strings. Keep
  `.check_df_name_provided()` as a thin wrapper calling it with the data.frame-specific
  noun, so the 3 existing call sites don't need to change.
- Add formula/family validity checks (currently duplicated 4x/3x across the glm-family
  functions) to `R/glmChecks.R`, following the same pattern as its existing content.

## What stays per-function (don't over-generalize)

The long tail of genuinely function-specific messages (parameter range checks, format
validation specific to one function's semantics, etc.) should still convert to
`cli_abort()` for style consistency, but there's no shared concept to extract — just apply
the formatting rules above at each site. Don't force a shared helper where the message is
legitimately one-off.

## Sequencing

1. Fix the `call.=FALSE` → `call = NULL` bug in `.check_df_name_provided()` first — it's a
   pre-existing latent bug, independent of the rest of this migration, and worth not
   propagating further while converting other call sites by example.
2. Generalize the top clusters above into `R/utils.R` helpers (or extend existing ones).
3. Migrate the 56 `.set_datasources()`-eligible functions from `DSBASECLIENT_DEDUP_PLAN.md`
   §1 — this simultaneously finishes the dedup work *and* converts the single largest
   error-message cluster (52 occurrences) to `cli_abort()`, for free.
4. Sweep the remaining ~150+ one-off `stop()`/`warning()` calls function-by-function,
   applying the formatting rules (glue interpolation, `{.arg}`/`{.val}` markup, bullet
   structure) without inventing new shared helpers unless a genuine second cluster turns up
   during the sweep.
5. Re-run `devtools::document()` / `R CMD check` after each batch — `cli_abort()` messages
   are still just character output for testthat's `expect_error(..., regexp=...)` matching,
   but glue interpolation changes the exact rendered text (e.g. added backtick-equivalents),
   so existing test assertions on exact error-message substrings will need re-verification
   against the new wording, not just a mechanical find-replace.

## Tests: write/update alongside the conversion, not after

**73 `test-arg-*.R` files currently use `fixed=TRUE` exact-string matching** on error
messages (`grep -l 'fixed\s*=\s*TRUE' tests/testthat/test-arg-*.R`) — the risky pattern for
this migration, since `cli_abort()` output differs from the current `stop()` text even when
the underlying message is conceptually unchanged: glue interpolation renders values
in-line, `{.arg}`/`{.val}` markup adds its own punctuation, and bullets prepend Unicode
symbols (`✖`, `ℹ`) that a `fixed=TRUE` full-string match will not reproduce. Every
`expect_error(ds.X(...), "<exact old text>", fixed=TRUE)` touching a converted function
needs re-verification, not just a find-replace of the expected string.

**Known related gotcha, already documented** — `run-dsbaseclient-tests-locally.md` notes
`test-arg-ds.foobar.R` already fails under a UTF-8 locale because R renders fancy quotes
(`'dsIsAsync'`) differently from the literal ASCII quotes in the `fixed=TRUE` match. cli's
Unicode bullets are the same class of problem, systematically, across every converted
message — budget for it as a known risk, not a one-off surprise per file.

**Conventions to adopt for the new/updated tests:**
- Prefer `expect_error(ds.X(...), regexp = "<distinctive substring>")` (partial match) over
  `fixed=TRUE` full-string matches, so bullet/markup rendering details don't make tests
  brittle. Match on the stable part of the message (the problem statement), not on
  formatting that cli owns.
- Where a test currently asserts the exact old `stop()` wording specifically *because* it
  was the only way to distinguish which validation failed, prefer asserting on the
  message's distinguishing content word(s) rather than its punctuation/formatting.
- For messages generalized into a shared helper (`.check_name_provided()`,
  `.checkMultiObjectConsistency()`, etc. per the Generalize section above): add **direct
  unit tests on the helper itself** (new file, e.g. `tests/testthat/test-utils.R` — none
  exists yet, confirmed via `ls tests/testthat/ | grep -i util`) covering its behavior once,
  rather than only exercising it indirectly through every calling `ds.X()` function's own
  arg test. Keep one or two indirect call-site tests per caller to confirm the helper is
  actually wired in, but stop asserting the full message text redundantly in each of the
  35+ call sites that already share one helper.
- Follow this project's own established convention for server-originated errors
  (`~/dotfiles/claude/notes/datashield/dsbase-refactor-pr-review-checklist.md` §E): when an
  error crosses the client→server boundary (as opposed to a pure client-side `cli_abort()`
  in a `ds.*` function before any server call), match on the specific message via
  `DSI::datashield.errors()` per study, not just the generic `"There are some DataSHIELD
  errors"` wrapper. This guide's conversions are client-side only, but any test that
  currently checks a client message where the underlying validation has *also* moved
  server-side (see the checklist's relocate-to-smk rule) needs the same care already applied
  in this session's `test-arg-ds.glmPredict.R` fix — don't reintroduce that class of bug
  while touching these same test files for the cli conversion.
- Run each touched test file locally against a live backend before considering it done —
  per `run-dsbaseclient-tests-locally.md` — not just a `parse()`/syntax check, since the
  actual rendered cli output can only be confirmed by triggering the real error path.

## Coordination with the other two plan files

This migration's call sites overlap heavily with `DSBASECLIENT_DEDUP_PLAN.md` (same
functions, same `.set_datasources()`/`newobj` helpers) and touch the same files as
`ARG_NAMING_STANDARDIZATION.md`'s `@template` rollout. Batch by function/file across all
three where they intersect rather than three separate full passes over the same files.
