# Launching DataSHIELD servers (Opal + Armadillo) locally

Reusable note for the `armadillo-opal-comparison` benchmark.

## Paths ($HOME-relative, neutral across laptops)
- Opal compose: `~/Library/CloudStorage/GoogleDrive-timcadman@gmail.com/Mi unidad/Work/repos/testing/opal-localhost`
- Armadillo checkout: `~/git-repos/molgenis/molgenis-service-armadillo`
- dsBaseClient data: `~/git-repos/ds-core/dsBaseClient/tests/testthat/data_files`

## Launch
`start_servers.sh` is the launcher (auto-detects the Armadillo checkout, logs to
`$TMPDIR`/`ARMA_LOG_DIR`). Opal comes up via Docker; Armadillo via `./gradlew run`.

Under the Claude Code sandbox: Opal works sandboxed (Docker socket allowed in
`~/dotfiles/claude/settings.json`). **Armadillo must run UNSANDBOXED** — its
`gradlew run` boot makes an OIDC call the sandbox's authenticated proxy blocks
(407, since the JVM can't auth to the proxy). So launch `start_servers.sh` with
`dangerouslyDisableSandbox: true`. `sandbox.allowUnsandboxedCommands` is enabled,
and a `PreToolUse` Bash hook restricts unsandboxed commands to ones matching
`gradlew|start_servers`.

**Critical gotcha — kill stale gradle daemons first.** Gradle reuses a background
daemon across invocations. If an earlier *sandboxed* `gradlew` run left a daemon,
a later *unsandboxed* run reconnects to it and the build executes under the OLD
sandbox profile → `EPERM` writing yarn/jest cache+temp (`~/Library/Caches/Yarn`,
`/var/folders/.../T`), which looks like a cache-permission problem but is not.
Fix: run `<ARMADILLO_DIR>/gradlew --stop` (unsandboxed) once before launching, so
`start_servers.sh` spawns a fresh, truly-unsandboxed daemon. Then NO proxy /
YARN_CACHE_FOLDER / TMPDIR overrides are needed — the default writable locations
work because the process is genuinely unsandboxed.

Then (sandboxed is fine; loopback allowed): `ARMA_AUTH=basic Rscript setup.R`,
then `DURATION_SEC=2 REPS=1 Rscript bench.R`.
