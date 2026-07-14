# Launching DataSHIELD servers (Opal + Armadillo) locally

Reusable note for the `armadillo-opal-comparison` benchmark.

> Reproduce dsBaseClient CI test failures locally (install dsBase, point the harness,
> run failing tests first): `run-dsbaseclient-tests-locally.md`.
> Armadillo sandbox rules + stale-gradle-daemon gotcha: `armadillo-local-run.md`.
> Parameterized launcher (start just one server): `start-datashield.sh`.

## Paths ($HOME-relative, neutral across laptops)
- Opal compose: `~/Library/CloudStorage/GoogleDrive-timcadman@gmail.com/Mi unidad/Work/repos/testing/opal-localhost`
- Armadillo checkout: `~/git-repos/molgenis/molgenis-service-armadillo`
- dsBaseClient data: `~/git-repos/ds-core/dsBaseClient/tests/testthat/data_files`

## Launch
`start-datashield.sh` is the launcher (auto-detects the Armadillo checkout, logs to
`$TMPDIR`/`ARMA_LOG_DIR`). Opal comes up via Docker; Armadillo via `./gradlew run`.

Under the Claude Code sandbox, Opal works sandboxed (Docker socket allowed in
`~/dotfiles/claude/settings.json`), but **Armadillo must run UNSANDBOXED** — launch
`start-datashield.sh` with `dangerouslyDisableSandbox: true`, and kill stale gradle
daemons first. Full rationale + the EPERM/stale-daemon gotcha: `armadillo-local-run.md`.

Then (sandboxed is fine; loopback allowed): `ARMA_AUTH=basic Rscript setup.R`,
then `DURATION_SEC=2 REPS=1 Rscript bench.R`.
