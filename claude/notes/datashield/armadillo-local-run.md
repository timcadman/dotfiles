# Running Armadillo locally

Armadillo is a Spring Boot app built with Gradle. Checkout:
`~/git-repos/ds-molgenis/molgenis-service-armadillo`.

For most quick/test/CSV work, prefer the **released jar**, launched **sandboxed** via
the benchmark scripts (`run_local_armadillo.sh` / `start_servers.sh`) — see
`launch-datashield-servers-sandbox.md`. This note covers running **from source** with
`./gradlew run` (the dev / full-build path), which must run **unsandboxed** (see Sandbox
below).

**Armadillo runs on 8080. Never put it on 8081 — that port belongs to Opal**, and an
Armadillo squatting there blocks Opal's compose from binding and silently absorbs admin
calls aimed at Opal (`ds-install.R opal`, whitelist POSTs). See
`launch-datashield-servers-sandbox.md`.

**ALWAYS check whether an Armadillo is already running before starting a new one.**

1. **Check 8080 first and reuse it if healthy:**
   ```
   curl -fsS http://localhost:8080/actuator/health      # -> {"status":"UP"}
   curl -s -u admin:admin http://localhost:8080/access/projects
   ```
   If it responds `UP`, **reuse it** — do not start another. Basic auth is `admin` / `admin`.

2. **Check what's actually listening before starting anything:**
   ```
   lsof -nP -iTCP:8080 -sTCP:LISTEN
   lsof -nP -iTCP:8081 -sTCP:LISTEN    # any java here is a stray Armadillo — kill it
   ```
   If 8080 is genuinely occupied by something else, stop that rather than moving Armadillo
   to 8081. `login_details.R` hardcodes `:8080` for `ArmadilloDriver`, so the dsBaseClient
   test harness cannot reach an Armadillo on any other port without patching it.

3. **Only if nothing is running, start it.** The canonical command is:
   ```
   SERVER_PORT=8080 ./gradlew run
   ```
   - Port 8080, basic auth `admin` / `admin`.
   - Readiness: `curl -fsS http://localhost:8080/actuator/health`.
   - Stop: `pkill -f 'gradlew run'`.

   Or, for the sandboxed jar path (no build), use the benchmark launchers
   `run_local_armadillo.sh` (Armadillo only) / `start_servers.sh` (both) — see
   `launch-datashield-servers-sandbox.md`.

## Sandbox

- **Do NOT disable the sandbox for arbitrary commands.** Run everything sandboxed by default.
- **Armadillo's `gradlew run` must run UNSANDBOXED.** Its boot makes an OIDC call the
  sandbox's authenticated proxy blocks (407, since the JVM can't auth to the proxy). Launch
  with `dangerouslyDisableSandbox: true`. `sandbox.allowUnsandboxedCommands` is enabled, and
  a `PreToolUse` Bash hook restricts unsandboxed commands to ones matching
  `gradlew|start_servers|run_benchmark|ds_unsandboxed`; everything else is denied unsandboxed.
- **Critical gotcha — kill stale gradle daemons first.** Gradle reuses a background daemon
  across invocations. If an earlier *sandboxed* `gradlew` run left a daemon, a later
  *unsandboxed* run reconnects to it and the build executes under the OLD sandbox profile →
  `EPERM` writing yarn/jest cache+temp (`~/Library/Caches/Yarn`, `/var/folders/.../T`), which
  looks like a cache-permission problem but is not. Fix: run `<ARMADILLO_DIR>/gradlew --stop`
  (unsandboxed) once before launching, so a fresh, truly-unsandboxed daemon spawns. Then NO
  proxy / YARN_CACHE_FOLDER / TMPDIR overrides are needed — the default writable locations
  work because the process is genuinely unsandboxed.
- **If you must run gradlew SANDBOXED instead** (fallback), two things break unless overridden:
  - Tomcat temp dir: set `JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$TMPDIR/jtmp"` (system
    `/var/folders/.../T` is not writable in the sandbox).
  - Storage dir: `bootRun`'s working dir is the `armadillo/` module, so the default relative
    `data` path fails; pass an absolute `--storage.root-dir=...` that exists and is writable.
  - For CSV-only testing, add `--armadillo.docker-management-enabled=false` to skip Docker.
