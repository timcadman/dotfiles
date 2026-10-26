# Refactoring Plan: dsBase & dsBaseClient Function Pairs

> **This file (`~/dotfiles/claude/notes/datashield/REFACTOR_GUIDE.md`) is the source of truth.** Do not commit copies of it to dsBase or dsBaseClient; remove any `REFACTOR_GUIDE.md` inherited from older batch branches (and the `^REFACTOR_GUIDE\.md$` line in `.Rbuildignore`).

## Context

The `ds.colnames` / `colnamesDS` pair has been refactored as a reference implementation. The pattern shifts server-state validation (object existence, type checking) from client to server, reducing network round trips and centralizing validation where data lives. This needs to be applied across all remaining function pairs in both packages.

The refactored `ds.colnames` branch (`v7.0-dev-colnames`) also introduces shared helpers:
- **Client:** `R/utils.R` with `.set_datasources()`, `.check_df_name_provided()`
- **Server:** `R/utils.R` with `.loadServersideObject()`, `.checkClass()`

## Relationship Between Packages

- **dsBaseClient** (`~/git-repos/ds-core/dsBaseClient/R/`) — Client functions (`ds.functionName`) that validate inputs and dispatch calls to server
- **dsBase** (`~/git-repos/ds-core/dsBase/R/`) — Server functions (`functionNameDS`) that execute on the data

## What Changes Per Function Pair

### Client-side (dsBaseClient)

1. **Replace datasource boilerplate** with `datasources <- .set_datasources(datasources)`
   - Removes: `datashield.connections_find()` + DSConnection class check (~8 lines)

2. **Remove `isDefined()` calls** — server handles via `.loadServersideObject()`

3. **Remove `checkClass()` calls and subsequent type guards** — server handles via `.checkClass()`

4. **Add `classConsistencyCheck` parameter** — For any function where the input accepts more than one permitted class, add a `classConsistencyCheck` parameter. The server function returns `class = class(obj)` in its result list; the client checks consistency via `.checkClassConsistency()` when the parameter is TRUE, then strips the `class` field before returning to the user. Rules for the default value:
   - **TRUE** when permitted classes include genuinely different types (e.g. data.frame + matrix, factor + character + integer)
   - **FALSE** when permitted classes are only `numeric` and `integer` (these are effectively interchangeable)
   - **No parameter** when only one class is permitted (e.g. `ds.levels` only permits factor — consistency is guaranteed by `.checkClass()`)

   **Verification:** after refactoring, inspect every `return()` in the client function — `class` (or `class.x` / `class.index` for multi-input functions) must not appear as a named element of the returned list. Stripping can be explicit (`r$class <- NULL`) or implicit (building the return from a specific subset of fields), but the absence of `class` in the final returned value must be visible at the `return()` site.

5. **Remove `ValidityMessage`** — Server functions that returned `ValidityMessage = "VALID ANALYSIS"` should remove it. Failures should call `stop()` instead of returning a failure message. Remove `ValidityMessage` from client returns too. This is a major release so API changes are acceptable.

6. **Remove `isAssigned()` calls** — no longer verify object creation client-side

7. **Remove MODULE 5 boilerplate** — the ~40-80 line "CHECK KEY DATA OBJECTS SUCCESSFULLY CREATED" block

8. **Remove `checks` parameter** — functions like `ds.dim` and `ds.length` have a `checks` parameter that gates `isDefined()`/`checkClass()` calls. Once those calls are removed, the parameter serves no purpose. Remove it from the function signature and delete the associated conditional block.

9. **Replace per-study loops with single aggregate calls** — some functions (e.g. `ds.isNA`) loop over datasources one at a time (`datashield.aggregate(datasources[i], ...)`). Since `datashield.aggregate` already supports multiple datasources and returns a named list, replace these loops with a single call and process results client-side. This collapses N sequential round trips into 1 parallel call.

10. **Keep**: null-input checks (or replace with `.check_df_name_provided()`), default `newobj` naming, the actual server call dispatch, any pure client-side logic

### Server-side (dsBase)

Two refactor patterns, depending on how the server function currently receives its input. Pick the one that matches.

**Pattern A — function already receives a string name and uses `eval(parse())` internally.**

1. Replace `eval(parse(text=x), envir=parent.frame())` with `.loadServersideObject(x)`.
2. Add `.checkClass(obj = x.val, obj_name = x, permitted_classes = …)` right after loading, where the client previously enforced type constraints.
3. Keep all computation, disclosure controls, privacy checks untouched.

**Pattern B — function currently receives a resolved R object via dispatch-layer evaluation (`as.symbol()` or `call()` in the client).**

1. Rename the function parameter from its descriptive body-variable name (e.g. `xvect`, `X`) to a simple string-name parameter (e.g. `x`). Do **not** rename the body-variable usages.
2. At the top of the body, load into the original body-variable name: `xvect <- .loadServersideObject(x)`.
3. Add `.checkClass(obj = xvect, obj_name = x, permitted_classes = …)`.
4. On the client, switch dispatch from `as.symbol(paste0("funcDS(", x, ")"))` to `call("funcDS", x)` so the string is passed through instead of being evaluated.
5. Update the `@param` roxygen line to describe the string-name form.

Both patterns leave the function body untouched — **no renaming inside the body, no restyling.** Minimise diff.

### Returning class from the server

Some client functions previously called `checkClass()` purely to drive **client-side routing** (e.g. decide which server function to dispatch, or which output format to use, or to warn about an argument being ignored). That's a separate network round trip solely to discover the class of the input object — redundant, because the server that runs the aggregate already has the object in hand.

The batch 2 precedent (`dimDS`, `lengthDS`) is: **return the class as a field of the aggregate result**. For example:

```r
lengthDS <- function(x){
  x.val <- .loadServersideObject(x)
  .checkClass(obj = x.val, obj_name = x, permitted_classes = c(...))
  list(length = length(x.val), class = class(x.val))
}
```

The client then reads `result$class` for any post-hoc routing, consistency check, or warning — no extra `checkClass()` call needed.

Cross-study class consistency is checked via the shared helper `.checkClassConsistency(results)` (in `dsBaseClient/R/utils.R`), which aborts if the `class` field differs across studies. Always use this helper instead of inlining the check.

**When to apply this:**
- The client was previously calling `checkClass()` to select output format, format warnings, or check class consistency across studies.
- The class information can be derived from the aggregate's input.

**When not to apply this:**
- The client needs the class *before* choosing which server function to call (true composite dispatchers like `ds.summary`, which branch to completely different server functions per class). These still need a pre-call class lookup, for example via `call("classDS", x)` as a single lightweight aggregate.
- The class is genuinely irrelevant to the client after the call.

Prefer this pattern over keeping a client-side `checkClass()` call whenever a client function currently does both a `checkClass()` and an aggregate call on the same object.

### Minimal-diff rule

Refactors should change as little as possible. Do not rename variables, restyle comments, reformat whitespace, or bundle unrelated cleanups. If a variable rename is stylistically tempting but not strictly required by the refactor, skip it. If the user pushes back on a change, stop and ask — do not iterate with more edits on the same file.

### Do not change existing behaviour

The refactor must not alter which input types a function accepts or what it returns (beyond adding `class` to the return list). If the original function accepted data.frames, the refactored version must too. Check previous behaviour before setting permitted classes in `.checkClass()`.

This extends to **test coverage**. If a refactor removes output fields that tests asserted on, the refactor is not done until equivalent coverage is added. Do not merely delete assertions to make tests pass — that silently reduces what the suite verifies. The change is reviewable by diffing `test-smk-*.R` against the base branch: every removed `expect_*` must be either (a) redundant because the same behaviour is covered elsewhere in the same file, or (b) replaced with an assertion covering the same server-side behaviour.

### Adding new parameters to existing exported functions

When adding a parameter to an already-released function (e.g. `classConsistencyCheck`, a new behaviour flag), **place it after all existing named parameters** — never in the middle of the signature. Inserting a parameter mid-signature silently breaks every caller that used positional argument order for anything to its right. Append it to the end (after `datasources=NULL` is acceptable even though `datasources` is conventionally last), and document the default value in `@param`.

### Tests

**Server-side unit tests** (new `test-smk-functionNameDS.R` in dsBase):
- Happy path: call with valid input, assert correct output
- Unhappy: nonexistent object → `expect_error(..., "does not exist")`
- Unhappy: wrong type → `expect_error(..., "must be of type")` (only where `.checkClass()` is used)

**Client-side end-to-end tests** (update existing `test-smk-ds.functionName.R` in dsBaseClient):
- Happy path: existing tests should still pass
- Unhappy: nonexistent object → `expect_error(..., "DataSHIELD errors")`
- Unhappy: wrong type → `expect_error(..., "DataSHIELD errors")` (where type was previously checked client-side)
- Update any tests that expected client-side error messages to expect server-originated errors
- **When MODULE 5 assertions are removed, add comparable replacements.** The old MODULE 5 block returned `$is.object.created` and `$validity.check` messages asserting that `newobj` existed on every server. When those assertions are stripped, add equivalent checks inside the same `test_that` block that verify the object was created on all sources — e.g. `ds_expect_variables(c("<expected list>"))` or `expect_no_error(ds.class("<newobj>"))`. Relying on the shutdown-block `ds_expect_variables()` alone is not sufficient because it can't pinpoint which test created the missing object.

**Client-side smoke tests** (new `test-smk-ds.functionName.R` if none exists):
- If no smoke test file exists for a refactored client function, create one. Every refactored function must have at least a basic happy-path smoke test that exercises the server call and verifies the result.
- Follow the existing test pattern: `connect.studies.dataset.cnsim(...)`, `test_that("setup", ...)`, main test block, `test_that("shutdown", ...)`, `disconnect.studies.dataset.cnsim()`.

**Client-side performance tests** (new `test-perf-ds.functionName.R` in dsBaseClient):
- Add a performance test for each refactored client function. Follow the pattern in `test-perf-ds.class.R`: call the function in a timed loop, compare against a reference rate from the perf profile CSV.
- Run with `PERF_DURATION_SEC=2 devtools::test(filter = "perf-")` during development; the default 30-second duration is for CI. Always actually run each new/modified perf test against a live backend at this reduced duration before considering it done — batch-10's perf tests for elspline/lspline/ns/qlspline/table all shipped with wrong column names or a missing `connect.studies.dataset.*()` call that only surfaced when executed, not on review.
- **Do not** include Arjuna Technologies copyright headers in new test files. The existing headers in pre-refactor files should be left as-is, but new files we create should not carry third-party copyright.
- **The perf test must replicate the smoke test.** Before writing a perf test, read the corresponding `test-smk-ds.functionName.R` and copy:
  1. The `connect.studies.dataset.*()` line (same dataset, same columns)
  2. The `disconnect.studies.dataset.*()` line
  3. The function call (same parameters, same column names, same argument names)
  
  The perf test should exercise the same code path as the smoke test's happy-path call. Do not use generic placeholder calls or different datasets.

**Design decisions:**
- Functions accepting any class: use `.loadServersideObject()` only, no `.checkClass()`
- Client tests must include unhappy paths testing server error propagation
- Start with Batch 1 (simple coercions)

### Authorship

After the refactor commits for a batch have landed, add `Tim Cadman, Genomics Coordination Centre, UMCG, Netherlands` as a new `@author` roxygen line in every R/ file touched on each branch (dsBase and dsBaseClient), matching the existing `@author` line(s) below:

```
#' @author <existing author line, unchanged>
#' @author Tim Cadman, Genomics Coordination Centre, UMCG, Netherlands
```

Skip files that have no existing `@author` line (e.g. `R/utils.R`). Do this as a separate trailing commit per repo with message `docs: updated authorship`, not bundled with the refactor commits.

**Only add the tag to files you actually refactored** (replaced `eval(parse())`, added `.loadServersideObject` / `.checkClass`, replaced MODULE 5, converted dispatch to `call()`, etc.). If a file in a batch's function list turns out not to need any substantive change — for example a server function whose inputs are client-transmitted literal data rather than object names (`dmtC2SDS` is one such case) — leave its author line as-is. Adding `@author Tim Cadman` to an untouched file is incorrect authorship attribution.

## Excluded Functions

**Defunct in 7.0.0:** see "7.0.0 deprecation" below.

**Already done:** ds.colnames / colnamesDS

**Client-only (no server pair):** checkClass.R, isDefined.R, extract.R, glmChecks.R, getPooledMean.R, getPooledVar.R, logical2int.R

## Batches

### Batch 1 — Simple Type Coercions (11 pairs)
Single input → single output, straightforward `eval(parse())` replacement.

**TODO:** Add `classConsistencyCheck` parameter to batch-1 functions with >1 permitted class. For numeric/integer-only functions (ds.abs, ds.exp, ds.log, ds.sqrt) default to FALSE; for others (ds.asDataMatrix: data.frame/matrix, ds.asLogical: numeric/integer/character/matrix) default to TRUE. Server functions need to return class in results to support this. dsBase batch-1 is already merged — server changes need a new branch or inclusion in a later batch. **Blocker:** all batch-1 functions except `ds.asList` are assign functions, so the server cannot return `class`; this would need a pre-call `checkClass()` lookup (as batch 4 does), costing an extra round trip.

**TODO:** `test-smk-asLogicalDS.R` in dsBase is missing a wrong-type test case (e.g. passing a list). Other `.checkClass()` functions (absDS, expDS, logDS, sqrtDS) have this test. dsBase batch-1 is merged — fix in a follow-up.

| Client | Server | Permitted classes | Notes |
|--------|--------|-------------------|-------|
| ds.abs | absDS | numeric, integer | |
| ds.asCharacter | asCharacterDS | * | |
| ds.asDataMatrix | asDataMatrixDS | data.frame, matrix | |
| ds.asInteger | asIntegerDS | * | |
| ds.asList | asListDS | * | **AGGREGATE** (not assign); server takes 2 params (x.name, newobj) |
| ds.asLogical | asLogicalDS | * | Server has existing type validation (numeric/integer/character/matrix) — preserve as `.checkClass()` |
| ds.asMatrix | asMatrixDS | * | |
| ds.asNumeric | asNumericDS | * | Server has complex factor/character conversion logic — preserve |
| ds.exp | **NEW: expDS** | numeric, integer | No server DS function exists — client currently calls native `exp()` via `as.symbol()`. Must create `expDS.R` |
| ds.log | **NEW: logDS** | numeric, integer | No server DS function exists — client currently calls native `log()` via `as.symbol()`. Must create `logDS.R`. Has `base` parameter |
| ds.sqrt | sqrtDS | numeric, integer | |

`*` = accept any class — only use `.loadServersideObject()`, no `.checkClass()` needed

**Batch 1 sub-patterns discovered:**
- **Math ops (abs, exp, log, sqrt):** Client uses `checkClass()` + `isAssigned()`, no MODULE 5
- **Type conversions (asCharacter, asDataMatrix, asInteger, asLogical, asMatrix, asNumeric):** Client uses `isDefined()` + MODULE 5 block (except asList which has neither)
- **asList is unique:** Uses `datashield.aggregate` instead of `datashield.assign`

### Batch 2 — Simple Aggregations (10 pairs)
Return results to client, no server-side assignment.

| Client | Server | Permitted classes |
|--------|--------|-------------------|
| ds.class | classDS | * |
| ds.dim | dimDS | data.frame, matrix |
| ds.length | lengthDS | character, factor, integer, logical, numeric, list |
| ds.names | namesDS | * |
| ds.isNA | isNaDS | character, factor, integer, logical, numeric, data.frame, matrix |
| ds.numNA | numNaDS | * |
| ds.ls | lsDS | (no object input) |
| ds.completeCases | completeCasesDS | * (no .checkClass — server handles via own branching) |
| ds.levels | levelsDS | factor |
| ds.unique | uniqueDS | * |

**Deferred from Batch 2 — DONE in Batch 10:** ds.isValid / isValidDS. `isValidDS(x)` now takes a name, runs `.checkClass`, and returns `list(valid, class)`; `ds.isValid` has `classConsistencyCheck=TRUE`. The size check itself lives in the internal `.checkDisclosureSize(obj)` (in `isValidDS.R`), which server functions that already hold the object call directly: `replaceNaDS`, `quantileMeanDS`, `recodeLevelsDS`, `rowColCalcDS`. `ds.summary` calls `isValidDS` by name and reads `$valid`.

**Batch 2 sub-patterns:**
- **Standard eval(parse()) functions (classDS, dimDS, lengthDS, namesDS, lsDS, completeCasesDS, uniqueDS):** Server uses `eval(parse(text=x), envir=parent.frame())` — replace with `.loadServersideObject()`
- **Dispatch-layer resolution functions (isNaDS, numNaDS, levelsDS):** Server receives resolved R objects via client `as.symbol()`/`call()` dispatch — change server to accept string name + `.loadServersideObject()`, change client to `call("funcDS", x)`
- **Assign functions (completeCases, unique):** Use `datashield.assign` not `datashield.aggregate` — still remove MODULE 5 / isAssigned
- **Client-side processing to preserve:** ds.dim and ds.length have `type` parameter with alias normalization and cross-study pooling; ds.isNA has per-study loop with conditional messaging; ds.ls has wildcard `*` → `_:A:_` escaping
- **Pooling functions (dimDS, lengthDS):** Return `list(dim=..., class=...)` / `list(length=..., class=...)` so client can check cross-study class consistency before pooling results

### Batch 3 — Statistics (10 pairs)
Aggregate functions returning computed values. Some have multi-step server calls.

| Client | Server | Notes |
|--------|--------|-------|
| ds.mean | meanDS | has disclosure controls |
| ds.var | varDS | has disclosure controls |
| ds.cor | corDS | two inputs |
| ds.corTest | corTestDS | two inputs |
| ds.cov | covDS | two inputs |
| ds.kurtosis | kurtosisDS1/DS2 | multi-step |
| ds.skewness | skewnessDS1/DS2 | multi-step |
| ds.quantileMean | quantileMeanDS | aggregate |
| ds.meanSdGp | meanSdGpDS | aggregate |
| ds.summary | (check server) | aggregate |

### Batch 4 — Data Manipulation / Assign (15 pairs)
Create/modify server objects. Many have MODULE 5 blocks.

| Client | Server | Notes |
|--------|--------|-------|
| ds.Boole | BooleDS | assign, MODULE 5 |
| ds.c | cDS | multi-input assign |
| ds.cbind | cbindDS | multi-input, permissive check |
| ds.rbind | rbindDS | multi-input |
| ds.dataFrame | dataFrameDS | multi-input, complex |
| ds.dataFrameSort | dataFrameSortDS | assign, MODULE 5 |
| ds.dataFrameSubset | dataFrameSubsetDS1/DS2 | multi-step |
| ds.dataFrameFill | dataFrameFillDS | assign |
| ds.list | listDS | assign |
| ds.unList | unListDS | assign |
| ds.merge | mergeDS | assign, MODULE 5 |
| ds.rep | repDS | assign |
| ds.seq | seqDS | assign |
| ds.replaceNA | replaceNaDS | assign, per-source loop |
| ds.recodeValues | recodeValuesDS | assign |

### Batch 5 — Matrix Operations (8 pairs)

| Client | Server |
|--------|--------|
| ds.matrix | matrixDS |
| ds.matrixDet | matrixDetDS1/DS2 |
| ds.matrixDet.report | matrixDetDS2 |
| ds.matrixDiag | matrixDiagDS |
| ds.matrixDimnames | matrixDimnamesDS |
| ds.matrixInvert | matrixInvertDS |
| ds.matrixMult | matrixMultDS |
| ds.matrixTranspose | matrixTransposeDS |

### Batch 6 — Factor & Recoding (5 pairs)

| Client | Server |
|--------|--------|
| ds.asFactor | asFactorDS1/DS2 |
| ds.asFactorSimple | asFactorSimpleDS |
| ds.changeRefGroup | changeRefGroupDS |
| ds.reShape | reShapeDS |
| ds.dmtC2S | dmtC2SDS |

### Batch 7 — Modelling (8 pairs)
Most complex. Multiple server calls, complex validation logic.

| Client | Server |
|--------|--------|
| ds.glm | glmDS1/DS2 |
| ds.glmSLMA | glmSLMADS1/DS2/assign |
| ds.glmPredict | glmPredictDS.ag/as |
| ds.glmSummary | glmSummaryDS.ag/as |
| ds.glmerSLMA | glmerSLMADS2/assign |
| ds.lmerSLMA | lmerSLMADS2/assign |
| ds.gamlss | gamlssDS |
| ds.mice | miceDS |

### Batch 8 — Random Generation & Sampling (6 pairs)

| Client | Server |
|--------|--------|
| ds.rBinom | rBinomDS |
| ds.rNorm | rNormDS |
| ds.rPois | rPoisDS |
| ds.rUnif | rUnifDS |
| ds.sample | sampleDS |
| ds.setSeed | setSeedDS |

### Batch 9 — Plotting & Visualization (7 pairs)

| Client | Server |
|--------|--------|
| ds.histogram | histogramDS1/DS2 |
| ds.heatmapPlot | heatmapPlotDS |
| ds.contourPlot | (check server name) |
| ds.densityGrid | densityGridDS |
| ds.scatterPlot | scatterPlotDS |
| ds.boxPlot | (check server) |
| ds.boxPlotGG | boxPlotGGDS |

**Batch 9 note — DONE in Batch 10:** `rangeDS(x)` is refactored (Pattern B, numeric/integer `.checkClass`) and `ds.heatmapPlot`, `ds.contourPlot`, `ds.densityGrid` now dispatch `call("rangeDS", x)`.

### Batch 10 — Splines, Tables, Misc (14 pairs)

| Client | Server |
|--------|--------|
| ds.elspline | elsplineDS |
| ds.lspline | lsplineDS |
| ds.ns | nsDS |
| ds.qlspline | qlsplineDS |
| ds.table | tableDS/tableDS.assign/tableDS2 |
| ds.tapply | tapplyDS |
| ds.tapply.assign | tapplyDS.assign |
| ds.rowColCalc | rowColCalcDS |
| ds.make | (check server) |
| ds.assign | (check server) |
| ds.metadata | metadataDS |
| ds.getWGSR | getWGSRDS |
| ds.lexis | lexisDS1/DS2/DS3 |
| ds.hetcor | hetcorDS |

**Batch 10 dependency — DONE:** see "Deferred from Batch 2" above. Batch 10 also moved `ds.rowColCalc`'s per-study numeric-column check into `rowColCalcDS`, and replaced the `eval(parse())` of `exclude` values in `tableDS`/`tableDS.assign` with string splitting (`"NA"` → `NA`).

## Known Issues

**Batch 8:** `ds.sample` smoke test failed at the `ds.length("newobj.sample")` call because the batch-2 client was not yet in v7.0-dev. Batch 2 is now merged, so this should pass — not yet re-run to confirm.

**Batch 9:** resolved in Batch 10 (`rangeDS` refactored).

## Open items (single list — 2026-10-23)

All batches 1–11 are merged in both repos. Remaining work is three PRs, in order.

**PR A — Fixes** (dsBase + dsBaseClient pair)
1. **`ds.mdPattern` combine pools by position** (review #43, `ds.mdPattern.R:170`) — fix aligning by variable name is in dsBaseClient stash `e5cfef2b` (`R/ds.mdPattern.R` + test); not yet run against a backend.
2. **`asListDS` in AggregateMethods** (review #1) — should be under AssignMethods only in `inst/DATASHIELD`. Fix is in dsBase stash `fbea2aee` (duplicate `57393bf1`).
3. **`corDS`/`covDS` factor guard** (review #5) — v7.0-dev permits only numeric/integer/matrix/data.frame; 6.3.5 accepted factor `x` (and `y`), correlating on level codes. **Decision needed:** any factor, two-level only, or keep rejecting. Code + server tests in the same dsBase stash. Restore client test "cor accepts a factor variable" and add one for `ds.cov`.
4. **`test-smk-asLogicalDS.R`** (dsBase) — no wrong-type test, although `asLogicalDS` runs `.checkClass`.

**PR B1 — Client helpers** (dsBaseClient; see `DSBASECLIENT_DEDUP_PLAN.md`)
1. Rename helpers to camelCase in one commit first (`.set_newobj_name`→`.resolveNewobjName`, `.set_datasources`→`.resolveDatasources`, etc.; review #37).
2. `newobj` sweep — replace the ~46 inline `is.null(newobj)` defaults with `.resolveNewobjName()`. See "Follow-up: settle the `newobj`…".
3. `.checkNameProvided(x, noun)` for the ~35 "Please provide the name of…" variants; `.check_df_name_provided` becomes a wrapper; fix its `call.=FALSE` → `call = NULL`.
4. Adopt `.set_datasources()` in `ds.dmtC2S`, `ds.glmPredict`, `ds.glmSummary`; glm formula/family check in `glmChecks.R`.
5. `tests/testthat/test-utils.R` unit-tests each helper.

**PR B2 — cli conversion** (dsBaseClient; see `CLI_ERRORS_GUIDE.md`)
1. Remaining one-off `stop()` → `cli_abort()` (208 `stop(` in `R/` on 2026-10-23).
2. Loosen `fixed=TRUE` message assertions in touched tests to distinctive substrings.

**Deferred past v7**
- **Batch 1 `classConsistencyCheck`** — blocked: all except `ds.asList` are assign functions, so the server cannot return `class`; would need a pre-call `checkClass()` (extra round trip). See Batch 1 TODO.
- **`*.transmit` / `eval(parse())` pass** — 15 server files deserialise via `strsplit` + `eval(parse())` (e.g. `matrixDS`, `matrixDiagDS`, `repDS`, `dmtC2SDS`, `dataFrameSubsetDS1/2`). See "Follow-up: replace clientside `*.transmit`…".

Stash SHAs are stable; `stash@{n}` indices shift — apply by SHA.

## Per-Batch Workflow

**Important:** dsBase and dsBaseClient are separate git repos. Changes must be committed and tested in the correct order since the client depends on the server package being installed.

### Step 0 — Branch bootstrap

When creating a new batch branch (in either repo) from `origin/v7.0-dev`:

1. **dsBaseClient:** copy `R/utils.R` from the most recently refactored client branch (e.g. `origin/refactor/perf-batch-4`). `origin/v7.0-dev` on the client does not yet contain it — it only enters `v7.0-dev` once the batch-1 or batch-2 client PR merges.
2. **dsBaseClient:** if the branch you're bootstrapping from carries a `REFACTOR_GUIDE.md`, do NOT bring it along — the dotfiles copy is the source of truth (see note at top). Remove the file and its `.Rbuildignore` entry if inherited.
3. **dsBase:** no bootstrap copy needed — `R/utils.R` with `.loadServersideObject` / `.checkClass` is already in `origin/v7.0-dev` (merged with batch-1).

Commit the bootstrap separately (message: `chore: bootstrap batch-N from batch-M`) before starting the refactor work.

### Step 1 — Server-side (dsBase repo)
1. Create feature branch from `v7.0-dev` in dsBase
2. Refactor server functions:
   - Replace `eval(parse())` → `.loadServersideObject()`
   - Add `.checkClass()` where the client had type guards
3. Write server-side unit tests (`test-smk-functionNameDS.R`) with happy + unhappy paths
4. Run `devtools::check(args = '--no-tests')` and `devtools::test()` in dsBase
5. Build package: `devtools::build()`

### Step 2 — Install refactored dsBase on Armadillo
6. Ensure `inst/DATASHIELD` has `default.datashield.privacyControlLevel="permissive"` before building. **Must be the literal string `"permissive"`** — other values like `"banana"` will not work for all functions (e.g. `levelsDS` checks for `'permissive'` explicitly).
7. Build package: `devtools::build()` in dsBase
8. Copy the built tar to dsBaseClient as `dsBase_7.0.0-permissive.tar.gz` (this is the filename the CI pipeline references in `armadillo_azure-pipelines.yml`)
9. Install on local Armadillo: `armadillo.login("http://localhost:8080")` then `armadillo.install_packages(paths = "<path-to-tar>", profile = "default")`

### Step 3 — Client-side (dsBaseClient repo)
7. Create feature branch from `v7.0-dev` in dsBaseClient
8. Ensure `R/utils.R` exists (copy from `v7.0-dev-colnames` branch if needed)
9. Refactor client functions:
   - Replace datasource boilerplate → `.set_datasources()`
   - Remove `isDefined()`, `checkClass()`, `isAssigned()` calls
   - Remove MODULE 5 blocks
   - Replace null-input checks with `.check_df_name_provided()` where applicable
10. Update/add client end-to-end tests with happy + unhappy paths
11. Run `devtools::check(args = '--no-tests')` in dsBaseClient
12. Run tests against Armadillo, **not DSLite**. Set the driver to `"ArmadilloDriver"` in `tests/testthat/connection_to_datasets/login_details.R` (default is `"DSLiteDriver"`). DSLite uses whatever dsBase is installed locally in R, which may not match the refactored version on Armadillo. Run `devtools::test(filter = "smk-|disc|arg")` for affected functions (requires refactored dsBase to be installed on Armadillo)

### Step 4 — Verify
13. Run full test suite to check no regressions
14. Run perf tests at 30 seconds (default): `devtools::test(filter = "perf-")`
15. Compare perf results against the v7.0-dev branch baseline to detect any regressions from the refactoring

### Step 5 — Pre-merge audit (mandatory)

Before marking a batch complete:

1. **Diff every touched `test-smk-*.R` / `test-arg-*.R` / `test-disc-*.R` against the branch base.** For each removed `expect_*` assertion, confirm it falls into one of:
   - (a) redundant — the same behaviour is covered by another assertion still present in the same file;
   - (b) replaced — a new assertion was added that covers the same server-side behaviour (e.g. `ds_expect_variables` replacing `$is.object.created`, or `ds.summary`/`ds.class` on the newobj).

   Any removed assertion that doesn't fall into (a) or (b) is a coverage loss that must be restored before merge.

2. **Inspect every `test_that(…)` block touched by the refactor.** Each block must still contain at least one `expect_*` assertion after the refactor. Blocks stripped to just the function call are not acceptable — add `ds_expect_variables`, `expect_no_error`, or a downstream property check.

3. **Diff every signature of every exported function touched.** Confirm no parameter was added in the middle of the signature; new parameters must be at the end (see "Adding new parameters to existing exported functions" above).

4. **Confirm docs match signature.** `@param` blocks present for every parameter, no stale `@param` for removed arguments, `@return` not promising MODULE 5 output fields.

5. **Grep for residual patterns that should have been removed:** `isDefined(`, `isAssigned(`, `CLIENTSIDE MODULE`, `testObjExistsDS`, `is.object.created`, `validity.check`, `studyside.messages` in source files (acceptable in test files only if the MODULE 5 pattern is being deliberately preserved with a replacement).

## Key Files

### Reference implementation
- Client refactored: `git show v7.0-dev-colnames:R/ds.colnames.R`
- Server refactored: `~/git-repos/ds-core/dsBase/R/colnamesDS.R`
- Client utils: `git show v7.0-dev-colnames:R/utils.R`
- Server utils: `~/git-repos/ds-core/dsBase/R/utils.R`
- Server tests: `~/git-repos/ds-core/dsBase/tests/testthat/test-smk-colnamesDS.R`
- Client tests: `~/git-repos/ds-core/dsBaseClient/tests/testthat/test-smk-ds.colnames.R`

### Guides
- `~/git-repos/ds-core/dsBaseClient/REFACTOR_GUIDE.md`
- `~/git-repos/ds-core/dsBase/.github/pull_request_template`

## Verification

For each batch:
1. Run server-side unit tests: `cd dsBase && devtools::test(filter = "functionNameDS")`
2. Run client-side smoke tests: `cd dsBaseClient && devtools::test(filter = "smk-ds.functionName")`
3. Run `devtools::check(args = '--no-tests')` on both packages
4. Run full test suite: `devtools::test(filter = "smk-|disc|arg")` to check no regressions
5. Run perf tests: `PERF_DURATION_SEC=2 devtools::test(filter = "perf-")` to verify no performance regression

## Follow-up: replace clientside `*.transmit` deserialisation via `eval(parse())`

**TODO (dedicated cross-cutting branch, not part of any batch):** several server functions
receive clientside **values** (not object names) serialised as comma-separated strings and
deserialise them with `strsplit(...)` → `eval(parse(text=...))` → `as.numeric(...)`
(e.g. `matrixDS`: `mdata.transmit`/`nrows.transmit`/`ncols.transmit`; `matrixDiagDS`:
`x1.transmit`/`nrows.transmit`; others findable by grepping for `eval(parse` next to
`strsplit`). The `eval(parse())` is unnecessary — for every legitimate input it is
equivalent to direct conversion:

```r
mdata <- as.numeric(unlist(strsplit(mdata.transmit, split=",")))
```

Replacing it removes the last code-execution path through these functions and lets the
`nfilter.stringShort` guards on the `*.transmit` parameters be dropped too (they are
currently kept precisely because those strings still reach `parse()`). Precedent: batch-4
already did this for the literal-scalar case in `BooleDS`
(`suppressWarnings(as.numeric(V2.name))`).

Do this as one consistent pass across every function using the idiom (the same pattern
appears in not-yet-refactored functions, e.g. `ds.rep`/`ds.seq` and the random-generation
batch), rather than piecemeal within a batch.

## Decision: keep client-side `checkClass` and `isDefined`

`checkClass()` stays. Assign functions (`ds.c`, `ds.cbind`, `ds.dataFrame`, `ds.list`, `ds.rbind`) get nothing back from `datashield.assign`, so a pre-call `classDS` lookup is the only way to check class consistency across studies; `ds.summary` needs it for dispatch and `glmChecks` for offset/weights. `isDefined()` stays because `glmDS1` and siblings do not validate formula terms server-side — removing it would degrade a missing-variable error to R's generic "object not found". Rename/split/merge with `.checkClassConsistency()` judged marginal and not planned.

## 7.0.0 deprecation (done, branch `refactor/deprecate-functions` in both repos)

**Client, defunct via `lifecycle::deprecate_stop("7.0.0", ...)`** (badge, `@keywords internal`, `...` signature so old calls reach the message): ds.listOpals, ds.setDefaultOpals, ds.listServersideFunctions, ds.meanByClass, ds.recodeLevels, ds.subset, ds.subsetByClass, ds.table1D, ds.table2D, ds.vectorCalc, ds.look, ds.message, ds.testObjExists, ds.dataFrameFill (→ `ds.standardiseDf`, from 6.4). `ds.ranksSecure` was already removed. `@import DSI` stays in the `ds.listServersideFunctions` stub (moving it changes NAMESPACE).

**Client helpers deleted:** meanByClassHelper0a/0b/1–4, subsetHelper, isAssigned, ds.extractQuantiles, colPercent, rowPercent, R/secure.global.ranking.md.

**Server functions removed:** recodeLevelsDS, subsetDS, subsetByClassDS (+ helpers 1–3), table2DDS, messageDS, testObjExistsDS, dataFrameFillDS, ranksSecureDS1–5, blackBoxDS, blackBoxRanksDS, minMaxRandDS, extractQuantilesDS1–2.

**Server functions kept despite the wiki list:** `table1DDS` (used by `ds.summary` for factor counts), `checkNegValueDS` (used by `glmChecks` for negative weights), `vectorDS` (`inst/DATASHIELD` maps the server's `c` to it, so every vector argument in a client call goes through it).

**Live-code changes:** `ds.lexis` no longer returns Note3/Note4 (pointed at `ds.message`); `ds.changeRefGroup` examples/test use `ds.recodeValues`; `asFactor`/`asFactorSimple` tests use `ds.table`; `ds.make` and `ds.meanSdGp` docs no longer reference defunct functions.

## Follow-up: settle the `newobj` default-and-validate helper

Dropping MODULE 5 also dropped the only thing that rejected a non-character `newobj`. Nothing client-side ever validated it — every `newobj` in `R/` is just an `is.null()` default — so the `expt`/`expt_dgr` tests that pass `newobj = 23` and expect an error started failing (batch 4, `ds.dataFrameSort`). Fixed there with `.check_newobj_name()` + `.set_newobj_name()` in `R/utils.R`.

Two things to settle once the batches are done, not per-batch:

- **Naming.** `.set_newobj_name()` both applies the default and validates, but `set` reads as a command and hides that it can abort. Prefer a name describing what it returns (e.g. `.resolve_newobj_name()`). Note `.set_datasources()` has the identical smell, so decide both together and rename in one commit.
- **Coverage.** Only `ds.dataFrameSort` calls it. Every other function that lost MODULE 5 has the same gap and will fail the same way if its tests assert on a bad `newobj`. Sweep them all at the end.

**Ordering is load-bearing:** apply the default *before* validating. `newobj = NULL` is a valid input meaning "use the default", so validating first makes no-argument calls abort with the wrong message and breaks the `arg-` tests (e.g. `test-arg-ds.dataFrameSort.R:24` expects the server-side `There are some DataSHIELD errors` message). This is exactly why the two steps are worth keeping in one helper rather than as two calls at ~40 sites.

A purer alternative, deliberately not taken: put the default in the signature (`newobj="dataframesort.newobj"`) so the helper only validates. It changes behaviour for an explicit `newobj=NULL` (abort instead of default) and diverges from the NULL idiom used everywhere else — evaluate as its own decision.
