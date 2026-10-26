---
name: datashield
description: Run federated analyses with DataSHIELD from R — logging in to Opal or Armadillo servers with DSI, exploring and manipulating server-side data, descriptive statistics, tables, plots and GLMs with dsBaseClient, dplyr-style data manipulation with dsTidyverseClient, and convenience wrappers from dsHelper. Use whenever the user mentions DataSHIELD, ds.* or dh.* functions, datashield.login, Opal, Armadillo, or wants to analyse data held on remote DataSHIELD servers.
---

# DataSHIELD

Individual-level data never leaves the servers. The client sends commands; each server runs them
and returns only results that pass its disclosure checks. You never see rows of data, and must
never try to.

## Credentials (hard rules)

- **Never use usernames and passwords.** Do not ask for them, write them into code, or run code
  containing them. If the only login available is a username and password, stop and ask the user
  to log in themselves, outside the agent.
- **Use token-based login only:**
  - Armadillo: `token <- MolgenisArmadillo::armadillo.get_token(url)` opens a browser; the user
    signs in there, so you never see their password.
  - Opal: a personal access token the user creates in Opal, read from an environment variable the
    user has set themselves (e.g. `Sys.getenv("OPAL_TOKEN")`).
- **Tokens are secrets too.** Never print them, write them to files, or include them in output.
  Never inspect login data or connection objects.
- **Prefer an existing session.** Check `DSI::datashield.connections_find()` before logging in;
  if the user already has `conns`, use it.

```r
builder <- DSI::newDSLoginBuilder()
builder$append(server = "study1", url = armadillo_url, token = token,
               driver = "ArmadilloDriver", profile = "default")
builder$append(server = "study2", url = opal_url, token = Sys.getenv("OPAL_TOKEN"),
               driver = "OpalDriver", profile = "default")
conns <- DSI::datashield.login(logins = builder$build(), assign = FALSE)
```

## How DataSHIELD works

- **Assign vs aggregate.** Assign functions create or change an object on each server and return
  nothing; aggregate functions return disclosure-checked results. Functions with a `newobj`
  argument create a server-side object of that name.
- **Objects are referred to by name, as strings:** `ds.mean("D$age")`, not `ds.mean(D$age)`.
  Use `datasources = conns` (dsBaseClient) or `conns = conns` (dsHelper) to target servers.
- **Results are per server by default.** `type = "split"` gives one result per server;
  `type = "combine"` pools them. Say which one you report.
- **Pooled vs meta-analysed models.** `ds.glm` fits one model as if the data were pooled;
  `ds.glmSLMA` fits a model per server and meta-analyses the estimates.

## Which package

| Package | Use for |
|---|---|
| DSI | Login, logout, tables, sessions, server-side errors (`datashield.*`) |
| dsBaseClient | Core statistics, tables, plots, models, base-R-style manipulation (`ds.*`) |
| dsTidyverseClient | Preferred for data manipulation: `ds.mutate`, `ds.filter`, `ds.select`, … (needs the dsTidyverse server package) |
| dsHelper | Higher-level wrappers that return tidy tibbles: `dh.getStats`, `dh.meanByGroup`, … |

Before using a function, check the server supports it: `DSI::datashield.methods(conns, type = "aggregate")`
(or `"assign"`), and `DSI::datashield.pkg_status(conns)` for installed versions.

## Workflow

1. **Explore**
   - dsBaseClient: `ds.ls()`, `ds.colnames("D")`, `ds.class("D$x")`, `ds.dim("D")`, `ds.numNA("D$x")`
   - dsHelper: `dh.classDiscrepancy()` (classes that differ across servers), `dh.anyData()`
     (variables entirely missing on a server)
2. **Describe**
   - dsBaseClient: `ds.summary()`, `ds.mean()`, `ds.quantileMean()`, `ds.table()`
   - dsHelper: `dh.getStats()` (tidy summary of many variables), `dh.meanByGroup()`,
     `dh.createTableOne()` (manuscript tables), `dh.getRmStats()` (repeated measures)
3. **Prepare** (check each new object with `ds.class`/`ds.dim` before using it)
   - **Use dsTidyverseClient first** when the dsTidyverse server package is installed
     (`DSI::datashield.pkg_status(conns)`); fall back to the equivalents below only if it isn't:

     | Task | dsTidyverseClient | Fallback |
     |---|---|---|
     | New or changed column | `ds.mutate()` | `ds.assign()` |
     | Keep rows | `ds.filter()` | `ds.dataFrameSubset()` |
     | Keep or drop columns | `ds.select()` | `ds.dataFrameSubset()`, `dh.dropCols()` |
     | Rename columns | `ds.rename()` | `dh.renameVars()` |
     | Recode values | `ds.case_when()`, `ds.if_else()` | `ds.recodeValues()` |
     | Sort rows | `ds.arrange()` | `ds.dataFrameSort()` |
     | Combine data frames | `ds.bind_rows()`, `ds.bind_cols()` | `ds.rbind()`, `ds.cbind()` |

   - Convert to factor: `ds.asFactor()` (no dsTidyverseClient equivalent).
   - dsHelper, no equivalent in either: `dh.quartileSplit()`, `dh.makeIQR()`, `dh.zByGroup()`,
     `dh.tidyEnv()` (remove server-side objects)
4. **Model and plot**
   - dsBaseClient: `ds.glm()`, `ds.glmSLMA()`, `ds.histogram()`, `ds.scatterPlot()`
   - dsHelper: `dh.multGLM()` (many GLMs, handles non-convergence), `dh.lmTab()` (coefficient
     tables), `dh.metaManual()` (two-stage meta-analysis), `dh.getAnonPlotData()` (anonymised data
     for custom plots)
5. **Finish:** `DSI::datashield.logout(conns)` when the user is done.

## Errors and disclosure

- A server-side error usually shows only a generic client message; call `DSI::datashield.errors()`
  for the real one.
- Disclosure failures ("FAILED: Nvalid less than nfilter.tab", "invalid table", subset too small)
  are protections, not bugs. Explain them to the user and suggest a coarser analysis (fewer groups,
  larger categories). Never try to get around them, e.g. with overlapping subsets, repeated
  queries or differencing. `ds.listDisclosureSettings()` shows each server's thresholds.

## Client-side results and plots

- **Tibbles, not data frames:** build client-side results with `tibble()` / `as_tibble()`, not
  `data.frame()`.
- **ggplot2 for plots,** except forest plots.
- **Forest plots use `metafor::forest` on a fitted `rma` model,** written once as a function and
  reused. Passing the model draws the pooled diamond, sizes the study squares by weight, and
  heads the count column (`ilab.lab`), so nothing is placed by hand:

```r
# coefs: one row per cohort (no "combined" row), with label, est, se and n_obs;
# est on the model scale (log odds for logistic models).
draw_forest <- function(coefs, title, ratio = TRUE, label_header = "Cohort", method = "REML") {
  ticks <- pretty(c(0, coefs$est - 2 * coefs$se, coefs$est + 2 * coefs$se))
  fit <- metafor::rma(yi = est, sei = se, data = coefs, slab = label, method = method)
  metafor::forest(
    fit, atransf = if (ratio) exp else NULL, refline = 0, xlab = title,
    at = ticks, alim = range(ticks),
    xlim = range(ticks) + c(-1.6, 1.1) * diff(range(ticks)),
    header = c(label_header, if (ratio) "OR [95% CI]" else "Estimate [95% CI]"),
    ilab = n_obs, ilab.lab = "N", digits = c(3, 2), cex = 0.8,
    mlab = paste0(method, " random-effects model (I² = ", round(fit$I2), "%)"))
}

png(here::here("figures", "forest.png"), width = 16, height = 7, units = "cm", res = 300)
par(mar = c(5, 4, 0, 2))
draw_forest(coefs, "Odds ratio of survival, male vs female")
dev.off()
```

  - Take `est` and `se` per cohort from `dh.lmTab(..., exponentiate = FALSE)` (drop the
    "combined" row) or from `ds.glmSLMA`'s `betamatrix.valid` / `sematrix.valid`.
  - Ratios are plotted on a log scale (`atransf = exp`, `refline = 0` on the model scale). Use
    `ratio = FALSE` for linear models.
  - The axis ticks span 0 and every interval, and `xlim` is derived from them, so the reference
    line is always drawn and nothing overlaps the estimate column.
  - `method = "ML"` matches `ds.glmSLMA`'s own pooled row; `"REML"` is metafor's default.
  - A one-stage pooled (IPD) estimate isn't a meta-analysis. To show it alongside, add it with
    `metafor::addpoly()`.
  - Open the saved PNG and check the layout before handing it over.

## References

Read only what the task needs:

- `references/functions-DSI.md`, `functions-dsBaseClient.md`, `functions-dsTidyverseClient.md`,
  `functions-dsHelper.md`: generated from each package's documentation. Each starts with an index
  table; search it for the function, then read that entry. Never use a function or argument that
  isn't there. The versions are in each file's title; if `packageVersion()` differs, trust the
  installed help (`?ds.mean`).
- `references/patterns.md`: DataSHIELD-specific patterns and pitfalls. **Read it before:**
  combining cohorts, recoding, per-cohort derivations or z-scores, repeated measures, running
  many models, meta-analysis, multiple imputation, or custom plots.
- `references/recipes/index.md`: worked examples from the DataSHIELD wiki (data manipulation,
  summaries, figures, GLMs, a full worked example). Read the matching recipe before a multi-step
  analysis.
- `~/dotfiles/claude/notes/datashield/recipe-drafts/README.md`: index of unpublished recipe drafts
  (model specification, mixed models, sensitivity analyses, preparation, imputation, output). Read
  the matching draft when no published recipe covers the task.
