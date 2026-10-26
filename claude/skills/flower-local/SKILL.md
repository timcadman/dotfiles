---
name: flower-local
description: Run Flower federated-learning apps locally in simulation (Flower 1.32+, e.g. molgenis-flwr-armadillo examples), find their logs, and fix runs that hang. Use when running or debugging a Flower app, or working on the Flower + Armadillo integration.
---

# Flower apps, local

| Task | Read |
|---|---|
| Run an app in simulation, config, logs, hangs | `~/dotfiles/claude/notes/flower-run-local.md` |
| Flower + Armadillo integration plan | `~/dotfiles/claude/notes/flower-armadillo-implementation-plan.md` |

- Federations are configured in `~/.flwr/config.toml`, not in the app's `pyproject.toml`.
- A run that hangs at "Starting logstream" is usually missing Ray or a stale local SuperLink on 39093. The note has the fix.
