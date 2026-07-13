# CoStrict 后端部署工具

[English Version](./README.md)

## 项目概述

CoStrict 后端部署工具是基于 Kubernetes 的企业级 AI 代码助手后端服务部署解决方案。该项目提供了完整的微服务架构，包含 AI 网关、身份认证、代码分析、聊天服务等核心组件，支持私有化部署和云端服务两种模式。

> 查看此项目的部署架构，部署的服务器要求、环境要求、模型要求、模型下载地址等，请访问 [前言](./docs/foreword.zh-CN.md)

## 快速开始

> 开始前，请确保你对 Linux 命令行有一定了解，并已经准备好可访问的 Kubernetes 集群和 kubectl。

### 1. 获取部署配置

**方式一：通过 Github Release**

访问一下地址：

```http
https://github.com/zgsm-sangfor/costrict-deploy-docker/releases/
```

下载最新的release压缩包 `costrict-backend-deploy-vX.X.X.tar.gz` ,如: `costrict-backend-deploy-v0.0.2.tar.gz
`

将压缩包复制到服务器，然后解压

```bash
# costrict-server 就是部署目录,请牢记这个目录，请牢记这个目录，请牢记这个目录，这是你的部署目录，后面将会用到
# 这个目录将存储大部分运行数据，请保证磁盘稳定、充足
mkdir ./costrict-server
# 将所有文件解压到 costrict-server,注意，costrict-backend-deploy-v0.0.2.tar.gz 替换为你下载的实际版本的压缩包。
tar -zxf costrict-backend-deploy-v0.0.2.tar.gz -C costrict-server
# 进入到部署目录
cd ./costrict-server
```

注意，**./costrict-server** 就是部署目录，

### 2. 准备后端服务镜像

注意，如果你是离线环境部署，继续查看本节；如果 Kubernetes 节点能正常访问整个互联网(包括 docker.io、quay.io、docker.elastic.co 等)，可以直接跳过这个步骤，部署时会自动拉取所有镜像。

CoStrict后端需要的镜像，可以查看 `scripts/newest-images.list` 文件获取完整列表，你也可以手动拉取这些镜像

我们提供了百度网盘的下载地址：

**网盘地址**：

```http
https://pan.baidu.com/s/5H0ppvaTja4g2MKZs0Ki1-g
```

当前最新版本: v0.0.3

多节点集群推荐先将镜像推送到内网镜像仓库，然后修改 `scripts/newest-images.list` 中的镜像地址。临时离线验证时，也可以将所有 tar 包复制到每个 Kubernetes 节点，并导入到节点使用的容器运行时：

```bash
# /root/images 就是tar包所在目录,请注意替换
# scripts/load-images.sh 是部署目录下的脚本,请自行查找
bash scripts/load-images.sh -l /root/images
```


### 3. 环境配置

编辑配置文件(注意，是编辑，不是新建，就在部署目录下,且已经存在一些内容):

```bash
vim configure.sh
```

**关键配置参数**:

为了快速开始，你只需要配置第一个参数为服务器的ip即可，CoStrict客户端将会通过这个ip访问CoStrict后台服务，请务必配置这个参数后继续

```sh
# 注意，这个配置就在第一行,直接编辑即可.
COSTRICT_BACKEND=""
```

如需调整 Kubernetes 命名空间，可修改：

```sh
K8S_NAMESPACE="costrict"
```

多节点部署默认使用 PVC，并使用“域名 + 外部端口”的方式暴露客户端和 CLI 入口。`EXTERNAL_PORT_*` 是用户访问 `dicode.byd.com` 时看到的端口，`K8S_NODEPORT_*` 是 Kubernetes 实际暴露的 NodePort；如果两者不同，需要在内网域名服务或前置代理中做端口映射。

```sh
COSTRICT_BACKEND="dicode.byd.com"
COSTRICT_BACKEND_SCHEME="https"
EXTERNAL_PORT_APISIX="30091"
EXTERNAL_PORT_CASDOOR="39009"
EXTERNAL_PORT_NACOS="31808"
EXTERNAL_PORT_OIDC_AUTH="30093"
EXTERNAL_PORT_CHATRAG="30094"
COSTRICT_BACKEND_BASEURL="${COSTRICT_BACKEND_SCHEME}://${COSTRICT_BACKEND}:${EXTERNAL_PORT_APISIX}"
K8S_INGRESS_CLASS_NAME="nginx"
K8S_APISIX_HOST="${COSTRICT_BACKEND}"
K8S_APISIX_TLS_SECRET_NAME="dicode-byd-com-tls"
K8S_NODE_SELECTOR_KEY="org"
K8S_NODE_SELECTOR_VALUE="dicode"
K8S_STATEFUL_NODE_NAME="gcyai-work7-ip51-t4x2-2288hv5"
K8S_NODEPORT_APISIX="30091"
K8S_NODEPORT_CASDOOR="30009"
K8S_NODEPORT_NACOS="31808"
K8S_NODEPORT_GRAFANA="30000"
K8S_NODEPORT_PROMETHEUS="30092"
K8S_NODEPORT_OIDC_AUTH="30093"
K8S_NODEPORT_CHATRAG="30094"
```

如果使用内网镜像仓库，请修改 `scripts/newest-images.list`，将镜像地址替换为内网仓库地址，然后重新执行 `bash costrict.sh prepare`。


### 4. 服务部署

只需要一行命令，就可以拉起所有的costrict服务。

```sh
bash costrict.sh install
```

部署脚本会生成 `k8s/costrict.yaml`，创建 ConfigMap/PVC/Deployment/Service/Ingress/NodePort，并通过 `kubectl apply` 创建资源。查看 Pod 状态：

```sh
kubectl -n costrict get pods
```

查看 PVC 和 NodePort：

```sh
kubectl -n costrict get pvc
kubectl -n costrict get svc
```

卸载 Kubernetes 资源：

```sh
bash costrict.sh down
```

说明：当前 Kubernetes 清单复刻原 `docker-compose.yml.tpl` 中实际启动的服务。仓库中保留了 `quota-manager` 的历史配置和 APISIX 路由脚本，但原 Docker Compose 未启动 `quota-manager` 后端服务，且该配置仍引用已移除的 `higress`，因此默认清单未纳入该服务。

注意：执行 `bash costrict.sh down` 会删除 Kubernetes 资源；PVC 数据是否保留取决于集群 StorageClass 的回收策略。

运行结束后，会提示类似的内容,请找个文本文件记录下来：

```
[INFO]  管理用户访问 (casdoor) http://192.168.79.130:39009/
[INFO]  配置Chat模型请访问 (nacos) http://192.168.79.130:31808/
[INFO]  BaseUrl请设置 http://192.168.79.130:39080/

```

Kubernetes 部署时，访问地址类似：

```
[INFO]  BaseUrl请设置为 https://dicode.byd.com:30091/
[INFO]  Casdoor管理入口：https://dicode.byd.com:39009/
[INFO]  OIDC/Auth外部入口：https://dicode.byd.com:30093/
[INFO]  Chat-RAG外部入口：https://dicode.byd.com:30094/
[INFO]  配置Chat模型请访问 (nacos) https://dicode.byd.com:31808/
```

## 服务配置

### 模型配置

当前版本已经移除了higress, 如果需要配置模型，请到nacos中配置,访问nacos,如`http://192.168.79.130:31808/`(**请注意,请你以实际输出为准**)

登录nacos
```
用户名: nacos
密码：nacos
```

1. 打开 配置管理-> 配置列表-> costrict(在`配置管理`这四个大字的下方)。
2. 找到 `model-config` 配置，点击编辑,根据提示编辑`配置内容`,其他不要动。
3. 编辑后发布即可，会自动实时更新。

以下是配置说明/示例，注意：

**请严格按照yaml或者json格式配置**

**请严格按照yaml或者json格式配置**

**请严格按照yaml或者json格式配置**

发布时nacos会有格式检查,如果报错: `配置信息可能有语法错误, 确定提交吗?`请不要提交。

配置前，请确定模型的支持情况：
- 模型支持openai的 /v1/chat/completions接口格式的调用,路径(路由)不一样没关系；
- 模型至少支持16000(最小测试上下文,仅测试模型是否正常)；
- 模型支持function call工具调用,也就是请求体中支持 `tools`字段,和`"tool_choice": "auto"`；

```yaml
# 配置示例和解释，请在nacos中修改，不用复制这个配置。
models:
    # 配置示例 1 
    # id,模型的名称, 你在插件中看到的名字,也就是你在模型列表中看到的名字，随便自定义
  - id: Kimi-K2-Moonshot
    # 模型的信息
    publicInfo:
      # 最大输出, 比contextWindow小 (一般32K够用了),请用阿拉伯数字.
      maxTokens: 32000
      # 上下文窗口,找模型提供者给,如果模型提供者给你的值小于16000,请换更大的模型，请用阿拉伯数字.
      # 警告,这个数字不是想调大就调大的，请必须填写模型真实支持的上下文长度.
      contextWindow: 200000
    # 模型的key相关
    privateConfig:
      # 模型的真实名字,找模型提供者给
      convertedName: KimiK1000000
      # 地址,完整的路径/v1/chat/completions
      addr: http://127.0.0.1:6666/v1/chat/completions
      # 自定义头,可以添加任意多个
      extraHeaders:
        # 认证头一般放这里,请询问模型提供者值是多少,请注意，请填写请求模型的实际认证头，不要简写，略写。
        Authorization: "sk-xxxxxxxx"
      # 是否跳过ssl校验,一般只有服务是https且采用自签名的ssl证书才需要设置，请询问模型提供者。
      skipSSLVerify: false
    # 配置示例 2,和1一样，只是有更多的补充说明。
    # 模型2，需要多少个模型就加多少个,请严格按照yaml格式配置
  - id: Qwen3.5
    # 模型的一些配置项,详细
    publicInfo:
      object: model
      maxTokens: 32000
      contextWindow: 200000
      # 是否支持图片
      supportsImages: true
      supportsComputerUse: false
      supportsPromptCache: false
      supportsReasoningBudget: false
      requiredReasoningBudget: false
      # 描述信息
      description: Qwen3.5 to glm
      # 配额，当前这个功能没有。
      creditConsumption: 3
      creditDiscount: 1
    privateConfig:
      convertedName: glm-5-tokens
      addr: http://127.0.0.1:32323/v1/chat/completions
      extraHeaders:
        Authorization: sk-***
      skipSSLVerify: false
```

如何测试是否配置成功

1. 根据当前文档，继续完成后续步骤，安装CoStrict插件后，尝试和模型对话。
2. 参考文档：[如何测试模型](./docs/model-test/How-to-test-model.zh-CN.md)

### 可选：身份认证系统配置 (Casdoor)

<span style="color: red; font-weight: bold;">如果没有特殊要求(如：对接第三方认证系统)，请直接 跳过此步骤，请跳过此步骤，请跳过此步骤。</span>

<span style="color: red; font-weight: bold;">第一次测试试用，也请直接 跳过此步骤，请跳过此步骤，请跳过此步骤。</span>

<span style="color: red; font-weight: bold;">如果您不知道应不应该跳过此步骤，请直接跳过此步骤</span>

通过以下地址访问 Casdoor 管理界面(请确保您已经清晰的认识到，你是在自定义配置认证系统或者对接第三方认证系统):

```
# 安装结束后提示的第一个url
http://{COSTRICT_BACKEND}:{PORT_CASDOOR}
```

基本用户添加参考: [casdoor基本设置](./docs/casdoor/casdoor-init-setting.zh-CN.md)

## 客户端集成

### CoStrict 插件配置

1. 安装 CoStrict VSCode 扩展
2. 打开扩展设置中的"提供商"页面
3. 选择 API 提供商为"CoStrict"(首次登录可能已经默认选择了)
4. 配置后端服务地址(也就是安装脚本输出的第三个Url):
   ```
   CoStrict Base URL: http://****:****
   ```
5. 点击"登录 CoStrict"完成身份验证

**登录测试账户**:
```
用户名: costrict
密码: 123
```

详细安装指南：[CoStrict 下载安装文档](https://costrict.ai/download) (含 `VSCode` 和 `JetBrains` IDE)

**服务访问地址**:
```
# 安装后提示的第三个url
默认后端入口: http://{COSTRICT_BACKEND}:{PORT_APISIX_ENTRY}
```

## Others

[更多信息](./docs/others.zh-CN.md)

## 许可证

本项目基于 Apache 2.0 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 支持与贡献

- **问题报告**: [GitHub Issues](https://github.com/zgsm-ai/zgsm-backend-deploy/issues)
- **功能请求**: [GitHub Discussions](https://github.com/zgsm-ai/zgsm-backend-deploy/discussions)
- **贡献指南**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**CoStrict** - 让 AI 助力您的代码开发之旅
