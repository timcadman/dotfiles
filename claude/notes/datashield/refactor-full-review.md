# Full refactor review (batches 1–10) — findings to triage

Review of dsBase + dsBaseClient working trees on `refactor/perf-batch-10` (2026-09-21) against
`REFACTOR_GUIDE.md`, baseline tag `6.3.5`. Read-only; nothing here is fixed unless marked.
Note: client tag `6.3.5` is not an ancestor of v7 HEAD — some client diffs are 6.3.x-only fixes
missing on v7 (e.g. `on.exit(options(warn))` in `glmChecks`, `ds.table`), not refactor regressions.

## Done in batch 10 (2026-09-21, uncommitted)
rowColCalc per-study loops removed (numeric-column check now in `rowColCalcDS`); lexisDS2
`entryCol=NULL` defaults to 0; tableDS/tableDS.assign `exclude` eval(parse) → string split
("NA" → NA, consistent); rangeDS refactored + 3 plot callers use `call()`; isValidDS NA/NULL
tests restored; Arjuna headers removed from 9 batch-10 server tests; client `utils.R` restored
to branch version; `test-perf-ds.isValid.R` staged; `Rplots.pdf` removed; CI tarball
`dsBase_7.0.0-permissive.tar.gz` rebuilt from batch-10 dsBase; guide updated.
Still open from batch 10: perf-profile rows (opal: lexis, rowColCalc, table, tapply,
tapply.assign; both: isValid; rowColCalc reference re-measure) — need Azure CI numbers.

## PR plans (4 PRs, each a dsBase + dsBaseClient pair)
Conventions for every PR: minimal diff; tests use `datashield.errors()` + specific message;
new files carry no Arjuna header; Tim Cadman @author on every file refactored (incl. files with
no previous author); run `devtools::test(filter="smk-")` in dsBase, then install a permissive
build on local Armadillo and run affected client `smk|arg|disc` tests; don't rebuild the tracked
tarballs (`dsBase_7.0.0*.tar.gz`) — do that once, in whichever PR merges last; re-run
`devtools::document()` after each rebase instead of hand-merging Rd. Item numbers → triage below.

### PR 1 — Fixes (branch `refactor/fixes` from origin/v7.0-dev; can start now)
1. #1 asListDS: end with `invisible(NULL)`; server + client tests that the return has no data.
2. #12 `.loadServersideObject`: stop on NULL object ("is NULL"); add `call. = FALSE` to the
   "does not exist" stop (#37). Full test run (touches every fn); check no optional arg is
   legitimately loaded as NULL.
3. Class-rule restorations:
   - #4 meanDS/varDS permit "logical"; restore `c(NA,...)` tests.
   - #8 glm/glmSLMA/glmer/lmer/gamlss data classes → c("data.frame","list"); server test with a
     list (check surrounding code handles lists).
   - #9 lengthDS, #10a dimDS: drop .checkClass (any class), keep returning class.
   - #10c meanSdGpDS index permits "numeric"; test with double 0/1 index.
4. Behaviour restorations:
   - #6 corDS/covDS ignore y when x is matrix/df; client warns after the call using returned
     class.
   - #7 ds.changeRefGroup sends `as.character(ref)`; test with levels "0","2","5", ref=2.
   - #13 levelsDS: privacy check back to first line.
   - #14b seqDS: FROM/TO/BY/LENGTH.OUT via plain `as.numeric()`.
   - #14c BooleDS: map "TRUE"/"FALSE"/"NA" before numeric/name handling.
   - #16 glmChecks: port 6.3.5 `on.exit(options(warn=old))` (70b467b2); check ds.table too.
5. Cleanups: #15c lmerSLMA comment ≤3 lines + revert whitespace-only lines; #32 ds.dim /
   ds.recodeValues examples; #33 dataFrameSortDS author order; #34 stale docs; #35 gamlssDS/
   miceDS obj_name.
6. Not included: #10b/d/e, #11, #14a, #15a/b (accepted).
7. #5 DECIDED: revert to 6.3.5 — corDS/covDS accept factor x (and y), correlated on level
   codes; factor x without y errors like numeric. DONE in code; tests pending.
8. #43 ADDED to PR 1: ds.mdPattern combine aligns columns by name to study 1 before pooling
   (stops if variable sets differ), replacing the "pooling by position" warning. DONE in code;
   test pending: pooled summary row == per-study summary rows summed by variable name (CNSIM
   already has differing column orders).

### PR 3 — Tests (after batch 10 merges)
1. #23 client smk (batches 1–7, ~50 fns): missing object; wrong type; happy path per distinct
   permitted class; classConsistencyCheck mismatch (one study converted) aborts TRUE / passes
   FALSE.
2. #24 server tests: same coverage for every server fn; restore batch-1 tests from f6f6b0d4.
3. #25 ds.length NULL-x/type arg tests; move changeRefGroup wrong-type to smk; (ds.seq arg
   test updated in PR 2 with #38).
4. #26 merge: two specific smk tests replacing the ambiguous arg assertion.
5. #27 levels disc test via asFactorSimple; #31 definition_tests MODULE 5 asserts → specific
   datashield.errors() checks (run dgr shard with dsDanger).
6. #28 perf tests replicate smoke (~30), fix boxPlotGG perf, add glm/glmSLMA/glmerSLMA/lmerSLMA
   perf; #29 `perf.testduration()` in all perf tests + `.load.pref()` fix; #30 remove Arjuna
   headers (15 files). Profile rows for new/changed keys from CI.

### PR 4 — Batch 11 + renames + guide (after PRs 1 and 3 merge)
1. #40 refactor ds.auc, ds.bp_standards, ds.igb_standards, ds.mdPattern, ds.exists
   (+ servers) under the guide rules, full tests; ds.rm, ds.listDisclosureSettings get only
   the `.set_datasources()` swap. (ds.testObjExists moved to PR 5 as defunct.)
2. #41 remove ranksSecureDS1-3/5, blackBoxDS, blackBoxRanksDS, minMaxRandDS,
   extractQuantilesDS1/2, checkNegValueDS, client ds.extractQuantiles, and their DATASHIELD
   entries. Keep standardise-df fns.
3. #37 camelCase all client helpers in one commit (.resolveDatasources, .resolveNewobjName,
   .checkNewobjName, .expandToStudies, .getDatasources, .verifyDatasources,
   .checkDfNameProvided, .poolMdPatterns); move .checkDisclosureSize to dsBase utils.R.
4. #36 restore only deleted comments that explained non-obvious code; matrixDimnamesDS remove
   commented-out guard.
5. #42 guide updates (rules from #20/#40, batch 11, authorship, stale sections).
5a. MOVE 5a to its own PR ("PR 5 — deprecation/defunct"), not PR 4. DECIDED: all deprecated
   become DEFUNCT in v7 (lifecycle::deprecate_stop stubs). Definitive list:
   client defunct: ds.listOpals, ds.setDefaultOpals, ds.listServersideFunctions,
   ds.meanByClass, ds.recodeLevels, ds.subset, ds.subsetByClass, ds.table1D, ds.table2D,
   ds.vectorCalc, ds.look, ds.message, ds.ranksSecure (already removed; add stub).
   delete (internal): meanByClassHelper0a/0b/1/2/3/4, subsetHelper, checkClass, isAssigned
   (isDefined too, unless ds.dataFrameFill stays), ds.extractQuantiles.
   server remove: recodeLevelsDS, vectorDS, subsetDS, subsetByClassDS (+ subsetByClassHelper1-3),
   table1DDS (after PR2 #22), table2DDS, messageDS, + #41 list; drop from inst/DATASHIELD.
   Tests: remove their test files; fix ds.message use in test-smk-ds.lexis.R; ds.make doc
   mentions messageDS.
   DECIDED: ds.testObjExists → defunct (remove from batch 11; remove testObjExistsDS and its
   test files incl. test-smk-ds.testObjExists-discordant.R). ds.dataFrameFill → defunct
   (replacement ready for v7; name it in the deprecate_stop `with=` arg); remove
   dataFrameFillDS; isDefined can then be deleted. Facts: all 12 current
   `.Deprecated()` calls date from 2019-09 (listOpals, setDefaultOpals, listServersideFunctions)
   or 2020-05 (the other 9) — both first released in 6.0.0, i.e. deprecated for 5+ years.
   ds.testObjExists: no callers in either package (only its own tests + function-list test).
   Lifecycle (decided 2026-09-21): add `lifecycle` to client Imports; replace all 12
   `.Deprecated(...)` with `lifecycle::deprecate_warn("7.0.0", "ds.x()", "ds.y()")`; add a
   defunct stub `ds.ranksSecure()` → `lifecycle::deprecate_stop("7.0.0", "ds.ranksSecure()")`
   (removed in 5cb506bb). ds.dataFrameFill → deprecate_warn (to be deprecated). Update tests
   that expect "'ds.x' is deprecated" (e.g. ds.message in test-smk-ds.lexis.R).
5b. ds.rm, ds.listDisclosureSettings: only swap datasource boilerplate for `.set_datasources()`
   (nothing else to refactor: rmDS reports missing objects itself; no class to check).
   ds.table1D/table2D stay deprecated (tracker "refactor" is stale). ds.extractQuantiles
   removed with ranksSecure servers (unexported; nothing to deprecate).
6. Rebuild tracked tarballs from final dsBase; full smk/arg/disc + perf run.

### PR 2 — Performance / design (last, after PRs 1, 3 and 4 merge)
1. #17 new aggregate helper `getClassAllObjectsDS(x.names)` → class + colnames per element in
   one call (.loadServersideObject, no privacy gate); register in inst/DATASHIELD; server tests.
2. #20 classConsistencyCheck rule for all fns:
   - aggregate fns read `class` from their result; assign fns call the helper once when TRUE.
   - add: batch 1 abs/exp/log/sqrt (FALSE), asDataMatrix/asLogical (TRUE); batch 7 glm,
     glmSLMA, glmerSLMA, lmerSLMA, gamlss, mice (TRUE).
   - batch 4: explicit server .checkClass in cDS, listDS, cbindDS, rbindDS, dataFrameDS; remove
     DataSHIELD.checks (ds.replaceNA's internal call → classConsistencyCheck=FALSE); equal-row
     check → server stop in cbindDS/dataFrameDS; duplicate-colname warning from helper.
   - remove param from ds.numNA, ds.length, ds.dim (any class).
   - #20c ds.meanSdGp checks class.index only.
3. #21 remove `checks` + glmChecks; move existence / numeric offset+weights / all-NA / negative
   weights checks into glmDS1, glmSLMADS1, glmerSLMADS2, lmerSLMADS2 (supersedes #16's
   glmChecks fix once merged).
4. #18 ds.replaceNA: numNA length check → replaceNaDS stop(); delete client loop.
5. #22 ds.summary: helper for class lookup; one multi-study call per server fn; tableDS instead
   of table1DDS; fix logical branch `1:2`; logical smoke test; verify INVALID studies.
6. #19a BooleDS/dataFrameSubsetDS1/2: vectorised `match.fun(op)(V1, V2)`; verify old vs new.
   #19b glm family offset/weights → `cbind(.loadServersideObject())`; check what ds.glm allows
   in formulas before touching the model.variables loop.
7. #38 `*.transmit` sweep: matrixDS, matrixDiagDS, repDS, dmtC2SDS (conversion lookup), client
   ds.seq; drop matching nfilter.stringShort guards; verify old vs new per fn.
8. #39 newobj: default-then-validate helper in all 58 client fns; client-only validation
   (character, length 1, `make.names(x) == x`).
9. Re-measure perf on CI for every changed call.

## Still to do after the fixes PRs (2026-10-13)
dsBase `refactor/fixes` merged into `v7.0-dev` as #515 (`7cfab531`) and the branch was deleted.
Three planned changes were stashed, never pushed, and are NOT in `v7.0-dev`:
- #5 corDS/covDS accept factor x and y (+ a test in each server test file). In dsBase
  `stash@{0}` (WIP on refactor/fixes, 2026-09-25). Open decision first: any factor (6.3.5
  behaviour), two-level factors only, or keep rejecting. The client test "cor accepts a factor
  variable" was removed from client `refactor/fixes` so its CI passes against `v7.0-dev`;
  restore it (and add one for ds.cov) with the server change.
- #1 remove `asListDS` from AggregateMethods in `inst/DATASHIELD` (it stays under
  AssignMethods). Same dsBase stash. Needs a new branch from `v7.0-dev`.
- #43 ds.mdPattern pools by variable name. In dsBaseClient `stash@{0}` (WIP on
  refactor/perf-batch-11): `R/ds.mdPattern.R` + a test; not yet run against a backend.

## Found during batch 11 (2026-09-22)
- #43 ds.mdPattern(type="combine") pools patterns by column POSITION, but mice::md.pattern
  orders columns by missingness, which differs per study → variables can be mixed in the pooled
  table (warns "Variable names differ across studies. Pooling by position."). Pre-existing on
  v7.0-dev (ds.mdPattern.R:168). TODO: align columns by name before pooling; test with studies
  whose missingness order differs.

## Triage (2026-09-21, for the tidy-up PR)
- #1 asListDS leak — VALID, fix: `invisible(NULL)` + tests that return carries no data.
- #2 ds.colnames client — VALID, DONE in batch 10 (colnames PR was closed): body from
  v7.0-dev-colnames, smoke tests now check specific server errors + wrong type.
- #3 dsBase_7.0.0.tar.gz stale — VALID, DONE: rebuilt (standard, "banana") from batch-10 dsBase.
- #4 meanDS/varDS reject logical — VALID, TODO: add "logical" to permitted classes in meanDS and
  varDS (matrix stays rejected); restore all-NA logical server tests (`c(NA,...)`, changed to
  `NA_real_` in 7870e5b2); add client test. Note: all-NA study gives NaN combined mean (as 6.3.5).
- #5 corDS/covDS reject factor vector x (and y) — DECISION NEEDED. 6.3.5 accepted factor x
  (client check numeric|integer|factor; y never type-checked) and correlated on level codes via
  cbind. Options: (1) re-allow "factor" (exact old behaviour; 2-level = point-biserial, >2 levels
  meaningless), (2) keep rejection (user runs ds.asNumeric first), (3) allow 2-level factors only.
- #6 ds.cor/ds.cov no longer ignore y when x is matrix/df — VALID, TODO: corDS/covDS ignore y
  when x is matrix/data.frame; client warns "y will be ignored..." after the call when y given
  and returned class is matrix/data.frame (no extra round trip). Add smoke tests.
- #7 ds.changeRefGroup numeric ref = position — VALID, TODO: client sends `as.character(ref)`;
  add test where level names differ from positions (e.g. levels "0","2","5", ref=2).
- #8 glm family data classes — VALID, TODO: permitted_classes c("data.frame","list") (not matrix)
  in glmDS1/2, glmSLMADS1/2, glmerSLMADS2/.assign, lmerSLMADS2/.assign, gamlssDS. Measured:
  glm/glmer/lmer/gamlss all accept data.frame + list, all reject matrix. miceDS unchanged. Add a
  server test passing a list (verify the surrounding server code handles lists).
- #9 lengthDS permitted classes — VALID, TODO: drop `.checkClass` (accept any class, like
  classDS/namesDS); keep returning `class`. Update server test (e.g. Date accepted).
- #10a dimDS rejects array/table/vector — VALID, TODO: drop `.checkClass` (any class), keep
  returning `class`; update server/client wrong-type tests accordingly.
- #10b densityGridDS numeric/integer only — ACCEPTED, no change (logical/character grid is
  meaningless; matches rangeDS and other plot fns).
- #10c meanSdGpDS rejects double grouping var — VALID, TODO: add "numeric" to index
  permitted classes (body does as.factor); server test with double 0/1 index.
- #10d asLogicalDS class names vs is.numeric() — ACCEPTED, no change (only haven_labelled-type
  objects differ; consistent with rest of refactor).
- #10e boxPlotGG accepts integer — ACCEPTED, no change (same disclosure controls as numeric:
  5–95% quantiles + n >= nfilter.subset; integer-valued doubles were already accepted).
- #11 kurtosisDS2 stop() instead of NA — ACCEPTED, no change (kurtosisDS1, skewnessDS1/2
  already stopped in 6.3.5; guide step 5).
- #12 uniqueDS NULL check dropped — VALID, TODO (option 2): reject NULL objects in
  `.loadServersideObject` for all functions ("The server-side object 'x' is NULL"), not just
  uniqueDS. Realistic cause measured on Armadillo: `ds.make("D$LAB_TSX", "nullobj")` (typo)
  silently creates NULL; ds.unique then propagates it. Needs full test run (touches every fn).
  Check nothing legitimately loads a NULL (e.g. optional args loaded by name).
- #13 levelsDS privacy gate after load/class check — VALID, TODO: move
  `checkPermissivePrivacyControlLevel()` back to first line (as 6.3.5).
- #14a names with spaces in rbindDS/cbindDS/dataFrameDS — ACCEPTED, no change (clients never
  add spaces).
- #14b seqDS FROM/TO/BY/LENGTH.OUT — VALID, TODO: replace `tryCatch(.loadServersideObject(..),
  error=as.numeric)` with plain `as.numeric()` (values are documented number strings; ds.seq
  validates them client-side so names never reach the server; BooleDS precedent).
  ALONG.WITH stays name-based.
- #14c BooleDS rejects literal "TRUE"/"FALSE"/"NA" for V2 — VALID, TODO: map "TRUE"/"FALSE" →
  logical and "NA" → NA before numeric/name handling (logical scalar is documented); tests.
- #15a matrixDetDS1 disclosure guard (7cb57fca) — ACCEPTED, no change (guard is on the aggregate
  fn that returns the determinant; DS2 assign keeps result server-side).
- #15b glmSummaryDS.as redaction by name (5bf1b1a0) — ACCEPTED, no change (real bug fix; old
  index-based code blanked coefficients when no NAs).
- #15c lmerSLMADS2/.assign offset/weights rewrite (1fff7008, 18bf2017) — ACCEPTED (bug fix),
  TODO tidy: shorten the 7-line inline comment to <=3 lines; revert whitespace-only lines.
- #16 glmChecks leaves options(warn=-1) — VALID, TODO: port 6.3.5 fix (70b467b2): save
  `getOption("warn")` + `on.exit(options(warn = old))` in glmChecks. Also check ds.table for the
  same 6.3.x-only on.exit fix.
- #17 client checkClass/classDS round trips in batch 4 — VALID, DESIGN TODO: new aggregate
  helper (e.g. `getClassAllObjectsDS(x.names)`, same style as `getClassAllColsDS`) returning
  class + colnames per element in one parallel call; switch ds.c, ds.list, ds.cbind, ds.rbind,
  ds.dataFrame (and ds.summary's pre-call class lookup) to it + `.checkClassConsistency()`.
  Uses `.loadServersideObject`, no privacy gate. Also serves the guide's "checkClass split"
  follow-up. getClassAllColsDS itself belongs with ds.standardiseDf (not on v7 client).
  ds.dataFrameFill OUT OF SCOPE: to be deprecated (also drops its items under #18, #26).
- #18 per-study loops — VALID for info/validation loops, TODO:
  ds.replaceNA: move the forNA-length vs numNA check into replaceNaDS (stop() server-side),
  delete client numNaDS loop; server test for wrong length. ds.summary → #22;
  ds.cbind/ds.dataFrame → #17; glmChecks → #21.
  ACCEPTED (DSI limitation, one assign call = same args for all studies): per-study assign
  loops with study-specific values in ds.replaceNA, ds.rNorm/rBinom/rPois/rUnif,
  ds.mean(save.mean.Nvalid=TRUE).
- #19a BooleDS, dataFrameSubsetDS1/DS2 per-element eval(parse) on names — VALID, TODO: use the
  already-loaded V1/V2 with `match.fun(Boolean.operator)` vectorised (keep length-equal /
  length-1 branches). Verify old vs new output on numeric, factor, NA inputs first.
- #19b glm family eval(parse) — VALID, TODO: offset/weights → `cbind(.loadServersideObject(x))`
  in glmDS1/2, glmSLMADS1/2, glmerSLMADS2/.assign, lmerSLMADS2/.assign. Formula terms
  (model.variables loop): first check what ds.glm allows in formulas — names only → switch to
  .loadServersideObject; expressions allowed → keep parse as formula handling, note in guide.
- #20 classConsistencyCheck — ONE RULE FOR ALL FUNCTIONS (assign and aggregate), SUPERSEDES the
  earlier #20a "close" and #20b "exempt batch 7" notes:
  - genuinely different permitted classes → param, default TRUE; numeric/integer only → param,
    default FALSE; single class → none; accepts any class → none.
  - aggregate fns: server returns `class`; assign fns: when TRUE, one parallel #17-helper call
    before the assign.
  - ADD: batch 1 abs/exp/log/sqrt (FALSE), asDataMatrix/asLogical (TRUE); batch 7 glm, glmSLMA,
    glmerSLMA, lmerSLMA, gamlss, mice (TRUE; replaces glm `checks`).
  - Batch 4 (option 2): give cDS, listDS, cbindDS, rbindDS, dataFrameDS explicit server
    `.checkClass` (start from 6.3.5 cbind DataSHIELD.checks list: data.frame, matrix, factor,
    character, numeric, integer, logical; decide c/list lists at implementation), so they keep
    classConsistencyCheck (TRUE) and DataSHIELD.checks is removed.
  - REMOVE param (any class): ds.numNA, ds.length, ds.dim (after #9/#10a).
  - Update guide with this rule; remove batch-1 TODO.
- #20c ds.meanSdGp — VALID, TODO: keep one classConsistencyCheck (TRUE) but check only
  `class.index`, not `class.x` (numeric/integer interchangeable).
- #21 glm-family `checks` / glmChecks — VALID, TODO: remove `checks` param from ds.glm,
  ds.glmSLMA, ds.glmerSLMA, ds.lmerSLMA and delete glmChecks. Move checks server-side
  (glmDS1, glmSLMADS1, glmerSLMADS2, lmerSLMADS2; always-on, no extra calls): existence via
  .loadServersideObject (#19b); offset/weights numeric via .checkClass; all-NA variable stop();
  negative weights stop(). Data class consistency via classConsistencyCheck (#20).
  checkNegValueDS then unused (→ #41 dead code).
- #22 ds.summary — VALID, TODO: (a) class lookup via #17 helper + .checkClassConsistency; one
  multi-study call per server fn per branch (verify INVALID studies still show 'INVALID object!'
  and no disclosure errors on small objects); (b) factor/logical branches: replace table1DDS
  (as.symbol) with refactored tableDS; (c) fix logical branch `1:length(2)` → `1:2` + logical
  smoke test.
- #23 client smoke tests — VALID, TODO (~50 fns, batches 1–7): for every refactored client fn,
  smk tests matching its server class behaviour: (1) missing object → "does not exist" via
  datashield.errors(); (2) wrong type → "must be of type" where .checkClass; (3) happy path per
  distinct permitted class (esp. logical mean/var #4, list glm #8, double index meanSdGp #10c);
  (4) where classConsistencyCheck exists: mismatched class in one study (e.g. ds.asCharacter on
  connections[1]) aborts with TRUE, passes with FALSE.
- #24 server unhappy-path tests — VALID, TODO: every server fn gets "does not exist" + (where
  .checkClass) "must be of type" + happy path per permitted class, mirroring #23. Restore
  batch-1 tests removed in f6f6b0d4; add for lengthDS, isNaDS, meanSdGpDS index, corDS/covDS y,
  uniqueDS, cDS, listDS, replaceNaDS, unListDS, gamlssDS, miceDS, asLogicalDS (guide TODO).
- #25 arg tests — VALID, TODO: ds.levels missing-object → covered by #23; ds.length restore
  NULL-x and bad-type arg tests without `checks=` (class test obsolete after #9); ds.seq
  "'Test'" assertion → update to "must be a real number" as part of #38; move
  ds.changeRefGroup wrong-type (server) test from arg to smk.
- #26 generic "DataSHIELD errors" in test-arg-ds.merge.R:26 — VALID, TODO: replace with two smk
  tests using datashield.errors(): x vector → "must be of type data.frame"; y missing →
  "does not exist". (dataFrameFill part dropped: deprecated.)
- #27 empty block test-disc-ds.levels.R — VALID, TODO: fill with ds.asFactorSimple("D$LAB_TSC")
  then ds.levels → expect "FAILED: Result length less than nfilter.levels.density" via
  datashield.errors(); if asFactorSimple refuses, delete the empty block.
- #28 perf tests — VALID, TODO: rewrite ~30 perf tests to copy their smoke test's connect line
  + call; boxPlotGG perf must call ds.boxPlotGG (not ds.boxPlot); add perf tests for ds.glm,
  ds.glmSLMA, ds.glmerSLMA, ds.lmerSLMA. Changed/new keys need CI re-measurement of reference
  rates (don't fill locally).
- #29 PERF_DURATION_SEC — VALID, TODO: in all 93 perf tests replace `.durationSec <- 30 #
  seconds` with `.durationSec <- perf.testduration()`; fix `perf.reference.save()` calling
  `load.pref()` → `.load.pref()` in perf_tests/perf_rate.R.
- #30 Arjuna headers on new refactor test files — VALID, TODO: remove 10-line header from
  client test-arg-ds.{abs,sqrt}.R, test-perf-ds.{completeCases,dim,isNA,levels,ls,names,numNA,
  unique}.R; server test-smk-{expDS,logDS,meanSdGpDS,mergeDS,repDS}.R (full sweep of files new
  since 6.3.5; batch-10 ones already done).
- #31 dormant MODULE 5 asserts in definition_tests (def-ds.dataFrameSort.R:38,
  def-ds.dataFrameSubset.R:35,68) — VALID, TODO: replace `results$studyside.messages` checks
  with expect_error("There are some DataSHIELD errors") + expect_match on each study's
  datashield.errors() specific server message; delete branches that are unreachable. Verify via
  dgr shard (needs dsDanger on server).
- #32 broken examples — VALID, TODO: ds.dim.R:67,71,74 remove doubled `#'` so calls close;
  ds.recodeValues.R:70 add comma after `newobj = 'bmi_recoded'`; redocument.
- #33 dataFrameSortDS author split — VALID, TODO: move Tim Cadman @author below line 34;
  redocument. Swept both repos: only occurrence.
- #34 stale docs — VALID, TODO: levelsDS @param x → name of a factor; asListDS @return → nothing
  returned to client (after #1); ds.mean.R:24 delete isDefined sentence; ds.glmSummary.R:98
  delete "LOOK BELOW CLIENTSIDE MODULE" comment; redocument.
- #35 gamlssDS/miceDS obj_name "data" — VALID, TODO: `data.name <- data` before loading, pass
  `obj_name = data.name` (gamlssDS classes also change per #8).
- #36 minimal-diff churn — PARTIAL, TODO: batch 10 (unmerged) revert whitespace-only lines;
  merged batches: leave whitespace/renames (reverting = more churn), restore only deleted
  comments that explained non-obvious code; matrixDimnamesDS delete the commented-out guard.
- #37 helpers — VALID, TODO: `.check_df_name_provided` now used (ds.colnames, #2) — resolved;
  add `call. = FALSE` to .loadServersideObject "does not exist" stop (with #12); move
  `.checkDisclosureSize` to dsBase/R/utils.R; one camelCase rename commit after batches merge:
  .set_datasources→.resolveDatasources, .set_newobj_name→.resolveNewobjName,
  .check_newobj_name→.checkNewobjName, .expand_to_studies→.expandToStudies,
  .get_datasources→.getDatasources, .verify_datasources→.verifyDatasources,
  .check_df_name_provided→.checkDfNameProvided (update guide's rename note).
- #38 *.transmit eval(parse) sweep — VALID, TODO (tidy PR): direct conversion
  (`as.numeric(unlist(strsplit(x, ",")))`) in matrixDS (3), matrixDiagDS (2), repDS (4),
  dmtC2SDS (3; `as.<class>()` builder → lookup of permitted conversion fns), client ds.seq (4);
  drop matching nfilter.stringShort guards; verify old vs new per function first; update
  ds.seq arg test (#25).
- #39 newobj validation — VALID, TODO: all 58 client fns with `newobj` use the default-then-
  validate helper (`.resolveNewobjName`, #37) instead of the bare is.null default. Validation is
  client-only (no server call): single character string AND `make.names(newobj) == newobj`
  (valid R symbol). Check test-expt_dgr-ds.dataFrameSubset.R:36,56 (newobj=20) then passes.
- #40 never in a batch — VALID, TODO "batch 11" (same guide rules): ds.auc/aucDS,
  ds.bp_standards/bp_standardsDS, ds.igb_standards/igb_standardsDS, ds.mdPattern/mdPatternDS,
  ds.exists, ds.rm/rmDS, ds.testObjExists/testObjExistsDS, ds.listDisclosureSettings.
  Leave deprecated-only servers (table1DDS, table2DDS, messageDS, subsetDS, subsetByClassDS);
  no-caller servers → #41. RULE: all client-side helpers camelCase only — snake_case ones today:
  .check_df_name_provided, .check_newobj_name, .expand_to_studies, .get_datasources,
  .pool_md_patterns (→ .poolMdPatterns, with batch 11), .set_datasources, .set_newobj_name,
  .verify_datasources (renames per #37). Add rule to guide.
- #41 dead server code — VALID, TODO in batch 11: remove ranksSecureDS1-3/5, blackBoxDS,
  blackBoxRanksDS, minMaxRandDS, extractQuantilesDS1/2, checkNegValueDS (after #21), client
  ds.extractQuantiles, plus their inst/DATASHIELD entries (exported+whitelisted = callable
  attack surface, several still eval(parse)). KEEP standardise-df server fns (ds.standardiseDf
  coming to v7; refactor then).
- #42 guide updates — TODO: ds.colnames now done (batch 10); Known Issues b4/6/7/8 → resolved
  (confirm on next full perf run); keep PERF_DURATION_SEC once #29 lands; Key Files path →
  dotfiles; remove ds.boxPlotGG from table (not exported); fix asDataMatrix permitted classes;
  remove batch-1 classConsistencyCheck TODO (superseded by #20 rule), keep asLogicalDS TODO
  until #24; add rules from #20, #40 (camelCase helpers), batch 11. AUTHORSHIP (decided): add
  the Tim Cadman @author tag to every file actually refactored, INCLUDING files with no previous
  @author line — make guide match the checklist.
- #20 (decision) Replace every `DataSHIELD.checks` / `checks` param with `classConsistencyCheck`
  (guide rule 8): ds.cbind, ds.rbind, ds.dataFrame (and ds.replaceNA's internal ds.dataFrame
  call → classConsistencyCheck=FALSE); glm family `checks` → #21.
  Non-class checks formerly under DataSHIELD.checks: equal row counts → server-side stop in
  cbindDS/dataFrameDS (cbind recycles silently); duplicate-colname warning → from #17 helper.

## 1. Critical / blocking
- **asListDS returns the converted object to the client** — `dsBase/R/asListDS.R` ends on
  `assign(newobj, result, ...)`, whose value is returned by the aggregate; `ds.asList` ends on
  `out.message <- datashield.aggregate(...)`. From commit `15394de6` (in v7.0-dev, no release).
  CONFIRMED 2026-09-21 on local Armadillo: `ds.asList("D$LAB_TSC")` returned all 2163
  individual values for sim1 to the client. Fix: end asListDS with `invisible(NULL)` (or return
  a non-disclosive message) and add a test asserting the return carries no data.
- **CI installs stale dsBase** — `armadillo_azure-pipelines.yml:240` installs tracked
  `dsBase_7.0.0-permissive.tar.gz` (batch-9 build). Opal Azure + GHA install `ref='v7.0-dev'`.
  Rebuild via `build-permissive.sh` and copy over the CI filename when batch 10 lands.
  `dsBase_7.0.0.tar.gz` (tracked) is stale and unreferenced.
- **ds.colnames client never refactored** — guide says "already done", but `1352363a` reverted it;
  `ds.colnames.R:56-73` still has `connections_find`, `isDefined`, `checkClass`.

## 2. Behaviour changes vs 6.3.5 ("do not change behaviour")
- `meanDS.R:26`, `varDS.R:27`: numeric/integer only → rejects logical (incl. all-NA cols) and
  matrix; server tests were edited to fit.
- `corDS.R:33,37`, `covDS.R:42,46`: factor x now rejected.
- `ds.cor` / `ds.cov`: y no longer ignored (with warning) when x is matrix/df; server cbinds it.
- `ds.changeRefGroup.R:133`: numeric `ref` now a position not a level name; server test passes
  by coincidence.
- glm/glmSLMA/glmerSLMA/lmerSLMA servers (`glmDS1:46` etc.): `c("data.frame","matrix")` rejects
  list (glm accepts), admits matrix (glm rejects). gamlssDS same (uncertain).
- `lengthDS.R:15`: wider than guide (df/array/matrix) and narrower than 6.3.5 default (Date etc.).
- Uncertain narrowing: `dimDS` (array/table), `densityGridDS`, `meanSdGpDS` (double index,
  logical X), `asLogicalDS` (is.numeric vs class names).
- Widening: `boxPlotGG_data_TreatmentDS.R:23` accepts integer (6.3.5 numeric only).
- `kurtosisDS2.R:31`: stop() instead of NA on small studies.
- `uniqueDS`: NULL no longer rejected.
- `levelsDS.R:15-18`: load/class check now runs before privacy-level gate.
- `lexisDS2.R:50`: documented-optional `entryCol=NULL` now errors (old path likely broken too).
- Batch-4 minor: names with spaces ("a, b") no longer resolve in rbindDS/cbindDS/dataFrameDS;
  seqDS returns NA not error on bad name; BooleDS rejects V2 "TRUE"/"NA".
- Batch-8 random generators accept per-study vectors (`.expand_to_studies`) — deliberate,
  documented, tested.
- Out-of-refactor commits to confirm: `matrixDetDS1` new disclosure guard (`7cb57fca`, DS2 not
  guarded); `glmSummaryDS.as` redaction by name (`5bf1b1a0`, real fix); lmerSLMA offset/weights
  rewrite (`18bf2017`, `1fff7008`) with 7-line comment + whitespace.
- `glmChecks.R:59`: leaves `options(warn=-1)` set globally (6.3.x fix `70b467b2` not on v7).

## 3. Guide steps not applied
- Client `checkClass(` remaining: `ds.summary:77`, `ds.colnames:73`, `ds.c:76`,
  `ds.cbind:131,142,160`, `ds.dataFrame:111,122,140`, `ds.list:76`, `ds.rbind:98`,
  `ds.dataFrameFill:93`. `isDefined(` in `ds.dataFrameFill:124`.
- Per-study `datasources[i]` loops (rule 9): `ds.summary`, `ds.rowColCalc:83-101` (classDS per
  column per study), `ds.replaceNA:110-119`, `ds.cbind:185-190`, `ds.dataFrame:165-170`,
  `ds.dataFrameFill:101,133`.
- `eval(parse` on object names: `BooleDS:105,112`, `dataFrameSubsetDS1:241,247`,
  `dataFrameSubsetDS2:270,277` (element-wise re-parse); glm family ~30 sites (model.variables,
  cbind of data/offset/weights) in glmDS1/2, glmSLMADS1/2, glmerSLMADS2/.assign,
  lmerSLMADS2/.assign.
- `classConsistencyCheck`: absent on batch 1 (TODO) and batch 7 (exemption undocumented);
  assign functions can't return class — needs design decision; batch-4 cbind/rbind/dataFrame
  param only active under `DataSHIELD.checks=TRUE`, undocumented; ds.rbind double-gated.
  `ds.meanSdGp` default TRUE though x is numeric/integer (uncertain).
- `checks` param still present on ds.glm/glmSLMA/glmerSLMA/lmerSLMA (gates glmChecks).
- `ds.summary`: per-study loops, `table1DDS` via `as.symbol`, client `checkClass`; pre-existing
  bug: logical branch `for(j in 1:length(2))` then names 2 elements → errors.

## 4. Tests
- Client smoke tests lacking nonexistent-object test: most of batches 1–7 (21/22 in 1–2, all
  batch 4 and 5, batch 3/6, batch 7 except glmPredict). ds.boxPlotGG too.
- Server tests lacking unhappy paths: all batch-1 (removed in `f6f6b0d4`), lengthDS/isNaDS
  (must be of type), uniqueDS, cDS, listDS, replaceNaDS, unListDS, gamlssDS, miceDS,
  meanSdGpDS (index type), corDS/covDS (y type); asLogicalDS TODO.
- isValidDS: 6.3.5 "special NA" / "special NULL" cases dropped.
- Arg checks deleted not relocated: `test-arg-ds.levels.R` (not defined), `test-arg-ds.length.R`.
  `test-arg-ds.seq.R:24` assertion loosened (`58f6ee39`).
- changeRefGroup wrong-type test in arg not smk.
- Generic "DataSHIELD errors" only: `test-arg-ds.dataFrameFill.R`, `test-arg-ds.merge.R`
  (ambiguous: two possible errors).
- Empty block: `test-disc-ds.levels.R` `test_that("simple levels", {})`.
- Perf not replicating smoke: many in batches 1–2, 3/6 (reShape, changeRefGroup, asFactor*,
  dmtC2S), 4 (rbind, rep, recodeValues, list, merge, dataFrameSort, dataFrameSubset),
  5 (matrixDiag, matrixDimnames), 7 (glmPredict, gamlss, mice); boxPlotGG perf times ds.boxPlot.
- No perf test: ds.glm, ds.glmSLMA, ds.glmerSLMA, ds.lmerSLMA.
- Perf profile rows missing: opal CSV lacks lexis, rowColCalc, table, tapply, tapply.assign;
  both lack isValid.
- `PERF_DURATION_SEC` not read by any perf test (94 hardcode 30s); guide instruction ineffective.
- Arjuna copyright on new files: client `test-perf-ds.{dim,names,isNA,numNA,ls,completeCases,
  levels,unique}.R`, `test-arg-ds.{abs,sqrt}.R`; server `test-smk-{expDS,logDS}.R`,
  `test-smk-{elspline,lspline,ns,qlspline}DS.R`, `test-smk-tableDS{,.assign,2}.R`,
  `test-smk-lexisDS{1,2}.R`.
- Dormant MODULE 5 asserts in `definition_tests/def-ds.dataFrameSort.R:38`,
  `def-ds.dataFrameSubset.R:35,68`.

## 5. Docs / hygiene
- Broken examples: `ds.dim.R:67,71,74` (unclosed calls), `ds.recodeValues.R:71` (missing comma).
- `dataFrameSortDS.R:32-34`: Tim author line inserted mid multi-line author entry.
- Stale: `levelsDS.R:5` @param, `asListDS.R:18-21` @return, `ds.mean.R:24` isDefined sentence,
  `ds.glmSummary.R:98` MODULE comment.
- `.checkClass` obj_name literal "data" in `gamlssDS.R:87`, `miceDS.R:62`.
- Whitespace/comment churn: ds.isNA (40 lines), ds.dim, ds.length, ds.numNA, isNaDS, numNaDS,
  levelsDS, completeCasesDS, quantileMeanDS, meanSdGpDS, changeRefGroupDS, cDS, listDS,
  recodeValuesDS, ds.cbind, ds.Boole, gamlssDS, miceDS, densityGridDS, heatmapPlotDS,
  boxPlotGGDS, histogramDS1 (reindent); deleted comments in batch-1 clients.
- Renames: dimDS/lengthDS `x.var`→`x.val`, ds.boxPlotGG `pt`→`plot_data`, completeCases
  `x1.transmit`, matrixDimnamesDS commented-out guard.
- `.check_df_name_provided` unused; `cli_abort(call.=FALSE)` is wrong arg (should be none /
  `call=`). `.loadServersideObject` "does not exist" stop lacks `call.=FALSE`.
- Helper naming mixes snake_case and camelCase; `.checkDisclosureSize` lives in isValidDS.R.

## 6. Guide follow-ups / guide out of date
- Open: rangeDS (+ `as.symbol` in heatmapPlot/contourPlot/densityGrid; error paths untested);
  `*.transmit` eval(parse) (matrixDS, matrixDiagDS, dmtC2SDS, repDS, tableDS/tableDS.assign
  `exclude`, client ds.seq); client checkClass rename; newobj validation (65/66 unvalidated;
  `test-expt_dgr-ds.dataFrameSubset.R:36,56` expects newobj=20 to error); `.set_*` renames;
  asLogicalDS wrong-type test; batch-1 classConsistencyCheck TODO.
- Never in a batch (old patterns): client ds.auc, ds.bp_standards, ds.igb_standards (isDefined),
  ds.exists, ds.listDisclosureSettings, ds.mdPattern, ds.rm, ds.testObjExists; server aucDS,
  bp/igb_standardsDS, mdPatternDS, messageDS, minMaxRandDS, blackBox*, extractQuantilesDS1/2,
  ranksSecureDS5, standardise-df fns, table1DDS/table2DDS, checkNegValueDS, testObjExistsDS, rmDS.
- Dead code: ranksSecureDS1-3/5, blackBoxDS, blackBoxRanksDS, minMaxRandDS, standardise-df server
  fns, client ds.extractQuantiles.
- Guide stale: "ds.colnames already done"; Known Issues batches 4/6/7/8 look resolved (not run);
  PERF_DURATION_SEC; "Key Files → Guides" path; authorship rule conflicts with checklist (files
  with no @author); asDataMatrix permitted classes in table; `ds.boxPlotGG` listed but not exported.
