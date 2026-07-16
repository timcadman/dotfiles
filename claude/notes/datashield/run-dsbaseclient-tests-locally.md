# Running dsBaseClient tests locally against Opal / Armadillo

Reusable workflow for reproducing CI test failures locally. Companion to
`launch-datashield-servers-sandbox.md` (how to start the servers via the armadillo
repo's `scripts/benchmark/` launcher).

## TL;DR order of operations
1. Start the backend (Armadillo or Opal).
2. **Install the dsBase version the branch needs** on that backend's R server.
3. Make sure test data is uploaded (usually already there).
4. Point the test harness at the backend (`local_settings.csv` + port).
5. **Run only the FAILING test files first** (fast); run the full suite last (slow).

## Helper scripts (in this folder)
Two parameterised scripts wrap steps 2 + 4–5 so you don't hand-write scratch R each
time. First arg is always `opal|armadillo`.

```bash
# Install the matching dsBase on a backend (tarball, or github ref for Opal):
Rscript ~/.claude/notes/datashield/ds-install.R armadillo ~/git-repos/ds-core/dsBaseClient/dsBase_6.3.6.9000.tar.gz
Rscript ~/.claude/notes/datashield/ds-install.R opal      refactor/perf-batch-3

# Run a test file (writes local_settings.csv in the right form, sets the driver, runs):
Rscript ~/.claude/notes/datashield/ds-run-tests.R armadillo smk-ds.standardiseDf
Rscript ~/.claude/notes/datashield/ds-run-tests.R opal      smk-ds.var
```
`ds-run-tests.R` auto-detects whether the branch wants a full-URL or bare-host
`local_settings.csv` and writes accordingly. It does NOT install dsBase or edit
`login_details.R`. Env overrides: `PKG`, `OPAL_URL`, `ARMA_URL`, `*_USER`/`*_PASS`.
The sections below are the manual equivalents / background for when the scripts don't fit.

## 0. Critical: match the dsBase server build to the client BRANCH (not just major version)
The server runs dsBase; the client (dsBaseClient) calls it. A refactor branch on the
client usually has a **matching dsBase branch** with new server-side signatures. If the
server runs a different dsBase, function signatures mismatch and ~everything errors.

- A dsBaseClient `refactor/perf-batch-N` pairs with **dsBase `refactor/perf-batch-N`**
  (e.g. dsBase PR #471 for batch-3 — new `varDS(x=string)`, `.loadServersideObject`,
  `.checkClass`, returns `class`). It does **NOT** pair with dsBase `v7.0-dev`, which
  may not have merged that batch yet.
- `v6.3.6-dev*` client → dsBase `6.3.6.x`. "Matching" means the FEATURE, not just the
  major version: e.g. the standardise client (`v6.3.6-dev-feat/standardise-df`) needs
  `getClassAllColsDS` / `standardiseDfDS` / `getAllLevelsDS`, which live in dsBase
  `v6.3.6-dev` (`dsBase_6.3.6.9000.tar.gz`) — NOT in `v7.0-dev` or the perf-batch
  permissive build. Verify before installing: `tar tzf <tar> | grep <fn>` or
  `git -C dsBase grep -l <fn> <ref>`.

Check the worktree branch first: `git -C <repo> branch --show-current`. Beware a stale
local dsBase checkout — `git fetch` before reading its source, or read the PR/branch.

Mismatch symptoms (all the same root cause — wrong dsBase on the server):
- `varDS(D$LAB_TSC): The input must be a single character string` (v7.0 server, v6.3.6 client).
- `ds.var` errors + `Error in sum(xvect): invalid 'type' (character)` and the negative
  test expecting `"must be of type numeric or integer"` fails — server has the OLD `varDS`
  (no `.checkClass`), i.e. dsBase `v7.0-dev` instead of `refactor/perf-batch-3`.

Prebuilt tarballs in the dsBaseClient repo root: `dsBase_7.0.0-permissive.tar.gz` (this
is the **perf-batch-3 build with the new `varDS`** — verified by `.checkClass` in its
`R/varDS.R`), `dsBase_7.0.0.tar.gz`, `dsBase_6.3.6.9000.tar.gz`. "permissive" = disclosure
checks relaxed for tests. **To install the matching version, use this tarball (Armadillo)
or `ref='refactor/perf-batch-3'` (Opal github install) — NOT `v7.0-dev`.**

### CI implication
The pipelines install `dsadmin.install_github_package(opal,'dsBase',ref='v7.0-dev')` /
the v7.0 tarball. While the client is on a batch branch whose dsBase counterpart isn't in
`v7.0-dev` yet, CI runs the wrong server code → mass failures. Fix: point the install at
`refactor/perf-batch-3` (or merge that dsBase PR into `v7.0-dev`).

## 1. Start a server (just one is fine)
Launcher lives in the armadillo repo's benchmark dir. `$ARMA` = your checkout
(`~/git-repos/ds-molgenis/molgenis-service-armadillo` or `.../molgenis/...`).
```bash
# Armadillo only (released jar), on 8080 -- matches login_details.R (see §4):
ARMADILLO_VERSION=5.12.2 ARMA_LOCAL_PORT=8080 ARMA_USER=admin ARMA_PASS=admin \
  bash "$ARMA/scripts/benchmark/run_local_armadillo.sh"
# Opal only:  docker compose -f "$ARMA/scripts/benchmark/opal/docker-compose.yml" up -d
# Both:       bash "$ARMA/scripts/benchmark/start_servers.sh"   (reads that dir's .env)
```
The jar uses basic auth so it runs sandboxed (no gradlew OIDC-boot dance — see launch
note). Health: `curl -s localhost:8080/actuator/health` → `{"status":"UP"}`.

## 2. Install dsBase on the server

### Armadillo (REST via MolgenisArmadillo) — use `armadillo.install_packages()`
```r
library(MolgenisArmadillo)
armadillo.login_basic("http://localhost:8081", "admin", "admin")
armadillo.install_packages(
  paths   = "~/git-repos/ds-core/dsBaseClient/dsBase_7.0.0-permissive.tar.gz",
  profile = "default")
```
Then whitelist it (no R wrapper; hit the endpoint as CI does):
```bash
curl -s -u admin:admin -X POST http://localhost:8081/whitelist/dsBase   # -> HTTP 204
curl -s -u admin:admin http://localhost:8081/whitelist                  # -> [...,"dsBase",...]
```
(If the package doesn't take effect, restart the rock/profile container.)

### Opal (opalr) — install from GitHub ref or a local tarball
```r
library(opalr)
opal <- opal.login("administrator", "datashield_test&", url = "http://localhost:8080/")
# Use the ref that MATCHES the client branch (see §0) — e.g. for perf-batch-3:
dsadmin.install_github_package(opal, "dsBase", username = "datashield", ref = "refactor/perf-batch-3")
dsadmin.profile_init(opal, name = "default", packages = c("dsBase","dsTidyverse","resourcer"))
dsadmin.set_option(opal, "default.datashield.privacyControlLevel", "permissive")
opal.logout(opal)
```
For a local tarball instead of a github ref, swap the install line for
`dsadmin.install_local_package(opal, "<tar>")` (keep the `profile_init` / `set_option`).

## 3. Test data
A long-lived local Armadillo usually already holds CNSIM/DASIM/standardise/etc, but a
**fresh server (released jar via `run_local_armadillo.sh`) starts EMPTY** — you MUST run
the upload script or every test fails at login with `table datashield/cnsim/CNSIM1 is
not accessible` (all studies excluded → the `D` object is never created → 0 PASS).
Check first with `MolgenisArmadillo::armadillo.list_tables("datashield")`.

Upload (Armadillo — script already targets `http://127.0.0.1:8080`, admin/admin):
```bash
# The script uses RELATIVE .rda paths, so it must run from the data_files dir. The
# no-cd/no-chaining hook blocks `Rscript -e 'setwd(...); source(...)'`, so use a
# tiny wrapper file instead (setwd + source on separate lines) and run that:
printf 'setwd("%s")\nsource("molgenis_armadillo-upload_testing_datasets.R")\n' \
  ~/git-repos/ds-core/dsBaseClient/tests/testthat/data_files > /tmp/upload_data.R
Rscript /tmp/upload_data.R
```
Opal equivalent: `obiba_opal-upload_testing_datasets.R`. Takes a minute or two; it
prints the final `armadillo.list_tables("datashield")` (~39 tables) on success.

## 4. Point the harness at the local server
Two knobs in `tests/testthat/connection_to_datasets/`:
- **`local_settings.csv`** (gitignored) — its form differs BY BRANCH, check before setting:
  `init.ip.address()` (e.g. `refactor/perf-batch-3`) reads it as a BARE HOST that
  `login_details.R` wraps with `paste0("http://", <this>, ":8080")` — a full URL mangles to
  `http://http://...:8080` → "Resource assignment failed". `init.server.url()` (e.g.
  `v6.3.6-dev-feat/standardise-df`) reads it as the FULL URL (`http://localhost:8081/`
  Armadillo, `http://localhost:8080/` Opal).
- **Port**: `login_details.R` hardcodes Armadillo on `:8080`.
  - Cleanest: run Armadillo on **8080** (stop Opal) → no edit needed.
  - Coexisting with Opal: Armadillo is on **8081**, so temporarily change the four
    `:8080` → `:8081` in the ArmadilloDriver block; revert before committing.

Driver is forced from the runner via `options(default_driver = "ArmadilloDriver")`
(or `"OpalDriver"`), which overrides the default in `login_details.R`.

## 5. Run FAILING tests first, full suite last
The full smoke suite is very slow. Iterate on just the broken file(s):
```r
options(default_driver = "ArmadilloDriver")   # or "OpalDriver"
devtools::test(
  pkg    = "~/git-repos/ds-core/dsBaseClient",
  filter = "smk-ds.var")        # regex on test-<filter>.R; e.g. "smk-ds.var", "standardiseDf"
```
`setup.R` (sourced automatically by devtools::test) wires up the connections.
Only once the targeted files are green, run everything:
```r
devtools::test(pkg = "~/git-repos/ds-core/dsBaseClient")
```

**Always validate against BOTH Armadillo and Opal.** CI runs the suite on each
backend and they diverge (different drivers, disclosure defaults, object-loading
paths — an Armadillo pass is not an Opal pass and vice versa). Run the same filter
against each and reconcile before calling a branch green:
```bash
Rscript ~/.claude/notes/datashield/ds-run-tests.R armadillo <filter>
Rscript ~/.claude/notes/datashield/ds-run-tests.R opal      <filter>
```
Each needs the matching dsBase installed (§0/§2) and its own test data uploaded (§3).

To see the real server-side reason behind a `There are some DataSHIELD errors`
abort, reproduce the single call and print `DSI::datashield.errors()` — the
testthat backtrace hides it.

## 6. What CI actually runs (mirror it locally)
Configs: `.github/workflows/dsBaseClient_test_suite.yaml` (Armadillo, GHA) and
`opal_azure-pipelines.yml` / `armadillo_azure-pipelines.yml` (Azure). To reproduce a
CI result locally, match its filter + options, not an ad-hoc file list.

- **Test filter (which files run)** — a regex on the file stem (after `test-`, before
  `.R`), same on both backends' main phase:
  ```
  _-|datachk-|smk-|arg-|disc-|perf-|smk_expt-|expt-|math-
  ```
  This DELIBERATELY excludes `smk_dgr-` (and every `*_dgr-`). The "danger" tests run in
  a SEPARATE later phase, only AFTER `dsDanger` is installed on the server:
  ```
  __dgr-|datachk_dgr-|smk_dgr-|arg_dgr-|disc_dgr-|smk_expt_dgr-|expt_dgr-|math_dgr-
  ```
  So: a plain run must NOT include `smk_dgr-*` (they error with `ds.DANGERdfEXTRACT` →
  `DataSHIELD errors` unless dsDanger is on the server). `dsDangerClient` is only the
  client half; the server needs `dsadmin.install_github_package(opal,'dsDanger',ref='6.3.4')`.
- **No early stop.** CI uses `ProgressReporter$new(max_failures = 999999)` +
  `stop_on_failure = FALSE` + `options(datashield.return_errors = FALSE)`. Locally,
  `devtools::test()` defaults to `TESTTHAT_MAX_FAILS=10` and WILL terminate early — set
  `Sys.setenv(TESTTHAT_MAX_FAILS="999999")` and pass `stop_on_failure = FALSE`, or a
  handful of failures aborts the run and later files never execute.
- **dsBase build.** Armadillo GHA installs `dsBase_7.0.0-permissive.tar.gz` (prebuilt);
  Opal Azure installs from github (`ref='v7.0-dev'`) then
  `dsadmin.set_option(opal,'default.datashield.privacyControlLevel','permissive')` — the
  runtime option is equivalent to the permissive build, so a github install + that option
  == the permissive tarball. Build the permissive tarball with
  `git-repos/testing/build-permissive.sh` (source of truth; outputs `dsBase_<ver>.tar.gz`
  with `.9000` stripped into the dsBaseClient root).
- **Opal needs package admin ENABLED first**, or `dsadmin.install_*_package` → `403
  Forbidden`. CI runs `opal.put(opal,'system','conf','general','_rPackage')` before
  installing. `ds-install.R` now does this automatically.
- **To run the touched-function subset CI-faithfully:** take the branch's changed
  `test-*.R` files, keep only stems matching the main filter above (drop `*_dgr-`), and
  run them with `stop_on_failure=FALSE` + high `TESTTHAT_MAX_FAILS` under each driver.

## Gotchas learned from real runs

- **dsBase version is baked into the R-server image, not a compose knob.**
  `docker-compose_opal.yml` pins `rock: image: datashield/rock_citest-permissive:latest`
  (Armadillo similarly via its profile/rock image). There is NO compose env var to
  pick a dsBase version, and `:latest` floats — local servers drift (seen: 6.3.5 →
  7.0.0.9000 → 6.3.6.9000 on the same Opal). To pin a version, change the rock image
  tag or — the reliable way — install at runtime (§2).
- **Local Opal is http on :8080** (no `:8443` TLS); the harness Opal default is
  `https://localhost:8443/`, so override via `local_settings.csv`.
- **Do NOT create git worktrees** to run a branch's tests. A worktree holds the branch
  checked out, so the user can't check it out / pull it in their own working dir and ends
  up with a blocked `fatal: ... already checked out` git state. Check the branch out in the
  user's normal checkout (ask first), and point `ds-run-tests.R` / `devtools::test(pkg=…)`
  at that path.
- **Tests that build expected values with `tibble()`** fail with `could not find
  function "tibble"` (package not attached in the test run). Fix without adding a dep:
  build expected as base `data.frame(..., stringsAsFactors = FALSE)` and compare
  `as.data.frame(actual)`.
