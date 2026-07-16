#!/usr/bin/env bash
# =============================================================================
# costrict.sh — Costrict Kubernetes 部署管理入口脚本
# 用法: ./costrict.sh <command> [options]
# 命令:
#   check    — 检查环境依赖（kubectl、Kubernetes 集群等）
#   prepare  — 准备部署环境（生成配置、解析模板等）
#   install  — 完整安装（prepare + 启动所有服务）
#   down     — 删除 Kubernetes 资源
#   up       — 启动所有服务
#   info     — 打印访问地址等提示信息
# =============================================================================

# set -euo pipefail

# 脚本所在目录（绝对路径，兼容软链接调用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载日志工具（颜色输出函数：info / success / warn / error / die）
# shellcheck source=scripts/logger/log_tool.sh
source "${SCRIPT_DIR}/scripts/logger/log_tool.sh"

load_config() {
  if [[ -f "${SCRIPT_DIR}/configure.sh" ]]; then
    # shellcheck source=configure.sh
    source "${SCRIPT_DIR}/configure.sh"
  else
    die "configure.sh 不存在，请在 configure.sh 中配置后重试。"
  fi

  export COSTRICT_DEPLOY_DIR="${COSTRICT_DEPLOY_DIR:-${SCRIPT_DIR}}"
  export COSTRICT_BACKEND_SCHEME="${COSTRICT_BACKEND_SCHEME:-http}"
  export K8S_NAMESPACE="${K8S_NAMESPACE:-costrict}"
  export K8S_APISIX_HOST="${K8S_APISIX_HOST:-${COSTRICT_BACKEND}}"
  export K8S_NODEPORT_APISIX="${K8S_NODEPORT_APISIX:-${PORT_APISIX_ENTRY}}"
  export K8S_NODEPORT_CASDOOR="${K8S_NODEPORT_CASDOOR:-30009}"
  export K8S_NODEPORT_NACOS="${K8S_NODEPORT_NACOS:-${PORT_NACOS}}"
  export K8S_NODEPORT_OIDC_AUTH="${K8S_NODEPORT_OIDC_AUTH:-30093}"
  export K8S_NODEPORT_CHATRAG="${K8S_NODEPORT_CHATRAG:-30094}"
  export K8S_STATIC_PV_BASE_PATH="${K8S_STATIC_PV_BASE_PATH:-/export/costrict}"
  export EXTERNAL_PORT_APISIX="${EXTERNAL_PORT_APISIX:-${K8S_NODEPORT_APISIX}}"
  export EXTERNAL_PORT_CASDOOR="${EXTERNAL_PORT_CASDOOR:-${K8S_NODEPORT_CASDOOR}}"
  export EXTERNAL_PORT_NACOS="${EXTERNAL_PORT_NACOS:-${K8S_NODEPORT_NACOS}}"
  export EXTERNAL_PORT_OIDC_AUTH="${EXTERNAL_PORT_OIDC_AUTH:-${K8S_NODEPORT_OIDC_AUTH}}"
  export EXTERNAL_PORT_CHATRAG="${EXTERNAL_PORT_CHATRAG:-${K8S_NODEPORT_CHATRAG}}"
  export COSTRICT_BACKEND_BASEURL="${COSTRICT_BACKEND_BASEURL:-${COSTRICT_BACKEND_SCHEME}://${COSTRICT_BACKEND}:${EXTERNAL_PORT_APISIX}}"
  export CASDOOR_EXTERNAL_BASEURL="${CASDOOR_EXTERNAL_BASEURL:-${COSTRICT_BACKEND_BASEURL}}"
  export OIDC_AUTH_EXTERNAL_BASEURL="${OIDC_AUTH_EXTERNAL_BASEURL:-${COSTRICT_BACKEND_BASEURL}}"
  export CHATRAG_EXTERNAL_BASEURL="${CHATRAG_EXTERNAL_BASEURL:-${COSTRICT_BACKEND_BASEURL}}"
  export K8S_NODE_SELECTOR_KEY="${K8S_NODE_SELECTOR_KEY:-org}"
  export K8S_NODE_SELECTOR_VALUE="${K8S_NODE_SELECTOR_VALUE:-dicode}"
}

apply_configmap() {
  local name="$1"
  shift
  kubectl -n "${K8S_NAMESPACE}" delete configmap "${name}" --ignore-not-found
  kubectl -n "${K8S_NAMESPACE}" create configmap "${name}" "$@"
}

apply_k8s_configmaps() {
  info "正在创建/更新 Kubernetes ConfigMap..."

  kubectl create namespace "${K8S_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  apply_configmap costrict-apisix-config \
    --from-file=config.yaml="${SCRIPT_DIR}/config/apisix/config.yaml"
  apply_configmap costrict-model-proxy-config \
    --from-file=config.yaml="${SCRIPT_DIR}/config/model-proxy/config.yaml"
  apply_configmap costrict-portal-nginx-config \
    --from-file=nginx.conf="${SCRIPT_DIR}/config/portal/nginx.conf"
  apply_configmap costrict-chat-rag-config \
    --from-file=chat-api.yaml="${SCRIPT_DIR}/config/chat-rag/chat-api.yaml" \
    --from-file=rules.yaml="${SCRIPT_DIR}/config/chat-rag/rules.yaml"
  apply_configmap costrict-code-completion-config \
    --from-file=config.yaml="${SCRIPT_DIR}/config/code-completion/config.yaml"
  apply_configmap costrict-prometheus-config \
    --from-file=prometheus.yml="${SCRIPT_DIR}/config/prometheus/prometheus.yml"
  apply_configmap costrict-grafana-config \
    --from-file=grafana.ini="${SCRIPT_DIR}/config/grafana/config/grafana.ini"
  apply_configmap costrict-grafana-provisioning-datasources \
    --from-file=all.yaml="${SCRIPT_DIR}/config/grafana/provisioning/datasources/all.yaml"
  apply_configmap costrict-grafana-provisioning-dashboards \
    --from-file=all.yaml="${SCRIPT_DIR}/config/grafana/provisioning/dashboards/all.yaml"
  apply_configmap costrict-grafana-dashboards \
    --from-file=apisix-grafana-dashboard.json="${SCRIPT_DIR}/config/grafana/dashboards/apisix-grafana-dashboard.json"
  apply_configmap costrict-postgres-initdb \
    --from-file="${SCRIPT_DIR}/config/postgres/initdb.d"

  success "ConfigMap 创建/更新完成。"
}

sync_portal_assets() {
  local portal_dir="${SCRIPT_DIR}/data/portal"
  if [[ ! -d "${portal_dir}" ]]; then
    warn "portal 静态资源目录不存在，跳过同步：${portal_dir}"
    return 0
  fi

  if ! find "${portal_dir}" -mindepth 1 -maxdepth 1 | read -r _; then
    warn "portal 静态资源目录为空，跳过同步：${portal_dir}"
    return 0
  fi

  local pod
  pod="$(kubectl -n "${K8S_NAMESPACE}" get pod -l app=portal -o jsonpath='{.items[0].metadata.name}')"
  if [[ -z "${pod}" ]]; then
    warn "未找到 portal Pod，跳过静态资源同步。"
    return 0
  fi

  info "正在同步 portal 静态资源到 PVC..."
  kubectl -n "${K8S_NAMESPACE}" cp "${portal_dir}/." "${pod}:/var/www"
  success "portal 静态资源同步完成。"
}

prepare_portal_assets() {
  local source_dir="${SCRIPT_DIR}/config/portal/static_file"
  local target_dir="${SCRIPT_DIR}/data/portal"
  mkdir -p "${target_dir}"

  local asset
  for asset in costrict costrict-static wasm; do
    if [[ -e "${source_dir}/${asset}" && ! -e "${target_dir}/${asset}" ]]; then
      cp -R "${source_dir}/${asset}" "${target_dir}/"
    fi
  done

  chmod -R +r "${target_dir}" 2>/dev/null || true
}

wait_k8s_rollout() {
  local deployments=(
    etcd
    redis
    postgres
    nacos
    apisix
    model-proxy
    portal
    chat-rag
    credit-manager
    oidc-auth
    code-completion
    casdoor
    prometheus
    grafana
  )

  for deployment in "${deployments[@]}"; do
    kubectl -n "${K8S_NAMESPACE}" rollout status "deployment/${deployment}" --timeout=300s || return 1
  done
}

# -----------------------------------------------------------------------------
# check — 检查运行环境
# -----------------------------------------------------------------------------
cmd_check() {
  info "开始检查运行环境..."

  local all_ok=true

  _check_cmd() {
    local cmd="$1"
    local min_ver="${2:-}"
    if command -v "${cmd}" &>/dev/null; then
      local ver
      ver="$(${cmd} --version 2>&1 | head -n1)"
      success "${cmd} 已安装：${ver}"
    else
      error "${cmd} 未找到，请先安装后再继续。"
      all_ok=false
    fi
  }

  _check_cmd kubectl
  if kubectl cluster-info &>/dev/null; then
    success "Kubernetes 集群连接正常。"
  else
    error "无法连接 Kubernetes 集群，请检查 kubeconfig/current-context。"
    all_ok=false
  fi

  # 检查必要文件
  local required_files=(
    "${SCRIPT_DIR}/k8s/costrict.yaml.tpl"
    "${SCRIPT_DIR}/scripts/newest-images.list"
    "${SCRIPT_DIR}/configure.sh"
  )
  for f in "${required_files[@]}"; do
    if [[ -f "${f}" ]]; then
      success "文件存在：${f}"
    else
      warn "文件缺失：${f}"
    fi
  done

  if [[ "${all_ok}" == true ]]; then
    success "环境检查通过！"
  else
    die "环境检查发现问题，请修复后重试。"
  fi

  # 检查重要环境变量配置，如果为空，会导致较复杂的问题
  load_config

  _check_env() {
    local var="$1"
    if [[ -n "${!var:-}" ]]; then
      success "${var} 已设置：${!var}"
    else
      error "${var} 未设置，请在 configure.sh 中配置后重试。"
      all_ok=false
    fi
  }

  local env_vars=(
    "COSTRICT_BACKEND"
    "COSTRICT_BACKEND_SCHEME"
    "COSTRICT_BACKEND_BASEURL"
    "CASDOOR_EXTERNAL_BASEURL"
    "OIDC_AUTH_EXTERNAL_BASEURL"
    "CHATRAG_EXTERNAL_BASEURL"
    "EXTERNAL_PORT_APISIX"
    "EXTERNAL_PORT_CASDOOR"
    "EXTERNAL_PORT_NACOS"
    "EXTERNAL_PORT_OIDC_AUTH"
    "EXTERNAL_PORT_CHATRAG"
    "PORT_APISIX_ENTRY"
    "K8S_NAMESPACE"
    "K8S_INGRESS_CLASS_NAME"
    "K8S_APISIX_HOST"
    "K8S_APISIX_TLS_SECRET_NAME"
    "K8S_NODE_SELECTOR_KEY"
    "K8S_NODE_SELECTOR_VALUE"
    "K8S_STATEFUL_NODE_NAME"
    "K8S_STATIC_PV_BASE_PATH"
    "K8S_NODEPORT_APISIX"
    "K8S_NODEPORT_CASDOOR"
    "K8S_NODEPORT_NACOS"
    "K8S_NODEPORT_OIDC_AUTH"
    "K8S_NODEPORT_CHATRAG"
  )
  for v in "${env_vars[@]}"; do
    _check_env "${v}"
  done

  if [[ "${all_ok}" == false ]]; then
    die "存在必填环境变量未配置，请编辑 configure.sh 后重试。"
  fi

  local default_sc
  default_sc="$(kubectl get storageclass -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{" "}{end}' 2>/dev/null || true)"
  if [[ -n "${default_sc}" ]]; then
    success "默认 StorageClass：${default_sc}"
  else
    warn "未检测到默认 StorageClass，PVC 可能无法自动创建 PV。请先配置默认 StorageClass，或手工给 PVC 指定 storageClassName。"
  fi

  if kubectl get ingressclass "${K8S_INGRESS_CLASS_NAME}" &>/dev/null; then
    success "IngressClass 存在：${K8S_INGRESS_CLASS_NAME}"
  else
    warn "未检测到 IngressClass：${K8S_INGRESS_CLASS_NAME}。HTTPS 域名入口可能不可用。"
  fi

  if kubectl -n "${K8S_NAMESPACE}" get secret "${K8S_APISIX_TLS_SECRET_NAME}" &>/dev/null; then
    success "TLS Secret 存在：${K8S_APISIX_TLS_SECRET_NAME}"
  else
    warn "未检测到 TLS Secret：${K8S_APISIX_TLS_SECRET_NAME}。如需 HTTPS，请先在 ${K8S_NAMESPACE} 命名空间创建该 Secret。"
  fi

  if kubectl get node "${K8S_STATEFUL_NODE_NAME}" &>/dev/null; then
    success "有状态服务固定节点存在：${K8S_STATEFUL_NODE_NAME}"
    info "静态 PV 基础目录：${K8S_STATIC_PV_BASE_PATH}，如目录不存在将由 kubelet 通过 hostPath DirectoryOrCreate 自动创建。"
  else
    warn "未检测到节点：${K8S_STATEFUL_NODE_NAME}。请检查 configure.sh 的 K8S_STATEFUL_NODE_NAME。"
  fi

  success "环境检查通过！"

}

# -----------------------------------------------------------------------------
# prepare — 准备部署环境（解析模板、生成配置）
# -----------------------------------------------------------------------------
cmd_prepare() {
  info "开始准备部署环境..."

  # 运行配置脚本，set -a 使所有变量自动 export 到子进程
  load_config

  # 解析模板
  if [[ -f "${SCRIPT_DIR}/scripts/template_gen.sh" ]]; then
    info "正在解析配置模板..."
    (cd "${SCRIPT_DIR}" && bash "${SCRIPT_DIR}/scripts/template_gen.sh")
    success "模板解析完成。"
  else
    die "scripts/template_gen.sh 不存在"
  fi

  prepare_portal_assets
  success "部署环境准备完毕！"
}

# -----------------------------------------------------------------------------
# User Reminder — 用户提示
# -----------------------------------------------------------------------------

cmd_user_reminder() {
  info "BaseUrl请设置为 ${COSTRICT_BACKEND_BASEURL}/"
  info "Casdoor统一入口：${CASDOOR_EXTERNAL_BASEURL}/"
  info "OIDC/Auth统一入口：${OIDC_AUTH_EXTERNAL_BASEURL}/oidc-auth/"
  info "Chat-RAG统一入口：${CHATRAG_EXTERNAL_BASEURL}/chat-rag/"
  info "OA/Casdoor回调地址请使用 ${OIDC_AUTH_EXTERNAL_BASEURL}/oidc-auth/api/v1/plugin/login/callback 等 /oidc-auth 下路径"
  info "配置Chat模型请访问 (nacos) ${COSTRICT_BACKEND_SCHEME}://${COSTRICT_BACKEND}:${EXTERNAL_PORT_NACOS}/"
  info "端口映射关系：APISIX ${EXTERNAL_PORT_APISIX}->${K8S_NODEPORT_APISIX}, Casdoor ${EXTERNAL_PORT_CASDOOR}->${K8S_NODEPORT_CASDOOR}, OIDC ${EXTERNAL_PORT_OIDC_AUTH}->${K8S_NODEPORT_OIDC_AUTH}, Chat-RAG ${EXTERNAL_PORT_CHATRAG}->${K8S_NODEPORT_CHATRAG}"
}

# -----------------------------------------------------------------------------
# install — 完整安装（prepare + up）
# -----------------------------------------------------------------------------
cmd_install() {
  info "开始完整安装流程..."

  cmd_check
  cmd_prepare

  # 检查 Kubernetes 清单文件是否存在
  if [[ ! -f "${SCRIPT_DIR}/k8s/costrict.yaml" ]]; then
    die "安装异常，k8s/costrict.yaml 不存在"
  fi
  info "开始安装..."
  apply_k8s_configmaps
  kubectl apply -f "${SCRIPT_DIR}/k8s/costrict.yaml"
  if [[ $? -ne 0 ]]; then
    die "安装异常"
  fi
  info "等待 Kubernetes 工作负载启动..."
  wait_k8s_rollout || die "Kubernetes 工作负载启动异常"
  sync_portal_assets
  info "服务启动结束，准备配置路由"
  if ! bash "${SCRIPT_DIR}/apisix_router_setting.sh"; then
    die "APISIX 路由配置失败。请检查 APISIX Pod 日志和 /tmp/costrict-apisix-port-forward.log。"
  fi
  success "安装完成！"
  cmd_user_reminder
}

# -----------------------------------------------------------------------------
# down — 删除 Kubernetes 资源
# -----------------------------------------------------------------------------
cmd_down() {
  load_config
  info "正在删除 Kubernetes 资源..."

  local manifest="${SCRIPT_DIR}/k8s/costrict.yaml"
  if [[ ! -f "${manifest}" ]]; then
    die "k8s/costrict.yaml 不存在，请先执行 prepare"
  fi

  if kubectl delete -f "${manifest}" --ignore-not-found "$@"; then
    success "Kubernetes 资源已删除。PVC 是否保留取决于集群 StorageClass 的回收策略。"
  else
    die "删除服务失败，请检查 Kubernetes 配置。"
  fi
}

# -----------------------------------------------------------------------------
# up — 启动所有服务
# -----------------------------------------------------------------------------
cmd_up() {
  load_config
  info "正在启动所有服务..."

  local manifest="${SCRIPT_DIR}/k8s/costrict.yaml"
  if [[ ! -f "${manifest}" ]]; then
    die "k8s/costrict.yaml 不存在，请先执行 prepare"
  fi

  apply_k8s_configmaps
  if kubectl apply -f "${manifest}" "$@"; then
    wait_k8s_rollout || die "Kubernetes 工作负载启动异常"
    sync_portal_assets
    success "所有服务已启动。"
    info "可通过 'kubectl -n ${K8S_NAMESPACE} get pods' 查看 Pod 状态。"
  else
    die "启动服务失败，请检查 Kubernetes 配置或日志。"
  fi
}

# -----------------------------------------------------------------------------
# usage — 打印帮助信息
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
用法: $(basename "$0") <command> [options]

命令:
  check    检查运行环境（kubectl、Kubernetes 集群、必要文件等）
  prepare  准备部署环境（解析模板、生成配置文件,创建文件夹等）或者 升级固定的配置文件
  install  完整安装（执行 check + prepare + kubectl apply）
  down     删除 Kubernetes 资源（支持透传 kubectl delete 参数）
  up       启动所有服务（支持透传 kubectl apply 参数）
  info     打印访问地址等提示信息

示例:
  $(basename "$0") check
  $(basename "$0") prepare
  $(basename "$0") install
  $(basename "$0") down
  $(basename "$0") up
  $(basename "$0") info

EOF
}

# -----------------------------------------------------------------------------
# 初始化部署目录变量
# 优先使用环境变量 COSTRICT_DPLOY_DIR；若未设置则默认为本脚本所在目录
# -----------------------------------------------------------------------------
COSTRICT_DPLOY_DIR="${COSTRICT_DPLOY_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# -----------------------------------------------------------------------------
# main — 入口函数
# -----------------------------------------------------------------------------
main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  local command="$1"
  shift  # 移除第一个参数，剩余参数透传给子命令

  case "${command}" in
    check)
      cmd_check "$@"
      ;;
    prepare)
      cmd_prepare "$@"
      ;;
    install)
      cmd_install "$@"
      ;;
    down)
      cmd_down "$@"
      ;;
    up)
      cmd_up "$@"
      ;;
    info)
      if [[ -f "${SCRIPT_DIR}/configure.sh" ]]; then
        source "${SCRIPT_DIR}/configure.sh"
      fi
      cmd_user_reminder
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      error "未知命令：'${command}'"
      usage
      exit 1
      ;;
  esac
}

main "$@"
