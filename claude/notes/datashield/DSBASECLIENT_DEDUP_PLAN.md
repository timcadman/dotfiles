# dsBaseClient: Duplicated-Logic Extraction Plan

> Source of truth alongside `REFACTOR_GUIDE.md` and `ARG_NAMING_STANDARDIZATION.md` in this
> same folder. Do not commit copies of this file into dsBase or dsBaseClient.

## Context

Found while reviewing batch-7: several validation/boilerplate patterns are duplicated
across many `ds.*` functions, in some cases even though a shared helper for exactly that
pattern **already exists in `R/utils.R` and is simply unused** almost everywhere. This is a
migration/adoption task more than a design task — the hard part (writing the helper) is
mostly already done.

All numbers below verified directly via grep against the current `dsBaseClient` checkout,
not estimated.

## 1. Datasource-lookup boilerplate — 56 functions not yet migrated

`.set_datasources()` already exists in `R/utils.R` and is used by 67 functions. 56 more
still hand-roll the pre-refactor version inline, byte-for-byte identical each time:

```r
if(is.null(datasources)){
  datasources <- datashield.connections_find()
}
if(!(is.list(datasources) && all(unlist(lapply(datasources, function(d) {methods::is(d,"DSConnection")}))))){
  stop("The 'datasources' were expected to be a list of DSConnection-class objects", call.=FALSE)
}
```

Confirmed present in (non-exhaustive list, ~56 total per `grep -l "datashield.connections_find()" R/ds.*.R`):
`ds.assign`, `ds.auc`, `ds.boxPlot`, `ds.boxPlotGG*` (5 variants), `ds.bp_standards`,
`ds.colnames`, `ds.contourPlot`, `ds.densityGrid`, `ds.exists`, `ds.dmtC2S`, `ds.elspline`,
`ds.getWGSR`, `ds.extractQuantiles`, `ds.glmPredict`, `ds.hetcor`, `ds.histogram`,
`ds.isValid`, `ds.heatmapPlot`, `ds.igb_standards`, `ds.lexis`,
`ds.listServersideFunctions`, `ds.listDisclosureSettings`, `ds.look`, `ds.lspline`,
`ds.make`, `ds.mdPattern`, `ds.message`, `ds.meanByClass`, `ds.ns`, `ds.metadata`,
`ds.rBinom`, `ds.rNorm`, `ds.qlspline`, `ds.rowColCalc`, `ds.rm`, `ds.sample`,
`ds.recodeLevels`, `ds.scatterPlot`, `ds.rUnif`, `ds.setSeed`, `ds.setDefaultOpals`,
`ds.subsetByClass`, `ds.subset`, `ds.rPois`, `ds.table2D`, `ds.tapply.assign`,
`ds.table1D`, `ds.testObjExists`, `ds.table`, `ds.vectorCalc`, `ds.tapply`, `ds.glmSummary`.

**Exclude 11 from priority** — already on the deprecation list in `REFACTOR_GUIDE.md`:
`ds.look`, `ds.meanByClass`, `ds.message`, `ds.recodeLevels`, `ds.setDefaultOpals`,
`ds.subset`, `ds.subsetByClass`, `ds.table1D`, `ds.table2D`, `ds.vectorCalc`,
`ds.listServersideFunctions`. Migrating these is wasted effort ahead of their removal.

**Action**: pure adoption — replace the 6-line block with `datasources <- .set_datasources(datasources)`
in each of the remaining ~45 functions. No new helper design needed.

## 2. `newobj` default-and-validate — helper exists, used by 1 of ~46+ candidates

`R/utils.R` already defines both halves of this:
```r
.check_newobj_name <- function(newobj) { ... }        # line 76
.set_newobj_name <- function(newobj, default) { ... }  # line 94, calls .check_newobj_name internally
```
Confirmed only `R/ds.dataFrameSort.R` calls either of them. At least 46 other functions
hand-inline the same 3-line shape with a different default string each time:
```r
if(is.null(newobj)){
  newobj <- "<funcname>.newobj"
}
```
Confirmed present in (sample; pattern holds broadly per grep):
`ds.abs`, `ds.cbind`, `ds.rbind`, `ds.list`, and the rest of the ~46+ matching
`grep -lE 'newobj\s*<-\s*"[a-zA-Z._]+\.newobj"' R/ds.*.R` (a fuller manual pass found ~60
when counting looser variants of the same shape — 46 is the conservative, exact-regex-verified
floor).

This is exactly what `REFACTOR_GUIDE.md`'s own "Follow-up: settle the newobj
default-and-validate helper" section already flags as planned-but-not-done — this entry
confirms the concrete scope (46+ call sites) rather than leaving it as a vague note. That
section also flags two naming/design questions worth resolving *before* the migration, not
after (see `REFACTOR_GUIDE.md` for the full reasoning):
- `.set_newobj_name()`'s name reads as a command but it can abort (validates too) — consider
  renaming to something like `.resolve_newobj_name()` first, so the migration only needs to
  happen once.
- Apply the default *before* validating, not after — `newobj = NULL` is a legitimate "use
  the default" signal, not an error case (see the ordering bug already documented for
  `ds.dataFrameSort`'s `expt_dgr` test in `REFACTOR_GUIDE.md`).

**Action**: resolve the naming question, then mechanically replace the 3-line pattern with
`newobj <- .set_newobj_name(newobj, "<funcname>.newobj")` (or renamed equivalent) across all
~46+ call sites.

## 3. Multi-study consistency checks — `ds.cbind`/`ds.dataFrame` only (2 functions, not 3)

**Correction to an earlier same-session estimate**: `ds.rbind.R` was initially reported as
sharing this block too — re-checked, it only shares the smaller `classConsistencyCheck`
sub-block (already covered under `ARG_NAMING_STANDARDIZATION.md`'s existing-template
finding), not the fuller column-name/row-count logic. The real duplication is 2 functions,
not 3.

`ds.cbind.R` and `ds.dataFrame.R` both contain the same ~40-line block: class-consistency
loop + duplicate-column-name warning loop + row-count-mismatch check across all studies —
duplicated closely enough that `ds.dataFrame.R`'s row-count check still carries the comment
`"# check that the number of rows is the same in all componets to be cbind"`, a literal
copy-paste leftover referencing the wrong function.

**Action**: extract `.checkMultiObjectConsistency(datasources, x, classConsistencyCheck)`
into `R/utils.R`, call from both `ds.cbind.R` and `ds.dataFrame.R`. This is genuinely new
helper code (unlike #1/#2), but small in scope — 2 call sites.

## Not pursued further

`notify.of.progress` boilerplate is single-line per call site — too trivial to extract.
No other duplicated-block patterns turned up in the scan beyond the three above.

## Sequencing recommendation

1. #1 and #2 first — both are pure mechanical adoption of helpers that already exist and
   are already tested via whichever function currently uses them (`ds.dataFrameSort` for
   #2). Lowest risk, highest volume, no design work.
2. Resolve the `.set_newobj_name()` naming question (part of #2) before doing the mechanical
   sweep, so it's not done twice.
3. #3 last — the only item requiring new helper code and design review.
4. Coordinate with `ARG_NAMING_STANDARDIZATION.md` where they overlap: `classConsistencyCheck`
   template adoption (5 functions) and the `.set_datasources()`/`newobj` migrations here
   touch many of the same files — batching them per-file (one pass per function covering
   both) is likely more efficient than two separate passes.
