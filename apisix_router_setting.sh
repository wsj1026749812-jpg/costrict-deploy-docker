# Usage: apisix_router_setting.sh [--skip-wait]
# ./apisix_router_setting.sh             
# ./apisix_router_setting.sh --skip-wait

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKIP_WAIT=false
for arg in "$@"; do
  case "$arg" in
    --skip-wait) SKIP_WAIT=true ;;
  esac
done

source "${SCRIPT_DIR}/configure.sh"
export APISIX_ADDR="127.0.0.1:${PORT_APISIX_API}"
export AUTH="X-API-KEY: ${APIKEY_APISIX_ADMIN}"
export TYPE="Content-Type: application/json"
K8S_NAMESPACE="${K8S_NAMESPACE:-costrict}"

export OIDC_CLIENT_ID="${OIDC_CLIENT_ID}"
export OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET}"
export OIDC_DISCOVERY_ADDR="${OIDC_DISCOVERY_ADDR}"
export OIDC_INTROSPECTION_ENDPOINT="${OIDC_INTROSPECTION_ENDPOINT}"

# Wait until APISIX Admin API is ready
wait_for_apisix() {
  local max_retries=30
  local interval=3
  local attempt=0
  echo "Waiting for APISIX Admin API to be ready (http://${APISIX_ADDR}) ..."
  while [ $attempt -lt $max_retries ]; do
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "${AUTH}" \
      "http://${APISIX_ADDR}/apisix/admin/routes")
    if [ "$http_code" = "200" ]; then
      echo "APISIX Admin API is ready (attempt $((attempt + 1)))"
      return 0
    fi
    attempt=$((attempt + 1))
    echo "APISIX not ready yet (HTTP $http_code), retrying in ${interval}s (${attempt}/${max_retries}) ..."
    sleep $interval
  done
  echo "ERROR: APISIX Admin API was not ready within $((max_retries * interval))s, aborting route setup." >&2
  exit 1
}

if [ "$SKIP_WAIT" = false ]; then
  kubectl -n "${K8S_NAMESPACE}" port-forward svc/apisix "${PORT_APISIX_API}:9180" >/tmp/costrict-apisix-port-forward.log 2>&1 &
  PF_PID=$!
  trap 'kill ${PF_PID} >/dev/null 2>&1 || true' EXIT
  sleep 2
  wait_for_apisix
fi

"${SCRIPT_DIR}/scripts/apisix_router/ai-gateway.sh"
"${SCRIPT_DIR}/scripts/apisix_router/casdoor.sh"
"${SCRIPT_DIR}/scripts/apisix_router/chatrag.sh"
"${SCRIPT_DIR}/scripts/apisix_router/completion-v2.sh"
"${SCRIPT_DIR}/scripts/apisix_router/costrict-apps.sh"
"${SCRIPT_DIR}/scripts/apisix_router/credit-manager.sh"
"${SCRIPT_DIR}/scripts/apisix_router/issue.sh"
"${SCRIPT_DIR}/scripts/apisix_router/oidc-auth.sh"
"${SCRIPT_DIR}/scripts/apisix_router/quota-manager.sh"

echo "APISIX routes setup completed."
