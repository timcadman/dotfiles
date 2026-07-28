# Running Flower apps locally (simulation) — logs & gotchas

Covers running a Flower app in the **Simulation Engine** locally (`:local:`
federation), e.g. the `molgenis-flwr-armadillo` examples (`pet-armadillo`,
`pytorch-armadillo`). Flower 1.32+.

## Config model (1.32)

Federations moved **out of** the app's `pyproject.toml` and into a global
Flower config file: `~/.flwr/config.toml`, under `[superlink.<name>]`.

```toml
[superlink.local-simulation]
address = ":local:"            # in-process simulation via Ray

[superlink.local-deployment]
address = "127.0.0.1:9093"
insecure = true
```

- `options.num-supernodes = N` inside a `[superlink.*]` connection entry is
  **deprecated** (warns on every run). Pass the count at runtime instead, or
  set it persistently:
  - per run: `flwr run . <fed> --federation-config "num-supernodes=2"`
  - persistent: `flwr federation simulation-config <fed> --num-supernodes 2`
- If the app's `pyproject.toml` still has `[tool.flwr.federations]`, `flwr` runs
  in "legacy" mode and tries to migrate; once it's commented out, use the new
  command syntax (no app path for `ls`/`log`).

## Running

```bash
pip install -e .                 # installs flwr[simulation] -> pulls Ray
flwr run . local-simulation --stream --federation-config "num-supernodes=2"
```

## Seeing logs

- `--stream` prints ServerApp/ClientApp logs inline. First output can lag a lot
  if round 1 downloads a dataset.
- Reattach to a running/finished run: `flwr log <run-id> . <superlink>`.
- Run status: `flwr ls <superlink>`  (**new syntax: superlink name only, no
  `.`**). `flwr ls . <fed>` triggers the legacy-migration error once federations
  are out of pyproject.
- `~/.flwr/local-superlink/superlink.log` holds only **control-plane** events
  (StartRun, StreamLogs polls every ~60s) — NOT app logs. If you see repeated
  `ControlServicer.StreamLogs` and nothing else, the run was created but is not
  executing (see gotchas).

## Gotcha 1 — missing Ray => run never executes

`flwr[simulation]` pulls in Ray. If Ray isn't importable, `flwr run` reports
`Successfully started run` and then hangs at `Starting logstream` forever: the
run is *created* but the Simulation Runtime can't launch, so there's no Ray
session, no dataset download, no logs.

- Verify: `python -c "import ray; print(ray.__version__)"`.
- A failed `pip install -e .` (e.g. it errored on a bad pin) means Ray never got
  installed either — fix the install and re-run.
- Exact torch pins bite here: `torch==2.4.1` has **no wheel for Python 3.13**
  (min is 2.6.0). Use `torch>=2.4.1` / `torchvision>=0.19.1` in `pyproject` for
  local dev; keep exact pins (if wanted) in the deployment Dockerfile where the
  Python version is fixed.

## Gotcha 2 — stale local SuperLink daemon

For `:local:` federations flwr manages a persistent local SuperLink on
`127.0.0.1:39093`. The running process captures its **environment and config at
startup**, so a daemon started *before* you installed deps (Ray) or changed
`~/.flwr/config.toml` keeps using the old state and silently fails to execute
new runs.

Symptoms:
- `flwr run` → `Successfully started run …` then stuck at `Starting logstream`,
  no app logs, no Ray session.
- `flwr ls <superlink>` → `Failed to start local SuperLink: flower-superlink
  exited with code 1` (the fresh one can't bind 39093 — the stale one holds it).

Diagnose & fix:
```bash
lsof -nP -iTCP -sTCP:LISTEN | grep 39093     # find the daemon PID
pkill -f flower-superlink                     # or: kill <PID>
flwr run . local-simulation --stream --federation-config "num-supernodes=2"
```
flwr then starts a fresh SuperLink with the current env/config. **Restart the
local SuperLink whenever you install new deps or edit `~/.flwr/config.toml`.**

## Quick diagnostic order when a sim "hangs at Starting logstream"

1. `python -c "import ray"` — Ray installed?  (Gotcha 1)
2. `flwr ls <superlink>` — does it error trying to start the local SuperLink?
   (Gotcha 2: stale daemon on 39093 → `pkill -f flower-superlink`)
3. `~/.flwr/local-superlink/superlink.log` — only StreamLogs polls = not
   executing; real app errors stream to the CLI, not this file.

## Publishing & reviewing apps on Flower Hub

Docs: <https://flower.ai/docs/hub/how-to-publish-app-on-hub.html> ·
<https://flower.ai/docs/hub/how-to-sign-hub-apps.html> (fetched 2026-07-21).

### Publish
`pyproject.toml` requirements:
- `[project]`: `name` (starts with a letter; letters/digits/hyphens only),
  `version`, `description`, `license`.
- `[tool.flwr.app]`: `publisher` = your Flower **account username** (must match
  exactly); `fab-format-version = 1`; `flwr-version-target` (required when
  `fab-format-version = 1`).
- App must run in BOTH simulation and deployment unchanged (branch on
  `"partition-id" in context.node_config`).

Steps:
1. Create a Flower account at flower.ai — **username must equal `publisher`**.
   (Org publishing not yet official: make a user account named after the org.)
2. `pip install flwr`
3. `flwr login supergrid` — browser auth; needs the `superlink.supergrid`
   connection (`supergrid.flower.ai`, present by default in `~/.flwr/config.toml`).
4. `flwr app publish <app-path>` — uploads **source + metadata, NOT a prebuilt
   FAB**; the Hub builds the FAB server-side (so deps must be pip-resolvable).
   App lands at `flower.ai/apps/<account>/<app>/`.
5. New version = bump `version` (semver) and re-run `flwr app publish`. Versions
   are kept side by side. **Published apps cannot be removed.**

Upload limits: allowed `*.py/.toml/.md/.yaml/.yml/.json/.jsonl` + `.gitignore`/
`.editorconfig`/`LICENSE`; excludes `.flwr/**` and `__pycache__`; ≤1000 files,
≤1 MB/file, ≤10 MB total; symlinks not followed; >10 dirs deep excluded.

### Review / sign (trust)
A reviewer signs an app so consumers can decide to trust it.
1. Reviewer generates an Ed25519 OpenSSH key and registers the **public** key in
   their Flower account profile:
   `ssh-keygen -t ed25519 -f hub_signing_key -C "hub-review-key"`
2. `flwr login supergrid`
3. `flwr app review @account/app==x.y.z` — downloads the FAB, unpacks it for
   manual inspection, prompts you to type `SIGN`, asks for the Ed25519 **private**
   key path, and submits the signature.
4. Signature appears in the app's **Verifications** section on its Hub page;
   consumers check that section to see who signed and decide trust.

Trust-model note: the Hub docs frame trust as advisory signatures ("check the
Verifications section, decide whom you trust") — they do NOT document a
supernode `--trusted-entities` flag or hard FAB-verification reject. That
enforcement lives on the **deployment/supernode** side (stock 1.32.1 e2e work),
separate from Hub signing — see [[flower-hub-migration-workflow]].
