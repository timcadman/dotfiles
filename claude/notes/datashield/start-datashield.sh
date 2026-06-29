#!/usr/bin/env bash
# ==============================================================================
# Start one or both DataSHIELD backends locally.
#
#   Opal       (docker compose)            -> http://localhost:8080
#   Armadillo  (Spring Boot via gradlew)   -> http://localhost:8081
#
# Usage:
#   bash start-datashield.sh [armadillo|opal|both]    # default: both
#
# Run Armadillo UNSANDBOXED (its gradlew boot makes an OIDC call the sandbox's
# authenticated proxy blocks). See launch-datashield-servers-sandbox.md.
#
# Paths are overridable via env (defaults auto-detect common locations):
#   ARMADILLO_DIR     Armadillo checkout (has ./gradlew)
#   OPAL_COMPOSE_DIR  dir containing docker-compose.yml for Opal
#   ARMA_PORT (8081), OPAL_PORT (8080)
#
# Stop:
#   Armadillo:  kill "$(cat "$LOG_DIR/armadillo-$ARMA_PORT.pid")"   (or: pkill -f 'gradlew run')
#   Opal:       docker compose -f "$OPAL_COMPOSE_DIR/docker-compose.yml" down
# ==============================================================================
set -euo pipefail

TARGET="${1:-both}"   # armadillo | opal | both

# --- Paths ------------------------------------------------------------------
if [ -z "${ARMADILLO_DIR:-}" ]; then
  for d in "$HOME/git-repos/molgenis/molgenis-service-armadillo" \
           "$HOME/git-repos/ds-molgenis/molgenis-service-armadillo"; do
    [ -d "$d" ] && ARMADILLO_DIR="$d" && break
  done
  ARMADILLO_DIR="${ARMADILLO_DIR:-$HOME/git-repos/molgenis/molgenis-service-armadillo}"
fi
# Opal compose dir is machine-specific; set OPAL_COMPOSE_DIR if Opal is wanted.
OPAL_COMPOSE_DIR="${OPAL_COMPOSE_DIR:-$HOME/git-repos/opal-docker}"
ARMA_PORT="${ARMA_PORT:-8081}"
OPAL_PORT="${OPAL_PORT:-8080}"
LOG_DIR="${ARMA_LOG_DIR:-${TMPDIR:-/tmp}}"

wait_for() {  # name url
  local name="$1" url="$2" i
  printf 'Waiting for %s (%s) ' "$name" "$url"
  for i in $(seq 1 60); do
    if curl -fsS -o /dev/null "$url" 2>/dev/null; then echo " ready"; return 0; fi
    printf '.'; sleep 5
  done
  echo " TIMEOUT"; return 1
}

# Free a host TCP port (but never kill Docker's own proxy — compose owns those).
free_port() {  # port label
  local port="$1" label="$2" pid comm killed=0
  listeners() { lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $2, $1}' | sort -u; }
  is_docker() { case "$1" in com.docke*|docker*|vpnkit*|Docker*) return 0;; *) return 1;; esac; }
  while read -r pid comm; do
    [ -z "$pid" ] && continue
    if is_docker "$comm"; then
      echo "  $label port $port held by Docker ($comm pid $pid); leaving it for compose"
    else
      echo "  $label port $port in use by $comm (pid $pid); stopping it"
      kill "$pid" 2>/dev/null || true; killed=1
    fi
  done < <(listeners)
  [ "$killed" = 1 ] || return 0
  sleep 2
  while read -r pid comm; do
    [ -z "$pid" ] && continue
    is_docker "$comm" && continue
    echo "  $label port $port still held by $comm (pid $pid); SIGKILL"
    kill -9 "$pid" 2>/dev/null || true
  done < <(listeners)
}

start_opal() {
  echo "== Starting Opal =="
  if [ ! -f "$OPAL_COMPOSE_DIR/docker-compose.yml" ]; then
    echo "  ERROR: no docker-compose.yml in OPAL_COMPOSE_DIR=$OPAL_COMPOSE_DIR" >&2
    echo "  Set OPAL_COMPOSE_DIR to your Opal compose dir and retry." >&2
    return 1
  fi
  free_port "$OPAL_PORT" "Opal"
  docker compose -f "$OPAL_COMPOSE_DIR/docker-compose.yml" up -d
  wait_for "Opal" "http://localhost:$OPAL_PORT"
}

start_armadillo() {
  # IMPORTANT: kill stale gradle daemons first so we get a fresh, truly-unsandboxed
  # daemon (a reused sandboxed daemon causes EPERM cache/temp errors). See note.
  echo "== Stopping stale gradle daemons =="
  "$ARMADILLO_DIR/gradlew" --stop || true
  echo "== Starting Armadillo on port $ARMA_PORT =="
  free_port "$ARMA_PORT" "Armadillo"
  ( cd "$ARMADILLO_DIR"
    SERVER_PORT="$ARMA_PORT" ./gradlew run > "$LOG_DIR/armadillo-$ARMA_PORT.log" 2>&1 &
    echo "$!" > "$LOG_DIR/armadillo-$ARMA_PORT.pid" )
  echo "Armadillo PID: $(cat "$LOG_DIR/armadillo-$ARMA_PORT.pid")  (log: $LOG_DIR/armadillo-$ARMA_PORT.log)"
  wait_for "Armadillo" "http://localhost:$ARMA_PORT/actuator/health"
}

case "$TARGET" in
  opal)      start_opal ;;
  armadillo) start_armadillo ;;
  both)      start_opal || true; start_armadillo ;;
  *) echo "usage: $0 [armadillo|opal|both]" >&2; exit 2 ;;
esac

echo
echo "Done ($TARGET)."
echo "  Opal:      http://localhost:$OPAL_PORT      (administrator / datashield_test&)"
echo "  Armadillo: http://localhost:$ARMA_PORT      (admin / admin)"
