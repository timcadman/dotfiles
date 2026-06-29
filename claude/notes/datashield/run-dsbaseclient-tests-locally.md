# Running dsBaseClient tests locally against Opal / Armadillo

Reusable workflow for reproducing CI test failures locally. Companion to
`launch-datashield-servers-sandbox.md` (how to start the servers) and
`start-datashield.sh` (the launcher).

## TL;DR order of operations
1. Start the backend (Armadillo or Opal).
2. **Install the dsBase version the branch needs** on that backend's R server.
3. Make sure test data is uploaded (usually already there).
4. Point the test harness at the backend (`local_settings.csv` + port).
5. **Run only the FAILING test files first** (fast); run the full suite last (slow).

## 0. Critical: match the dsBase server build to the client BRANCH (not just major version)
The server runs dsBase; the client (dsBaseClient) calls it. A refactor branch on the
client usually has a **matching dsBase branch** with new server-side signatures. If the
server runs a different dsBase, function signatures mismatch and ~everything errors.

- A dsBaseClient `refactor/perf-batch-N` pairs with **dsBase `refactor/perf-batch-N`**
  (e.g. dsBase PR #471 for batch-3 — new `varDS(x=string)`, `.loadServersideObject`,
  `.checkClass`, returns `class`). It does **NOT** pair with dsBase `v7.0-dev`, which
  may not have merged that batch yet.
- `v6.3.6-dev*` client → dsBase `6.3.6.x`.

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
```bash
# Armadillo only, on 8081 (Opal, if running, holds 8080):
bash ~/.claude/notes/start-datashield.sh armadillo
# or both:  bash ~/.claude/notes/start-datashield.sh both
```
Run UNSANDBOXED (gradlew boot needs it) — see launch note. Health:
`curl -s localhost:8081/actuator/health`  → `{"status":"UP"}`.

## 2. Install dsBase on the server

### Armadillo (REST via MolgenisArmadillo) — use `armadillo.install_packages()`
```r
library(MolgenisArmadillo)
armadillo.login_basic("http://localhost:8081", "admin", "admin")
armadillo.install_packages(
  paths   = "/Users/timcadman/git-repos/ds-core/dsBaseClient/dsBase_7.0.0-permissive.tar.gz",
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

## 3. Test data
The `datashield` project on a long-lived local Armadillo usually already holds
CNSIM/DASIM/standardise/etc. Check with
`MolgenisArmadillo::armadillo.list_tables("datashield")`. To (re)upload, run the
repo's upload script (edit the URL to your port):
`tests/testthat/data_files/molgenis_armadillo-upload_testing_datasets.R` (Armadillo)
or `obiba_opal-upload_testing_datasets.R` (Opal).

## 4. Point the harness at the local server
Two knobs in `tests/testthat/connection_to_datasets/`:
- **`local_settings.csv`** (gitignored): must be a BARE HOST, e.g. just `localhost`.
  `login_details.R` does `paste0("http://", <this>, ":8080")`, so a full URL like
  `http://localhost:8080` mangles to `http://http://...:8080` → "Resource assignment failed".
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
  pkg    = "/Users/timcadman/git-repos/ds-core/dsBaseClient",
  filter = "smk-ds.var")        # regex on test-<filter>.R; e.g. "smk-ds.var", "standardiseDf"
```
`setup.R` (sourced automatically by devtools::test) wires up the connections.
Only once the targeted files are green, run everything:
```r
devtools::test(pkg = "/Users/timcadman/git-repos/ds-core/dsBaseClient")
```

To see the real server-side reason behind a `There are some DataSHIELD errors`
abort, reproduce the single call and print `DSI::datashield.errors()` — the
testthat backtrace hides it.
