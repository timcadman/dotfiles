# Armadillo release / integration tests (`scripts/release`)

R-based end-to-end suite that drives a running Armadillo (create projects, upload
data/resources, run DataSHIELD). It is **not** run by `main.yml`. Repo:
`~/git-repos/molgenis/molgenis-service-armadillo`. See also `armadillo-local-run.md`.

- **One-time:** `./install_release_script_dependencies.R`
- **Run** (must be from the `scripts/release` dir — it reads `./.env` and relative
  `lib/` + `testthat/tests/`):
  ```
  cd scripts/release && ./release-test.R
  ```

## Configure via `.env`

Copy `dev.env.dist` to `.env` and fill in:

- `ARMADILLO_URL` — e.g. `http://localhost:8080`
- `ADMIN_PASSWORD` — admin password (e.g. `admin`)
- `OIDC_EMAIL` — researcher email. **Leave empty to run in admin mode**; set it
  (plus `TOKEN`) to run as a researcher. `ADMIN_MODE` is TRUE iff `OIDC_EMAIL` is
  empty and `ADMIN_PASSWORD` is set.
- `PROFILE` — DataSHIELD profile(s), comma-separated for multiple (e.g. `donkey`)
- `INTERACTIVE` — `N` for non-interactive (skip manual-check pauses)
- `SKIP_TESTS` — comma-separated test names, no spaces (e.g. `setup-resources,resources`)
- `DEBUG` — `Y` keeps created projects (skips teardown deletion)
- `GIT_CLONE_PATH`, `TEST_FILE_PATH` — usually auto-detected; leave empty

## Admin mode and resource tests

CI runs **admin mode only** (can't authenticate an OIDC researcher). Resource tests
(`setup-resources`, `resources`, and the exposome/omics *resolve* steps) skip in admin
mode with "Cannot test resources as admin" via `skip_if_no_resources()`; they only run
as a researcher with `resourcer` whitelisted. Note the profile auto-whitelister treats
any package reporting assign/aggregate methods as a DS package, and `resourcer` reports
an assign method — so it lands in the whitelist automatically.
