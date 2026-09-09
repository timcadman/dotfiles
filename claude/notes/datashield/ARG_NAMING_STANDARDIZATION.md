# Argument Naming & Description Standardization Plan

> Source of truth alongside `REFACTOR_GUIDE.md` in this same folder. Do not commit copies
> of this file into dsBase or dsBaseClient — same rule as the refactor guide.

## Context

A parameter-naming/description consistency audit across dsBase and dsBaseClient found the
same underlying concept spelled multiple different ways across functions (e.g. "name of a
server-side data.frame" is `df.name`, `dataName`, `data`, or `data.name` depending on the
function), plus stale `@param` descriptions left over from the perf-batch refactor (a
parameter that used to hold a real data.frame object now holds just its string name, but
the doc text wasn't updated).

**Decision: standardize both names and descriptions, not descriptions only.** Renaming is
in scope. Precedent: `REFACTOR_GUIDE.md` already treats this as a major release where API
changes are acceptable (e.g. dropping `ValidityMessage` from client returns).

**Risk asymmetry to weigh per-cluster, not a blocker:**
- dsBase server-side param names (`*DS`/`*DS1`/`*DS2`/`.assign` functions) are effectively
  private — the client dispatches via `call('funcDS', ...)` positionally, so renaming them
  is zero-risk to end users.
- dsBaseClient `ds.*` param names ARE the public API — researchers call them by name in
  analysis scripts. Renaming these has a real (if precedented-as-acceptable) cost.

## Mechanics: `@template`

dsBaseClient already has a working `man-roxygen/` precedent (`classConsistencyCheckTrue.R`
/ `classConsistencyCheckFalse.R`) — literal-text templates, no `@templateVar`
parameterization, two variants because the default value differs. Follow this style:

1. One template file per canonical concept in `man-roxygen/` (dsBase needs this directory
   created + a `^man-roxygen$` line added to its `.Rbuildignore` — dsBaseClient already has
   both).
2. Each function's roxygen block replaces its inline `#' @param <name> ...` with
   `#' @template <template-name>`.
3. `@template` only rewrites documentation text. Actual parameter renames are separate code
   edits (`R/*.R` signature + call sites + `devtools::document()`), not something the
   template mechanism does by itself.

## Sequencing

1. **Zero-effort win, do immediately:** 5 dsBaseClient functions (`ds.cbind`,
   `ds.dataFrameFill`, `ds.rbind`, `ds.c`, `ds.list`) hand-write `classConsistencyCheck`
   description text that is *already identical* to the existing
   `classConsistencyCheckTrue.R`/`False.R` templates. Just point them at
   `@template classConsistencyCheckTrue`/`False` — no new template needed, no rename, no
   text to write.
2. Fix the two outright-stale (not just inconsistent) descriptions — correctness bugs, not
   style: `gamlssDS`/`ds.gamlss` and `miceDS`/`ds.mice` both say "a data frame
   containing..." when the parameter is actually a string *name* post-refactor
   (`.loadServersideObject()`). `glmDS1`'s existing correct wording ("a character string
   specifying a data.frame object holding...") becomes the reference phrasing.
3. Roll out Category A below (name already consistent, description-only fix) — mechanical,
   low-risk, do in bulk. `datasources` alone (107 occurrences, ~95%+ already near-identical)
   is the single biggest win in the codebase.
4. Decide + apply canonical names for Category B (name inconsistent), rename in both repos,
   then apply the now-unified template.
5. Resolve Category C (same name, different concept) — these need a rename on at least one
   side to stop the collision; not a template fix.
6. Re-run `devtools::document()` in both repos, diff the generated `.Rd` files for
   unintended changes before committing.

## Catalog of inconsistencies

Exhaustive pass complete: every `@param` extracted from all R files in both repos (351
distinct param names; 186 appear 2+ times; 130 of those have 2+ distinct wordings). Raw
extraction was session-scratch (not persisted) — this file is the durable record.

### A. Same concept, name already consistent — description-only fix

| Param | Occurrences | Wording spread | Notes |
|---|---|---|---|
| `datasources` | 107 | 87 near-identical + 6 short-form (`ds.boxPlot` family, missing the "default connections" explanation) + ~14 minor variants (spacing/punctuation) + 3 divergent (`ds.dmtC2S`, `ds.glmPredict`, `ds.glmSummary` use a different "opals.a, opals.w2" example paragraph) | Biggest single win — one template covers the large majority as-is |
| `classConsistencyCheck` | 5 not-yet-templated (+13 already using the template) | 3 near-identical, 2 minor variants ("before concatenation"/"before coercion" suffix) | See zero-effort win above |
| `checks` (client) | 5 | `ds.glm`/`ds.glmSLMA`/`ds.glmerSLMA`/`ds.lmerSLMA`: `"logical. If TRUE ds.X checks the structural integrity of the model. Default FALSE."` (function name substituted each time) — `ds.look` alone says something generic | 4-of-5 template-ready |
| `notify.of.progress` | 8 | `"specifies if console output should be produced to indicate progress. Default FALSE."` (6x) vs `"logical. If TRUE console output..."` (`ds.recodeValues`) vs a typo variant (`ds.sample`) | Trivial harmonization |
| `M1` (client, matrix family) | 5 | 3x `"a character string specifying the name of the matrix."`, 2 minor variants | — |
| `V1.name`/`V2.name` (dsBase) | 4 each | `BooleDS` and `dataFrameSubsetDS1/2` describe the identical Boolean-comparison concept in near-identical wording | — |

Not fully catalogued to the individual-wording level (time-boxed; reviewed by sample, lower
priority because variance looked mostly genuine, not accidental drift): `x` (86
occurrences, 57 distinct — legitimately function-specific: "a numeric vector" vs "a factor"
vs "an object name" depending on what the function actually accepts), `newobj` (59
occurrences, all distinct by design — each describes what that specific call creates; not a
literal-text template candidate), `type`, `method`, `y`, `formula` (14–23 occurrences each).

### B. Same concept, different name (description also drifts — template can standardize text per name-variant now; the rename itself is the bigger decision)

| Concept | Names in use | dsBase functions | dsBaseClient functions | Proposed canonical |
|---|---|---|---|---|
| Name of a server-side data.frame/matrix | `df.name`, `dataName`, `data`, `data.name` | `dataFrameFillDS`, `dataFrameSortDS`, `dataFrameSubsetDS1/2`, `standardiseDfDS` (`df.name`); `glmDS2`, `glmSLMADS.assign/2`, `glmerSLMADS.assign/2`, `lmerSLMADS.assign/2` (`dataName`); `glmDS1`, `glmSLMADS1`, `gamlssDS`, `miceDS`, `hetcorDS`, `subsetByClassDS` (`data`); `reShapeDS` (`data.name`, also has a roxygen typo: stray comma after the param name) | `ds.dataFrameFill`, `ds.dataFrameSort`, `ds.dataFrameSubset` (`df.name`); `ds.glmSLMA`, `ds.glmerSLMA`, `ds.lmerSLMA` (`dataName`); `ds.glm`, `ds.gamlss`, `ds.hetcor`, `ds.mice`, `ds.lexis` (`data`); `ds.reShape` (`data.name`) | TBD — pick one, likely `df.name` (most descriptive) or `data` (most common) |
| — within this cluster, wording *also* drifts independently of the name split | — | `dataFrameSortDS`/`dataFrameSubsetDS1/2` use self-referential doc text (e.g. `"<df.name> argument generated and passed directly to dataFrameSubsetDS1 by ds.dataFrameSubset"` — accurate, but a different style from the plain versions used elsewhere); `glmDS1` and `glmSLMADS1` both use `data` but word it differently from each other, even though their client callers (`ds.glm`/`ds.glmSLMA`) are already near-identical to each other | — | i.e. the client is already more consistent than the server here — server needs the catch-up |
| Name of the object to operate on (generic) | `x` vs `x.name` | batch-2+ functions use bare `x`; batch-1 functions use `x.name` (`asCharacterDS`, `asIntegerDS`, `asDataMatrixDS`, `asListDS`, `asMatrixDS`) | mirrors server split (`ds.asCharacter`, `ds.asInteger`, etc. use `x.name`; `ds.class`, `ds.length` use `x`) | `x` (majority convention, matches `.loadServersideObject(x)` idiom used throughout) |
| Name of the new object to create | `newobj` vs `newobj.name` | — | `newobj` (63 functions) vs `newobj.name` (`ds.asFactor`, `ds.asFactorSimple` — 2 outliers) | `newobj` |
| Run optional client-side validation | `checks` vs `DataSHIELD.checks` | — | `checks` (`ds.glm`, `ds.glmSLMA`, `ds.glmerSLMA`, `ds.lmerSLMA`, `ds.look`) vs `DataSHIELD.checks` (`ds.cbind`, `ds.dataFrame`, `ds.rbind`) | TBD |
| Matrix name(s) — whole matrix family (`matrixDetDS1/2`, `matrixDimnamesDS`, `matrixMultDS`, `matrixInvertDS`, `matrixTransposeDS`) | dsBase `M1.name`/`M2.name` vs dsBaseClient `M1`/`M2` | — | — | Cross-repo mismatch, not just within-repo |
| Name of the message-holding list (`messageDS` / `ds.message`) | dsBase `message.object.name` vs dsBaseClient `message.obj.name` | — | — | Cross-repo mismatch |
| `na.action` | dsBase/client `na.action` everywhere else | — | `ds.cov` alone uses `naAction` (camelCase outlier) | `na.action` |

### C. Same literal name, genuinely different concept (needs a rename to resolve the collision — not a template fix)

| Name | Meaning 1 | Meaning 2 |
|---|---|---|
| `df` | An actual resolved data.frame **object** (`dataFrameFillDS`, `subsetByClassHelper2/3` — internal helpers) | **Degrees of freedom** (a number) in `ds.ns`: *"df degrees of freedom. One can supply df rather than knots..."* |
| `x.name` | "Name of a glm object" (`ds.glmSummary`) | "Name of the first data frame to be merged" (`ds.merge`) | "Name of the variable to perform unique upon" (`ds.unique`) — three-plus genuinely different things share this one literal param name across the type-coercion-family-style functions where `x.name` is otherwise used consistently as "name of the object to coerce" |

Not flagged as inconsistency (genuinely richer, not drifted): `verbose` mostly defers to
`"see help for ds.X"`, except `ds.glmerSLMA`/`ds.lmerSLMA` (client) which spell out real
PIRLS-iteration-verbosity semantics — correct to differ, not a bug.

### D. Stale descriptions (correctness bugs, not just inconsistency)

| File | Current text | Problem |
|---|---|---|
| `dsBase/R/gamlssDS.R` | `@param data a data frame containing the variables occurring in the formula.` | Parameter is actually a string name (`.loadServersideObject(data)`), not a real data.frame |
| `dsBaseClient/R/ds.gamlss.R` | same text | same problem, client-side mirror |
| `dsBase/R/miceDS.R` | `@param data a data frame or a matrix containing the incomplete data.` | same problem |
| `dsBaseClient/R/ds.mice.R` | same text | same problem, client-side mirror |

## Open decisions before implementation

- Canonical name per cluster in section B — proposed, not decided. Confirm before renaming.
- Category C collisions (`df`, `x.name`) need at least one side renamed to stop the
  collision — pick which side per case.
- Whether `newobj`/`checks`-style clusters get touched in the same pass as the harder
  renames, or shipped first as a quick win (recommend: ship first, per Sequencing above).
- Whether dsBase and dsBaseClient renames land in the same commit/PR per function pair, or
  dsBase's (zero-risk) renames go out ahead of the client's (public-API) renames.
