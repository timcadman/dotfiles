# Launching DataSHIELD servers (Opal + Armadillo) locally

**Source of truth: `scripts/benchmark/README.md` in the armadillo repo.** Read the
launch commands there — they are deliberately NOT duplicated here, because they drift.
This note holds only the local/sandbox facts that README can't know.

`$ARMA` = `~/git-repos/ds-molgenis/molgenis-service-armadillo`

> To reproduce dsBaseClient CI test failures (install dsBase, point the harness,
> run failing tests first), see `run-dsbaseclient-tests-locally.md`.

## Which branch to read it from

**Check `master` first.** As of 2026-07-20 the benchmark scripts are not yet merged —
they live on the `scripts-benchmark` branch, expected to land in master the week of
2026-07-20. **Once merged, delete this section and always read master.**

Symptom that you're on a branch without them: `$ARMA/scripts/benchmark/` contains only
`logs/` and `results/`, and every `scripts/benchmark/...` path in these notes appears
to not exist.

Read from the branch without checking it out or making a worktree (a worktree would
block your own checkout of that branch):

```bash
git -C "$ARMA" ls-tree --name-only scripts-benchmark:scripts/benchmark/
git -C "$ARMA" show scripts-benchmark:scripts/benchmark/README.md
git -C "$ARMA" show scripts-benchmark:scripts/benchmark/.env.dist
# To actually run a file from the branch, extract it first:
git -C "$ARMA" show scripts-benchmark:scripts/benchmark/opal/docker-compose.yml > "$TMPDIR/opal-compose.yml"
```

## Local facts not in the README

- **Port convention: Armadillo `:8080`, Opal `:8081`** (from `.env.dist`:
  `ARMA_LOCAL_PORT` / `OPAL_LOCAL_PORT`; both are overridable). Both can run at once.
  Beware: dsBaseClient's own `docker-compose_opal.yml` puts **Opal on 8080** instead —
  see the "two stacks" gotcha in `run-dsbaseclient-tests-locally.md`.
- **Armadillo must NOT be on 8081 — that port belongs to Opal.** A stray second
  Armadillo there (e.g. a jar started with `ARMA_LOCAL_PORT=8081`, or a leftover from an
  earlier session) will block Opal's compose from binding, and will silently absorb
  `ds-install.R opal` / any admin call aimed at 8081. Check and stop it before starting
  Opal:
  ```bash
  lsof -nP -iTCP:8081 -sTCP:LISTEN          # any java here = stray Armadillo
  curl -s -u admin:admin localhost:8081/actuator/info   # molgenis-armadillo JSON confirms it
  kill <pid>                                 # jar; or: docker stop <container>
  ```
  Correct end state: **Armadillo on 8080 only, Opal on 8081** (plus Opal's TLS 8443).
- **Identify what's on a port before installing anything into it:**
  `curl -s -u admin:admin localhost:<port>/actuator/info` — Armadillo returns
  `molgenis-armadillo` build JSON, Opal 404s. Installing dsBase against the wrong port
  silently targets the other instance.
- **Health:** Armadillo `curl -s localhost:8080/actuator/health` → `{"status":"UP"}`.
  Opal has no `/actuator/health` (Jetty, not Spring Boot) — a 404 is normal; probe
  `curl -s localhost:8081/` (200) or log in via `opalr`.
- **The released jar can crash-loop** / recreate its containers under sustained heavy
  test load, losing runtime-installed dsBase (reverts to the rock image's baked-in
  version) and the uploaded data. After any restart, re-verify dsBase version + data
  before trusting a run (see `run-dsbaseclient-tests-locally.md` §2–3).

## Sandbox

Both the jar and Docker run **sandboxed**: the Docker socket is allowed
(`~/dotfiles/claude/settings.json`) and loopback is allowed. The jar uses basic auth and
makes no OIDC-on-boot call for the sandbox proxy to block (407), so there's no
unsandboxed-launch / stale-gradle-daemon dance. If a launch ever does need unsandboxed,
the `PreToolUse` Bash hook permits commands matching
`gradlew|start_servers|run_benchmark|ds_unsandboxed`.

Note the sandbox blocks in-place edits (`perl -i`) and process substitution
(`<(...)`) under `~/dotfiles` — write to `$TMPDIR` and compare files instead.

To run Armadillo **from source** (`./gradlew run`) instead of the jar — the dev /
full-build path, which must run unsandboxed and has a stale-gradle-daemon gotcha — see
`armadillo-local-run.md`.

## Paths
- Armadillo checkout: `$ARMA` (see top)
- dsBaseClient data: `~/git-repos/ds-core/dsBaseClient/tests/testthat/data_files`
