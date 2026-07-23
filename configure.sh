#!/bin/sh
#---------------------------------------------------------
# CoStrict服务端设置，COSTRICT_BACKEND_BASEURL 将成为你的 BaseUrl
#---------------------------------------------------------
# 对外访问域名。正式环境建议使用内网 DNS 域名，端口在下方 K8S_NODEPORT_* 中配置。
COSTRICT_BACKEND="dicode.byd.com"
# 对外访问协议。如果域名端口前面没有 HTTPS 终止代理，这里应改为 http。
COSTRICT_BACKEND_SCHEME="https"
# APISIX 在 Kubernetes 中暴露的 NodePort。
PORT_APISIX_ENTRY="30091"
# nacos管理端口,如果对此不了解，就不需要修改.
PORT_NACOS="31808"

#---------------------------------------------------------
# 大模型相关设置，请根据实际部署情况设置
#---------------------------------------------------------
# 模型服务器的IP，需要根据实际情况设置
MODEL_SERVER_IP="10.72.12.32"
# 对话模型的BASEURL,DEFAULT_MODEL,MODEL_CONTEXTSIZE,APIKEY，初始化后更新配置需在higress中修改

# 已废弃，到higress中配置
# CHAT_MODEL_HOST="${MODEL_SERVER_IP}:2334"
# CHAT_BASEURL="http://${CHAT_MODEL_HOST}"
# CHAT_DEFAULT_MODEL="GLM-4.5-FP8"
# CHAT_MODEL_DESC="GLM-4.5-FP8量化版——又快又好用的顶尖大模型"
# CHAT_MODEL_CONTEXTSIZE=128000
# CHAT_APIKEY=""

# CodeReview模型，已废弃，将直接采用Chat模型
# REVIEW_MODEL_BASEURL="http://${MODEL_SERVER_IP}:2333/v1"
# REVIEW_MODEL_MODEL="Review-Model"
# REVIEW_MODEL_APIKEY=""
# 允许之后配置,并通过命令行更新配置.
# 代码补全模型的BASEURL,MODEL,APIKEY,次密钥为阿里百炼无效密钥,请替换。
COMPLETION_BASEURL="https://dashscope.aliyuncs.com/compatible-mode/v1/completions"
COMPLETION_MODEL="deepseek-r1-distill-qwen-7b"
COMPLETION_APIKEY="sk-30767fb1a58b4091a8a864e515dbea2c"

# 向量嵌入模型的BASEURL,MODEL和APIKEY
EMBEDDER_BASEURL="http://${MODEL_SERVER_IP}:2336/v1/embeddings"
EMBEDDER_MODEL="embedding"
EMBEDDER_APIKEY=""

# RAG排序模型的BASEURL,MODEL和APIKEY
RERANKER_BASEURL="http://${MODEL_SERVER_IP}:2335/v1/rerank"
RERANKER_MODEL="rerank"
RERANKER_APIKEY=""


#-------------------------------------------------------------------------------
# 以下端口设置如非必要，请勿修改
#-------------------------------------------------------------------------------
PORT_CASDOOR="39009"
PORT_HIGRESS_CONTROL="38001"
PORT_APISIX_API="39180"
PORT_GRAFANA="33000"
PORT_REDIS="36379"
PORT_PROMETHEUS="39090"
PORT_ES="39200"

#---------------------------------------------------------
# 对外域名端口。可由内网域名服务/代理映射到下方 K8S_NODEPORT_*。
# 例如外部 dicode.byd.com:39009 可以映射到任一节点的 30009。
#---------------------------------------------------------
# APISIX 对客户端暴露的外部端口，可由内网域名服务/代理映射到 K8s NodePort。
EXTERNAL_PORT_APISIX="30092"
EXTERNAL_PORT_CASDOOR="${PORT_CASDOOR}"
EXTERNAL_PORT_NACOS="${PORT_NACOS}"
EXTERNAL_PORT_GRAFANA="${PORT_GRAFANA}"
EXTERNAL_PORT_PROMETHEUS="${PORT_PROMETHEUS}"
EXTERNAL_PORT_OIDC_AUTH="30093"
EXTERNAL_PORT_CHATRAG="30094"

#---------------------------------------------------------
# 私有镜像仓库设置
# 用户可以私有化部署镜像仓库，用于存放诸葛神码所使用的所有镜像
# 这些镜像默认存储在docker.io/zgsm下
#---------------------------------------------------------
# 私有镜像仓库的主机名
DH_HOST="docker.io"
# 私有镜像仓库中存储诸葛神码镜像的项目地址
DH_ADDR="docker.io/zgsm"

#---------------------------------------------------------
# 登录神码内部应用所使用的账号密码
# 建议修改，以提高系统安全性
#---------------------------------------------------------
# apisix中admin用户的APIKEY
APIKEY_APISIX_ADMIN="edd1c9f034335f136f87ad84b625c8f1"
# apisix中viewer用户的APIKEY
APIKEY_APISIX_VIEWER="4054f730f8e344346cd3f287985e76a2"
# apisix-dashboard的登录密码
PASSWORD_APISIX_DASHBOARD="sf2025~SHENMA"
# etcd的访问密码
PASSWORD_ETCD="sf2025~SHENMA"
# redis的访问密码
PASSWORD_REDIS="sf2025~SHENMA"
# postgres的访问密码
PASSWORD_POSTGRES="sf2025~SHENMA"
# elasticsearch的访问密码
PASSWORD_ELASTIC="4c6y4g6Z09T2w33pYRNKE3LG"
# 
KEY_QUOTA_MANAGER=""

#---------------------------------------------------------
# apisix设置，无需修改
#---------------------------------------------------------

APISIX_ADDR="127.0.0.1:${PORT_APISIX_API}"
AUTH="X-API-KEY: ${APIKEY_APISIX_ADMIN}"
TYPE="Content-Type: application/json"

#---------------------------------------------------------
# postgres/redis设置，无需修改
#---------------------------------------------------------
POSTGRES_USER="zgsm"
POSTGRES_DB="zgsm"

PGSQL_ADDR="postgres:5432"
REDIS_ADDR="redis:6379"

#---------------------------------------------------------
# 认证设置(oidc-auth/casdoor)，无需修改
#---------------------------------------------------------
# oidc-auth模块在casdoor中注册用的clientid
OIDC_AUTH_CLIENT_ID="9e2fc5d4fbcd52ef4f6f"
# oidc-auth模块在casdoor中注册用的client secret
OIDC_AUTH_CLIENT_SECRET="ab5d8ba28b0e6c0d6e971247cdc1deb269c9eea3"

# apisix使用OIDC协议与casdoor通讯验证请求者身份
OIDC_CLIENT_ID="9e2fc5d4fbcd52ef4f6f"
OIDC_CLIENT_SECRET="ab5d8ba28b0e6c0d6e971247cdc1deb269c9eea3"
# OIDC_CLIENT_ID="7c51a6b92dfebfa55d96"
# OIDC_CLIENT_SECRET="bcb3dc222a07fad21aabdd5035dadba2f09e05d6"
OIDC_CASDOOR_ADDR="http://casdoor:8000"
OIDC_DISCOVERY_ADDR="${OIDC_CASDOOR_ADDR}/.well-known/openid-configuration"
OIDC_INTROSPECTION_ENDPOINT="${OIDC_CASDOOR_ADDR}/api/login/oauth/introspect"
OIDC_TOKEN_ENDPOINT=""

#-------------------------------------------------------------------------------
#   以下设置请根据部署环境信息进行修改
#-------------------------------------------------------------------------------
# VSCODE扩展连接诸葛神码后端时使用的入口URL地址，指向 APISIX 入口。
COSTRICT_BACKEND_BASEURL="${COSTRICT_BACKEND_SCHEME}://${COSTRICT_BACKEND}:${EXTERNAL_PORT_APISIX}"

#---------------------------------------------------------
# Kubernetes 设置
#---------------------------------------------------------
# 所有资源部署到该命名空间
K8S_NAMESPACE="costrict"
# Ingress 控制器类名，请按集群实际情况修改，常见值：nginx、traefik
K8S_INGRESS_CLASS_NAME="nginx"
# APISIX 对外 Ingress 域名和 TLS Secret。TLS Secret 需提前在 K8S_NAMESPACE 下创建。
K8S_APISIX_HOST="${COSTRICT_BACKEND}"
K8S_APISIX_TLS_SECRET_NAME="dicode-byd-com-tls"
# 调度设置：有状态服务固定到一个静态 PV 所在节点，其余服务调度到 org=dicode 节点池。
K8S_NODE_SELECTOR_KEY="org"
K8S_NODE_SELECTOR_VALUE="dicode"
K8S_STATEFUL_NODE_NAME="gcyai-work7-ip51-t4x2-2288hv5"
# 静态 PV 在有状态节点上的基础目录。hostPath DirectoryOrCreate 会在 Pod 启动挂载时自动创建目录。
K8S_STATIC_PV_BASE_PATH="/export/costrict"
# 直接 NodePort 暴露的访问端口。正式客户端入口统一走 APISIX；OIDC/Auth 和 Chat-RAG NodePort 仅用于调试或兼容。
K8S_NODEPORT_APISIX="${PORT_APISIX_ENTRY}"
K8S_NODEPORT_CASDOOR="30009"
K8S_NODEPORT_NACOS="${PORT_NACOS}"
K8S_NODEPORT_GRAFANA="30000"
K8S_NODEPORT_PROMETHEUS="30092"
K8S_NODEPORT_OIDC_AUTH="30093"
K8S_NODEPORT_CHATRAG="30094"
# 外部访问地址。客户端、Casdoor 登录/回调、OIDC 回调和 Chat-RAG 默认统一走 APISIX 入口。
CASDOOR_EXTERNAL_BASEURL="${COSTRICT_BACKEND_BASEURL}"
OIDC_AUTH_EXTERNAL_BASEURL="${COSTRICT_BACKEND_BASEURL}"
CHATRAG_EXTERNAL_BASEURL="${COSTRICT_BACKEND_BASEURL}"
# PVC StorageClass。当前静态 PV 场景保持空字符串；动态存储可改为 longhorn、nfs-client 等。
K8S_STORAGE_CLASS_NAME=""
# PVC 容量。静态 PV 容量必须大于等于这里的请求容量。
K8S_PVC_ETCD_SIZE="10Gi"
K8S_PVC_REDIS_SIZE="5Gi"
K8S_PVC_POSTGRES_SIZE="50Gi"
K8S_PVC_PORTAL_SIZE="5Gi"
K8S_PVC_CHATRAG_LOGS_SIZE="10Gi"
K8S_PVC_OIDC_AUTH_LOGS_SIZE="5Gi"
K8S_PVC_LOKI_SIZE="100Gi"
LOKI_RETENTION_PERIOD="168h"
