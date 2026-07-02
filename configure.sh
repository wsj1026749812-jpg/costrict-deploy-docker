#!/bin/sh
#---------------------------------------------------------
# CoStrict服务端设置，http://${COSTRICT_BACKEND}:${PORT_APISIX_ENTRY} 将成为为你的BaseUrl
#---------------------------------------------------------
COSTRICT_BACKEND=""
PORT_APISIX_ENTRY="39080"
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
# VSCODE扩展连接诸葛神码后端时使用的入口URL地址
# 一般会利用DNS及应用发布设备将该地址映射到 Ingress 暴露的 APISIX 入口
# 诸葛神码后端的IP地址，`deploy.sh --auto-ip`可自动获取
COSTRICT_BACKEND_BASEURL="http://${COSTRICT_BACKEND}:${PORT_APISIX_ENTRY}"

#---------------------------------------------------------
# Kubernetes 设置
#---------------------------------------------------------
# 所有资源部署到该命名空间
K8S_NAMESPACE="costrict"
# Ingress 控制器类名，请按集群实际情况修改，常见值：nginx、traefik
K8S_INGRESS_CLASS_NAME="nginx"
# 通过 Ingress 暴露的域名。请提前配置 DNS 或 /etc/hosts 指向 Ingress 入口 IP。
K8S_APISIX_HOST="costrict.local"
K8S_NACOS_HOST="nacos.costrict.local"
K8S_GRAFANA_HOST="grafana.costrict.local"
K8S_PROMETHEUS_HOST="prometheus.costrict.local"
# K8s Ingress 模式下客户端访问后端的 Base URL
COSTRICT_BACKEND_BASEURL="http://${K8S_APISIX_HOST}"
# PVC 容量。默认使用集群默认 StorageClass；如果集群没有默认 StorageClass，需要先创建或手工修改 PVC。
K8S_PVC_ETCD_SIZE="10Gi"
K8S_PVC_REDIS_SIZE="5Gi"
K8S_PVC_POSTGRES_SIZE="50Gi"
K8S_PVC_PORTAL_SIZE="5Gi"
K8S_PVC_CHATRAG_LOGS_SIZE="10Gi"
K8S_PVC_OIDC_AUTH_LOGS_SIZE="5Gi"
