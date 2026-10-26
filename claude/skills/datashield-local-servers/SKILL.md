---
name: datashield-local-servers
description: Start, check and use local Opal and Armadillo servers, install a dsBase build on them, and run dsBaseClient tests or Armadillo release tests against them. Use when work needs a running DataSHIELD backend, reproduces a dsBaseClient CI failure, or calls the Armadillo storage API.
---

# Local DataSHIELD servers

The procedures live in `~/dotfiles/claude/notes/datashield/`. Read the note for the task before acting; they are not duplicated here because they drift.

| Task | Read |
|---|---|
| Start Opal and/or Armadillo (released jar, sandboxed) | `launch-datashield-servers-sandbox.md` |
| Run Armadillo from source (`./gradlew run`, unsandboxed) | `armadillo-local-run.md` |
| Reproduce a dsBaseClient CI failure | `run-dsbaseclient-tests-locally.md` |
| Install a dsBase build on a backend | `ds-install.R <opal\|armadillo> <tarball\|github-ref>` |
| Run dsBaseClient test file(s) | `ds-run-tests.R <opal\|armadillo> <filter> [pkg]` |
| Upload CSV/parquet, create projects | `armadillo-storage-api.md` |
| Armadillo release/integration suite | `armadillo-release-tests.md` |
| Benchmark slide deck | `armadillo-opal-comparison.md` |

- Armadillo is on 8080, Opal on 8081. Never put Armadillo on 8081.
- Check whether a server is already up and healthy before starting another.
- Run the failing test files first and the full suite last.
