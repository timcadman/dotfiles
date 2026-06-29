# Reviewing dsBase / dsBaseClient refactor PRs

A reviewer checklist for the "perf-batch" refactors, derived from `REFACTOR_GUIDE.md`.
These refactors ship as a **pair**: a dsBase (server) PR and a dsBaseClient (client) PR
for the same batch. They move server-state validation (object existence, class checks)
from client to server. Review the pair together against the batch's base (`origin/v7.0-dev`).

## 1. Pairing, build & CI
- [ ] The matching server PR (dsBase) and client PR (dsBaseClient) both exist and are for the **same batch**; client `call("XDS", …)` args line up with the server signature and returns.
- [ ] Merge-order dependency noted: the client depends on the **refactored dsBase being installed**. If the server side isn't merged to `v7.0-dev` yet, CI must install the matching dsBase build/ref — **not stale `v7.0-dev`** (this exact gap causes mass `varDS`-style failures). See `run-dsbaseclient-tests-locally.md`.
- [ ] Tests were run against **Armadillo with the matching refactored dsBase**, not DSLite.

## 2. Client-side diff (`ds.X`)
- [ ] Datasource boilerplate (`datashield.connections_find()` + DSConnection class check) replaced by `datasources <- .set_datasources(datasources)`.
- [ ] `isDefined()`, `isAssigned()`, and client-side `checkClass()` + type guards **removed** (server handles these now).
- [ ] MODULE 5 "CHECK KEY DATA OBJECTS SUCCESSFULLY CREATED" block removed.
- [ ] Redundant `checks` parameter removed (and its conditional block) where its only purpose was gating the now-removed calls.
- [ ] Per-study `datashield.aggregate(datasources[i], …)` loops collapsed into a single multi-source call (e.g. `ds.isNA`).
- [ ] **Kept**: null-input checks (or `.check_df_name_provided()`), default `newobj` naming, the server-call dispatch, and any genuinely client-side logic (alias normalization, pooling, etc.).

## 3. Server-side diff (`XDS`)
- [ ] Correct pattern applied: **A** (already takes a string name) → `eval(parse())` replaced by `.loadServersideObject(x)`; **B** (received a resolved object) → param renamed to a string `x`, body loads `xvect <- .loadServersideObject(x)`, and the **client** dispatch switched from `as.symbol(paste0(...))` to `call("XDS", x)`.
- [ ] `.checkClass(obj=…, obj_name=x, permitted_classes=…)` added where the client previously enforced type — **and `permitted_classes` matches the types the original function accepted** (must not silently narrow behaviour; functions accepting any class use `.loadServersideObject()` only, no `.checkClass()`).
- [ ] Disclosure controls / privacy checks (`listDisclosureSettingsDS()`, `nfilter.*`) untouched.
- [ ] **Minimal diff**: no body-variable renames, no comment/whitespace restyle, no bundled cleanups.

## 4. Return contract & `classConsistencyCheck`
- [ ] Where the client used to `checkClass()` for routing/format/consistency, the server now returns `class = class(obj)` and the client reads `result$class` (no extra round trip). Exception: true composite dispatchers (e.g. `ds.summary`) that need the class **before** choosing the server fn may keep one lightweight `call("classDS", x)`.
- [ ] `classConsistencyCheck` parameter presence/default is correct: **TRUE** for genuinely different permitted types (data.frame+matrix, factor+character+integer); **FALSE** for numeric/integer-only; **no parameter** when only one class is permitted.
- [ ] Cross-study check uses the shared `.checkClassConsistency()` helper, not an inlined check.
- [ ] **`class` is stripped before returning to the user** — verify at *every* `return()` site that `class` (or `class.x`/`class.index`) is not a named element of the returned list.

## 5. Behaviour preservation & test-coverage audit (the critical pass)
- [ ] No change to accepted input types or returned values beyond the added `class` field (checked against the pre-refactor function).
- [ ] **Diff every touched `test-smk-*.R` / `test-arg-*.R` / `test-disc-*.R` against base.** Each removed `expect_*` is either (a) redundant (same behaviour asserted elsewhere in the file) or (b) replaced with an equivalent assertion. Any other removal is a coverage loss → must be restored.
- [ ] **Validation moved server-side is relocated, not dropped.** A class/type/validity check that was asserted in `test-arg-ds.X.R` (client-side arg check) but is now enforced server-side via the call must be **moved to `test-smk-ds.X.R`** (where it surfaces as a server-originated DataSHIELD error) — not simply deleted from the arg test.
- [ ] Every `test_that()` block touched still has **≥1 assertion** (not stripped to just the function call).
- [ ] MODULE 5 removals (`$is.object.created` / `$validity.check`) replaced with equivalents (`ds_expect_variables(...)` / `expect_no_error(ds.class(newobj))`) inside the same block.

## 6. Tests present
- [ ] **Server unit** (`test-smk-XDS.R` in dsBase): happy path; nonexistent object → `expect_error(…, "does not exist")`; wrong type → `expect_error(…, "must be of type")` (where `.checkClass` used).
- [ ] **Client e2e** (`test-smk-ds.X.R`): happy path passes; nonexistent / wrong type → `expect_error(…, "DataSHIELD errors")`; client-side message expectations updated to server-originated ones.
- [ ] **Client smoke** exists for every refactored function (create if missing), following the `connect.studies.dataset.*` → setup → test → shutdown → `disconnect` pattern.
- [ ] **Client perf** (`test-perf-ds.X.R`) exists for every refactored function and **replicates the smoke test** (same `connect`/`disconnect`, same call/params/columns); **no Arjuna copyright header** on new files.
- [ ] **New functions get a perf test.** If a function had no performance test before the refactor (e.g. newly created `expDS`/`logDS`, or any function lacking `test-perf-ds.X.R`), one must be **added** — not just preserved where it already existed.

## 7. Signatures, docs & residuals
- [ ] New parameters appended at the **end** of the signature — never inserted mid-signature.
- [ ] `@param` present for every parameter, no stale `@param` for removed args, `@return` no longer promises MODULE 5 fields.
- [ ] Grep source (not test) files for residuals that should be gone: `isDefined(`, `isAssigned(`, `CLIENTSIDE MODULE`, `testObjExistsDS`, `is.object.created`, `validity.check`, `studyside.messages`.

## 8. Authorship
- [ ] `@author Tim Cadman, Genomics Coordination Centre, UMCG, Netherlands` added to **every file you actually refactored — including files that had no previous `@author` line** — as a separate `docs: updated authorship` commit. Not added to files left untouched by the batch.

## 9. Known-issue / dependency awareness
- [ ] PR isn't blocked by a deferred dependency: `ds.isValid`/`isValidDS` stays deferred until its internal callers (`replaceNaDS`, `quantileMeanDS`, `rowColCalcDS`) are refactored; batch-9 plot fns (`ds.heatmapPlot`/`ds.contourPlot`/`ds.densityGrid`) still use `as.symbol(...)` for `rangeDS` until `rangeDS` is refactored.
