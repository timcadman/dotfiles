# Flower + Armadillo: Implementation Plan

Copy of `IMPLEMENTATION_PLAN.md` from `molgenis-flwr-armadillo` (branch `feat/data-module`, 2026-09-10).
Refresh with `git show feat/data-module:IMPLEMENTATION_PLAN.md` in `~/git-repos/ds-molgenis/molgenis-flwr-armadillo`.
Status notes not in the repo copy are at the bottom.

## Overview

This document describes how Flower federated learning integrates with MOLGENIS Armadillo for secure data access. The design mirrors the existing DataSHIELD `assign.table` pattern: authenticated requests, server-side data push into the container, and immediate file deletion after loading into memory.

The key principle: **Armadillo pushes data into the container** (via `docker exec`). The container never pulls data from Armadillo. This is the same approach DataSHIELD uses with Rserve.

**Repositories:**
- **molgenis-service-armadillo** — Java changes (endpoint, docker exec push, security)
- **molgenis-flwr-armadillo** — Python package (CLI tools, helper functions, example apps)

---

## DataSHIELD vs Flower: Side-by-Side

| Step | DataSHIELD (assign.table) | Flower (push-data) |
|------|---------------------------|----------------------|
| **1. Researcher authenticates** | Gets OIDC token | Gets OIDC token |
| **2. Researcher triggers** | `datashield.assign.table()` | Submits Flower job with token in run_config |
| **3. Job arrives** | DSI sends HTTP to Armadillo | Flower delivers run_config to ClientApp |
| **4. HTTP request to Armadillo** | DSI calls `POST /load-table` | ClientApp calls `POST /flower/push-data` |
| **5. Auth** | Spring Security + `ROLE_<PROJECT>_RESEARCHER` | Spring Security + `ROLE_<PROJECT>_RESEARCHER` |
| **6. Read from storage** | `armadilloStorage.loadTable()` | `armadilloStorage.loadObject()` |
| **7. Data push** | Rserve `writeFile()` | `docker exec cat >` into container |
| **8. Load into memory** | R reads file internally | `load_data()` reads file into bytes |
| **9. File deleted** | `base::unlink()` | `filepath.unlink()` inside `load_data()` |
| **10. Code execution** | DataSHIELD functions (file gone) | `model.fit(df)` (file gone) |
| **11. Process ends** | R session ends, container stops | ClientApp exits, container stops |

### File Lifetime — Identical Pattern

```
DataSHIELD:
──────────────────────────────────────────────────────────────────►
     │         │         │
   Write     Load    Delete                      Researcher code
     │         │         │                              │
     └────┬────┴────┬────┘                              │
      File exists   └──── Data in memory only ──────────┘


Flower:
──────────────────────────────────────────────────────────────────►
     │       │       │       │
   Write   Read   Delete   Parse                  Researcher code
           bytes          bytes                         │
     │       │       │       │                          │
     └───┬───┴───┬───┘       └── Data in memory only ───┘
     File exists
```

In both cases, the file is deleted immediately after loading into memory, before the researcher's code runs.

---

## Request Flow

```
1. Researcher authenticates (OIDC) to each Armadillo via
   armadillo-flwr-authenticate. Tokens saved locally.

2. Researcher submits Flower job via armadillo-flwr-run.
   All tokens are bundled into one run-config value,
   armadillo-tokens = base64(JSON {sanitized-url: token}),
   handed to flwr run as a private TOML file.

3. Flower routes the job. ServerApp extracts tokens from
   run_config and forwards them to ClientApps via ConfigRecord.

4. ClientApp (running inside a container started by Armadillo)
   reads ARMADILLO_URL from its environment variable, sanitizes
   it, and looks up its matching token from the ConfigRecord.

5. ClientApp calls POST /flower/push-data on Armadillo with
   the OIDC token, project, resource, and container name.

6. Armadillo (server-side):
   a. Validates OIDC token, checks project authorization
   b. Reads data from storage
   c. Pushes data into container via docker exec

7. ClientApp helper (load_data), once the push has returned:
   a. Reads file into bytes
   b. Deletes file immediately
   c. Returns raw bytes

8. Researcher code parses bytes into the format they need
   (file is gone, data in memory only)

9. Training proceeds. ClientApp exits. Memory freed by OS.
```

---

## Security Properties

| Property | DataSHIELD | Flower |
|----------|------------|--------|
| **Authentication** | OIDC via Spring Security | OIDC via Spring Security |
| **Authorization** | `ROLE_<PROJECT>_RESEARCHER` | `ROLE_<PROJECT>_RESEARCHER` |
| **Data push mechanism** | Rserve protocol | Docker exec |
| **File lifetime** | Milliseconds | Milliseconds |
| **Credentials in container?** | No | No |
| **Who controls file deletion?** | Armadillo (via Rserve) | Our helper library (`load_data()`) |

---

## Token Routing

Tokens are routed using sanitized URLs as keys. The researcher authenticates to each Armadillo server, and the authenticate CLI derives a config-safe key from each URL using `sanitize_url()` (strips scheme, lowercases, replaces non-alphanumeric chars with hyphens). All tokens travel in a single declared run-config key, `armadillo-tokens`, as a base64-encoded JSON map of `{sanitized-url: token}`: a published Flower Hub app must declare every run-config key it accepts, and per-node keys are only known at run time.

```
flower-nodes.yaml          Token file                  pyproject.toml
(researcher config)        (generated)                 (app config)

urls:                      armadillo-demo-             [tool.flwr.app.config]
  - "https://armadillo-      molgenis-net: "eyJ..."    armadillo-tokens = ""
     demo.molgenis.net"
```

On the container side, Armadillo injects the `ARMADILLO_URL` environment variable when starting the superexec container. The Python helpers read this to match the correct token:

- `get_node_url()` — reads `ARMADILLO_URL` from the environment
- `get_node_token(msg)` — decodes the `armadillo-tokens` bundle from the ConfigRecord and looks up the sanitized URL

---

## Components

### 1. Armadillo: Container Management (Java — `molgenis-service-armadillo`)

Manages Flower container lifecycle:
- **FlowerSupernodeContainerConfig** — supernode with TLS certificates, trusted entities, and Docker args (e.g. `--superlink`)
- **FlowerSuperexecContainerConfig** — clientapp container where researcher code runs
- **DockerService** — creates containers on `flower-network`, injects `ARMADILLO_CONTAINER_NAME` and `ARMADILLO_URL` env vars into superexec containers, mounts certs into supernodes

### 2. Armadillo: Push-Data Endpoint (Java — `molgenis-service-armadillo`)

`POST /flower/push-data` endpoint that:
- Accepts `{ project, resource, containerName }` plus an OIDC Bearer token
- Checks authorization via `@PreAuthorize` (`ROLE_SU` or `ROLE_{PROJECT}_RESEARCHER`)
- Reads data from storage using `armadilloStorage.loadObject()`
- Copies data into the container via Docker API (`copyArchiveToContainerCmd`)
- Returns 204 No Content

### 3. Python Package: `molgenis-flwr-armadillo`

**CLI tools:**
- `armadillo-flwr-authenticate` — authenticates to each Armadillo URL via OIDC device flow, saves tokens
- `armadillo-flwr-run` — loads tokens and injects them into `flwr run --run-config`
- `armadillo-flwr-resources` — lists accessible projects and resources on each Armadillo

**Helper functions (for use in Flower apps):**
- `extract_tokens(context)` — returns the `armadillo-tokens` bundle from run_config for the server to forward
- `get_node_url()` — reads `ARMADILLO_URL` env var
- `get_node_token(msg)` — matches this node's token from the ConfigRecord
- `sanitize_url(url)` — converts URL to a config-safe key
- `load_data(url, token, project, resource)` — requests data push, reads file, deletes it, returns bytes
- `list_projects(url, token)` — lists accessible projects
- `list_resources(url, token, project)` — lists resources in a project
- `check_access(url, token, project, resources)` — verifies access before training

---

## Implementation Stages

### Stage 1: Token Routing

Pass OIDC tokens via Flower's run_config. Each ClientApp receives all tokens and picks its own by matching the sanitized `ARMADILLO_URL` from its environment.

### Stage 2: Push-Data Endpoint (Armadillo)

`POST /flower/push-data` endpoint. Reuses existing auth, storage, and Docker client. Data pushed into container via `docker exec` / Docker API tar copy.

### Stage 3: Python Data Helpers (molgenis-flwr-armadillo)

`load_data()` helper and supporting functions. End-to-end flow: authenticate → submit job → data pushed → model trained.

### Stage 4: Differential Privacy

Client-side clipping on model parameters. Clients clip updates before sending, server adds noise after aggregation.

### Stage 5: Per-Container Permissions

Extend Armadillo's permission model so users have access to specific containers, not just projects. Currently `User → Project → [all containers]`, target is `User → Project → Container(s)`.

#### Why Per-Container Matters

**Reusable across DataSHIELD and Flower.** Container-level permissions are not Flower-specific — they apply equally to DataSHIELD profiles. Currently any researcher with project access can select any DataSHIELD profile (`POST /select-profile` has no container authorization) and any Flower container (`POST /flower/push-data` checks the project but not the container name). Per-container permissions close this gap for both.

**Controls whether a researcher can use Flower at all.** A Flower supernode is a container. If a researcher doesn't have permission for any Flower container, they effectively can't use Flower on that Armadillo instance — even if they have project access. This gives admins a clean way to enable or disable Flower for specific researchers without changing project permissions.

#### Enforcement Points

Both DataSHIELD and Flower already pass the container name through their request path, so enforcement requires minimal plumbing:

| Use case | Where enforced | Current check | Added check |
|----------|---------------|---------------|-------------|
| DataSHIELD profile selection | `DataController.selectContainer()` | Authenticated user only | + user has permission for container |
| Flower data push | `FlowerDataService.pushData()` | `ROLE_{PROJECT}_RESEARCHER` | + user has permission for `containerName` |

#### Container Self-Identification Vulnerability

**Problem:** The current `POST /flower/push-data` endpoint trusts the `containerName` field in the request body. The clientapp reads `ARMADILLO_CONTAINER_NAME` from its own environment and sends it to Armadillo. But a malicious app running inside the container could send a different container name, bypassing per-container permissions or pushing data into another container.

**Fix: Server-side container identity resolution.** Remove `containerName` from the request body entirely. Instead, Armadillo resolves the calling container from the source IP of the HTTP request.

**How it works:**

1. The clientapp calls `POST /flower/push-data` with only `project` and `resource` (no `containerName`)
2. `FlowerController.pushData()` reads the source IP from `HttpServletRequest.getRemoteAddr()`
3. Armadillo resolves the IP to a container name by inspecting the Docker network:
   ```java
   // Docker Java API equivalent of: docker network inspect flower-network
   dockerClient.inspectNetworkCmd()
       .withNetworkId("flower-network")
       .exec()
       .getContainers()  // Map<String, ContainerNetworkConfig>
       // find the entry whose IPv4Address matches remoteAddr
   ```
4. If no container matches the source IP → 403 Forbidden (request didn't come from a managed container)
5. The resolved container name is used for the `docker exec` push and for per-container permission checks

**Why this is reliable:** Flower containers already run on a dedicated Docker bridge network (`flower-network`). On a bridge network, each container gets a stable IP that's visible to Armadillo via the Docker API. The IP→container mapping is authoritative — Docker manages it, not the container.

**Changes required:**

| Component | Change |
|-----------|--------|
| `PushDataRequest` | Remove `containerName` field |
| `FlowerController.pushData()` | Inject `HttpServletRequest`, pass `request.getRemoteAddr()` to service |
| `FlowerDataService.pushData()` | Accept source IP instead of container name, resolve via Docker API |
| `FlowerDockerService` | New method: `resolveContainerByIp(String networkName, String ip)` |
| `data.py` (`load_data()`) | Remove `containerName` from the request body, remove `ARMADILLO_CONTAINER_NAME` env var dependency |
| `DockerService.configureEnv()` | No longer needs to set `ARMADILLO_CONTAINER_NAME` |

### Stage 6: Result Storage

Allow researchers to upload model results to Armadillo and retrieve them later.

---

## Manual Review Checklist

Researcher-submitted Flower app code should be reviewed for:

- [ ] Uses `load_data()` to get data
- [ ] Does not access the data directory directly
- [ ] No hardcoded file paths
- [ ] No exfiltration of raw bytes

---

## Open Questions

1. **Server-side evaluation:** ServerApp needs test data for `global_evaluate()`. Options: (a) client-side evaluation only, (b) push data to the ServerApp container too.

2. **OIDC token refresh:** If access token expires during long training, refresh token is available. Could add automatic refresh to Python helpers.

---

## Status notes (updated 2026-09-11 — not in the repo copy)

**PRs (all pushed, all ready for review).**
- molgenis-service-armadillo, stacked: #985 container classes + Docker service → #986 push-data endpoint → #1066 whitelist config + endpoint.
  - #985: SuperExec containers start with the `armadillo-flwr-superexec` entrypoint plus `--fab-whitelist /app/fab-whitelist.yaml`, so the stock `flwr/superexec` image won't start.
  - #986: a container that isn't a SuperExec container returns 400 (`NotFlowerSuperexecContainerException`).
  - #1066: a general container save keeps the stored whitelist and rewrites the file from it. The file is written after the settings are saved, so a failed write leaves the app blocked. Hashes are stored in lower case, and the audit record includes `fabId`, `fabVersion` and `fabHash`.
- molgenis-flwr-armadillo:
  - #5 core (auth CLI, token routing, `_http`) → master.
  - #10 `load_data` → #5; #11 superexec image + whitelist plugin → #10; #4 example app → #10 (imports the package; published to Flower Hub as `timmyjc/quickstart-pytorch-armadillo` 1.0.4).
  - #6 API helpers + resources CLI → #5; #12 review-app / approve-app CLIs → #5.
  - Merge order: #5, #10, #11, #4, #6, #12.
- CI:
  - Python: all green on 3.11/3.12/3.13, Ruff 0.16.7 clean. `master` ruleset active, head branches deleted automatically so stacked PRs retarget.
  - Java: CircleCI always fails (known). SonarCloud gate fails on #985 (not yet looked at) and passes on #986/#1066. Sonar runs inside CircleCI; if the tests there stop early, coverage may be incomplete.
- `feat/#2053-ui-for-containers` container UI: the colleague's branch, out of date. Rebase once #985 merges.

**Decisions.**
- Token routing: a single `armadillo-tokens` base64 key; run-config passed as a 0600 TOML file; token file `~/.molgenis-flwr/tokens.json`, 0600. Final design, in core.
- Server-side evaluation data comes through the push-data endpoint (open question 1 resolved). Returning results is handled by Flower itself, with no Armadillo work.
- The whitelist is enforced by the image entrypoint, and Armadillo sets the entrypoint. Reviewing and approving are separate CLIs (`armadillo-flwr-review-app`, `armadillo-flwr-approve-app`) because a review can take hours.
- Python >= 3.11, `flwr>=1.32.0,<1.33`. Error messages match DSMolgenisArmadillo's `.handle_request_error`. pandas 3.0.5 in the superexec image.

**Implementation notes / open.**
- Publish `molgenis-auth` and `molgenis-flwr-armadillo` to PyPI: removes the git pins in `pyproject.toml` and the superexec Dockerfile.
- Container identity (with the colleague): #986 trusts the client-supplied `containerName` / `ARMADILLO_CONTAINER_NAME`; Stage 5 is undecided and unbuilt. Blocks a real release.
- Also with the colleague: the container finds its token by `sanitize_url(ARMADILLO_URL)`, so `flower.armadillo-url` must match the URL in the researcher's `flower-nodes.yaml`. An internal or bridge-gateway URL (needed for identity option 3) breaks every run with "No token found" unless the token key gets its own setting.
- #1066 can add or replace a whitelist hash, but can't list or revoke one.
- Token refresh (open question 2) not built.
- Every ClientApp receives the whole token bundle for all nodes, and it passes through the SuperLink. Design-level exposure, not yet assessed.
- #986 DataSHIELD divergences still open: `FlowerDataService.pushData` repeats the `@PreAuthorize` already on `ArmadilloStorageService.loadObject`; `PushDataRequest` is `@NotBlank` only, where `load-table` validates with `TABLE_RESOURCE_REGEX`/`SYMBOL_RE`.
- Docs, at the end of the review order: a Python docs PR (add `docs/reference.md` with `::: molgenis_flwr_armadillo`, since `mkdocs.yml` already links to it) and Armadillo docs.
- Core `README.md` line 3 typo ("with in conjuncture with") — parked.
- End-to-end release test: not ready; shown dashed on the slides.
  - Current work is on `test/flower-release-staging` in molgenis-service-armadillo: local only, not pushed, last commit 56f05dd3 on 2026-08-18 (added Scenario G, per-node whitelist isolation), 51 commits beyond #1066. It needs rebasing onto the current stack and checking against it.
  - `test/flower-release-test` is an older local branch (2026-07-31).
  - The Python `test/fab-whitelist-staging` was deleted from GitHub on 2026-09-11. It merged the pre-#11 branches, so it's out of date; a local copy remains at a8126c60.
- **Large data (must handle; 2026-09-11).** #986 `FlowerDockerService.copyDataToContainer` holds ~3 copies of the file on the heap (`readAllBytes` + in-memory tar); files over ~2 GB fail outright (Java array limit). Fix in #986, ~half a day: `FlowerDataService` passes the size from `ArmadilloStorageService.getFileSizeIfObjectExists` plus the open stream; `FlowerDockerService` writes the tar header from that size and streams the content through a piped stream on a background thread into `withTarInputStream` (constant memory). Alternative: temp tar file on disk (no thread, but writes every file twice). Update `FlowerDockerServiceTest`, add a larger-than-memory stream test, and do a manual multi-GB push.
  - Timeouts: Python `load_data` POST timeout is 300 s; Armadillo's Docker client (`DockerClientConfig`) has a 45 s response timeout. Unverified whether the 45 s bites during a long upload; the multi-GB test will show. Likely need longer limits.
  - Container memory: `load_data` returns the whole file as bytes, and parsing (pandas/torch) makes a second copy. Avoiding that means returning a file path instead, which changes the "read into memory and delete immediately" design. Design decision, not part of the #986 fix.

**Implementation review (2026-09-10) — outcome.**
- Fixed since:
  - #11 re-reads the whitelist for every task and fails closed.
  - `flwr` is pinned to `>=1.32.0,<1.33` in core.
  - `_report_rejection` catches any exception.
  - `verified_superexec.py` is down to four arguments.
  - The whitelist path is now an instance attribute.
  - `approve_app` uses `_auth_headers` / `describe_http_error`.
- Still open:
  - `approve_app.add_to_whitelist` (basic auth) and `authenticate.get_auth_info` call `requests` directly rather than `_http._request`.
  - The #986 DataSHIELD divergences above.
- Container chosen per request (`containerName`) vs DataSHIELD's server-held `select-profile` session is the pending identity decision. Verify-claim (2) or resolve-from-IP (3) restore the server-side shape. Both need `flower.armadillo-url` = bridge gateway, `--cap-drop NET_RAW` on Flower containers, and `forward-headers-strategy: framework` kept.
- Audit events are consistent with DataSHIELD's.
