# Batch 9 review (plotting functions) — open findings

Reviewed 2026-09-14 against `REFACTOR_GUIDE.md` and `dsbase-refactor-pr-review-checklist.md`.
Read-only review; nothing fixed yet.

- dsBase `refactor/perf-batch-9` @ `5906be81` (branched from the batch-2 merge `d2f5b781`)
- dsBaseClient `refactor/perf-batch-9` @ `f16502ca` (branched from `ac777749`, bootstrapped from an old batch-7)
- Server tests run in a scratch worktree: only `smk-densityGridDS` and `smk-rangeDS` exist for these functions — 16 pass, 0 fail.
- Client tests: to be run on CI, not locally.

## dsBase (server)

Must fix:
1. **Type checks dropped, not moved.** The client used to reject non-numeric input for `ds.histogram`, `ds.heatmapPlot`, `ds.contourPlot`, `ds.scatterPlot`. `histogramDS1/2`, `heatmapPlotDS`, `scatterPlotDS`, `densityGridDS` got no `.checkClass(permitted_classes = c("numeric","integer"))`. Behaviour change.
2. **Missing server unit tests** for `histogramDS1`, `histogramDS2`, `heatmapPlotDS`, `scatterPlotDS`, `boxPlotGGDS` (happy path, "does not exist", "must be of type").
3. **Box plot helpers not refactored.** `boxPlotGG_data_TreatmentDS(table, …)` and `boxPlotGG_data_Treatment_numericDS(vector)` still take resolved objects; client callers `ds.boxPlotGG_data_Treatment(_numeric)` still use `paste0` + `as.symbol()` and the old datasource boilerplate.

Should fix:
4. `boxPlotGGDS.R` refactored but has no `@author` line (guide says skip files without one; checklist says add — decide).
5. Whitespace-only churn: `boxPlotGGDS.R` (2 lines), `densityGridDS.R` (4, incl. trailing spaces on `# MODULE 1…`), one line in `test-smk-densityGridDS.R`.
6. `densityGridDS` `@param limits` still mentions `xvect`/`yvect`.

## dsBaseClient

Must fix:
7. **`ds.boxPlot` lost checks.** Before: class consistency across studies, `variables` exist and are numeric, `group`/`group2` exist and are factors. Now only `unique(unlist(classDS(x)))` — mixed classes silently merged, nothing server-side replaces the rest. (`classDS` returns a bare class vector, so `.checkClassConsistency()` doesn't fit as-is.)
8. `test-smk-ds.boxPlotGG.R` never calls `ds.boxPlotGG` (only `ds.dataFrame`); `test-perf-ds.boxPlotGG.R` calls `ds.boxPlot`.
9. No wrong-type smoke tests (factor/character input) — add once item 1 is fixed.
10. `REFACTOR_GUIDE.md` committed plus its `.Rbuildignore` line — remove both.

Should fix:
11. `ds.boxPlot.R`, `ds.boxPlotGG.R` refactored but no `@author` (same decision as item 4).
12. No `classConsistencyCheck` parameter (numeric/integer inputs that previously had a cross-study class check → guide says return `class` from server, parameter default `FALSE`).
13. Missing-object tests only match the generic "There are some DataSHIELD errors"; tighten with `datashield.errors()`.
14. No perf profile reference rows for the seven functions, so perf tests self-calibrate and always pass.

Fine: `call()` dispatch with matching argument names; `rangeDS` deliberately still `as.symbol()` (guide batch-9 note); residual-pattern grep clean; perf calls match smoke calls (except item 8); no Arjuna headers on new files.

## Before finalising (after items above)

- Merge `origin/v7.0-dev` into both batch-9 branches, then the batch-8 changes.
- Expect the same conflicts as batch-8: client `.Rbuildignore`, `NAMESPACE`, `R/utils.R`, `dsBase_7.0.0-permissive.tar.gz`. Batch-9's `utils.R`/`DESCRIPTION` (`cli`)/`NAMESPACE` edits are the old batch-7 bootstrap — take v7.0-dev's.
- Rebuild the permissive dsBase tarball from the merged dsBase batch-9 (`build-permissive.sh`), copy as `dsBase_7.0.0-permissive.tar.gz`.
- After batch-8's `lint.yaml` arrives, the lint job flags `DSI::datashield.aggregate` (redundant `::`, `import(DSI)`) on batch-9's changed lines, and `testthat::` is needed for any testthat call inside helper functions in tests.
- Batch-8 context carried over: per-study vector arguments (`.expand_to_studies()`), `setSeedDS` `as.integer()`.
