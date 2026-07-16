# Launching DataSHIELD servers (Opal + Armadillo) locally

Single launcher (source of truth): the armadillo repo's `scripts/benchmark/`.
`$ARMA` = your checkout, e.g. `~/git-repos/ds-molgenis/molgenis-service-armadillo`
(older machines: `~/git-repos/molgenis/molgenis-service-armadillo`).

> To reproduce dsBaseClient CI test failures (install dsBase, point the harness,
> run failing tests first), see `run-dsbaseclient-tests-locally.md`.

## Launch

```bash
# Armadillo only (released jar), on :8080 -- env-overridable, needs no .env:
ARMADILLO_VERSION=5.12.2 ARMA_LOCAL_PORT=8080 ARMA_USER=admin ARMA_PASS=admin \
  bash "$ARMA/scripts/benchmark/run_local_armadillo.sh"

# Opal only, via Docker:
docker compose -f "$ARMA/scripts/benchmark/opal/docker-compose.yml" up -d

# Both, version-pinned from that dir's .env:
bash "$ARMA/scripts/benchmark/start_servers.sh"
bash "$ARMA/scripts/benchmark/stop_servers.sh"     # or: start_servers.sh --down
```

The jar is cached under `scripts/benchmark/.armadillo/` and runs with a 2 GB heap
(memory parity). Basic auth is admin/admin. Health:
`curl -s localhost:8080/actuator/health` → `{"status":"UP"}`.

## Sandbox

Both the jar and Docker run **sandboxed**: the Docker socket is allowed
(`~/dotfiles/claude/settings.json`) and loopback is allowed. Unlike the old
`gradlew run`, the jar uses basic auth and makes no OIDC-on-boot call for the
sandbox proxy to block (407), so there's no unsandboxed-launch / stale-gradle-daemon
dance. If a launch ever does need unsandboxed, the `PreToolUse` Bash hook permits
commands matching `start_servers` (run via `start_servers.sh`).

## Paths
- Armadillo checkout: `$ARMA` (see top)
- dsBaseClient data: `~/git-repos/ds-core/dsBaseClient/tests/testthat/data_files`
