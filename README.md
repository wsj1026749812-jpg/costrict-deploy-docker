# CoStrict Backend Deployment Tool

[中文版本](./README.zh-CN.md)

## Project Overview

CoStrict Backend Deployment Tool is an enterprise-level AI code assistant backend service deployment solution based on Kubernetes. This project provides a complete microservice architecture, including core components such as AI gateway, identity authentication, code analysis, and chat services, supporting both private deployment and cloud service modes.

> To view the deployment architecture, server requirements, environment requirements, model requirements, model download links, etc., please visit [Foreword](./docs/foreword.md)

## Quick Start

Before you start, make sure you have a reachable Kubernetes cluster and a working `kubectl` context.

### 1. Get Deployment Configuration

**Method 1: Via GitHub Release**

Visit the following address:

```http
https://github.com/zgsm-sangfor/costrict-deploy-docker/releases/
```

Download the latest release archive `costrict-backend-deploy-vX.X.X.tar.gz`, e.g. `costrict-backend-deploy-v0.0.2.tar.gz`

Copy the archive to the server, then extract it:

```bash
# costrict-server is the deployment directory, please remember this directory as your deployment directory, it will be used later
# This directory will store most runtime data, please ensure stable and sufficient disk space
mkdir ./costrict-server
# Extract all files into costrict-server; replace costrict-backend-deploy-v0.0.2.tar.gz with the actual version you downloaded
tar -zxf costrict-backend-deploy-v0.0.2.tar.gz -C costrict-server
# Enter the deployment directory
cd ./costrict-server
```

Note, **./costrict-server** is the deployment directory,

### 2. Prepare Backend Service Images

Note: if you are deploying in an offline environment, continue reading this section. If your Kubernetes nodes can access the full internet (including docker.io, quay.io, docker.elastic.co, etc.), you can skip this step — all images will be pulled automatically during deployment.

The images required by the CoStrict backend can be found in the `scripts/newest-images.list` file for a complete list. You can also pull these images manually.

We provide a Baidu Netdisk download link:

**Netdisk address**:

```http
https://pan.baidu.com/s/5H0ppvaTja4g2MKZs0Ki1-g
```

Newest Version is: v0.0.3

For multi-node clusters, push the images to an internal registry first, then update the image references in `scripts/newest-images.list`. For temporary offline validation, you can also copy the tar packages to every Kubernetes node and import them into the node container runtime:
```bash
# /root/images is the directory containing the tar packages; please replace accordingly
# scripts/load-images.sh is the script in the deployment directory, please find it yourself
bash scripts/load-images.sh -l /root/images
```
```


### 3. Environment Configuration

Edit the configuration file (Note: edit, not create new, it's in the deployment directory and already contains some content):

```bash
vim configure.sh
```

**Key Configuration Parameters**:

For a quick start, you only need to configure one parameter — the server's IP address. The CoStrict client will use this IP to access the CoStrict backend services. Be sure to set this parameter before continuing:

```sh
# Note, this configuration is on the first line, just edit it directly
COSTRICT_BACKEND=""
```

To change the Kubernetes namespace, edit:

```sh
K8S_NAMESPACE="costrict"
```

Multi-node deployments use PVCs and Ingress by default. Make sure the cluster has a default StorageClass and a working Ingress controller, then set the host names:

```sh
K8S_INGRESS_CLASS_NAME="nginx"
K8S_INGRESS_HTTP_PORT="30080"
K8S_APISIX_HOST="costrict.example.com"
K8S_CASDOOR_HOST="casdoor.costrict.example.com"
K8S_NACOS_HOST="nacos.costrict.example.com"
K8S_GRAFANA_HOST="grafana.costrict.example.com"
K8S_PROMETHEUS_HOST="prometheus.costrict.example.com"
```

If you use an internal registry, edit `scripts/newest-images.list`, replace the image references with the internal registry addresses, then run `bash costrict.sh prepare` again.


### 4. Service Deployment

A single command is all it takes to bring up all CoStrict services:
```sh
bash costrict.sh install
```

The deployment script generates `k8s/costrict.yaml`, creates ConfigMaps/PVCs/Ingress, and applies the resources with `kubectl apply`. To inspect Pod status:

```sh
kubectl -n costrict get pods
```

Inspect PVCs and Ingress:

```sh
kubectl -n costrict get pvc
kubectl -n costrict get ingress
```

To remove the Kubernetes resources:

```sh
bash costrict.sh down
```

Note: the Kubernetes manifest mirrors the services that were actually started by the original `docker-compose.yml.tpl`. The repository still contains historical `quota-manager` config and an APISIX route script, but the original Docker Compose setup did not start the `quota-manager` backend, and that config still references the removed `higress` gateway, so it is not included in the default manifest.

Warning: `bash costrict.sh down` deletes Kubernetes resources. Whether PVC data is retained depends on the reclaim policy of your StorageClass.

When the process completes, output similar to the following will be displayed — save it somewhere:

```
[INFO]  Admin user access (casdoor): http://192.168.79.130:39009/
[INFO]  Configure Chat model at (nacos): http://192.168.79.130:31808/
[INFO]  Set BaseUrl to: http://192.168.79.130:39080/

```

For Kubernetes Ingress NodePort deployments, the URLs look like:

```
[INFO]  Admin user access (casdoor) http://casdoor.costrict.local:30080/
[INFO]  Configure Chat model at (nacos) http://nacos.costrict.local:30080/
[INFO]  Set BaseUrl to http://costrict.local:30080/
```

## Service Configuration

### Model Configuration

Higress has been removed in the current version. To configure models, please go to nacos, e.g. `http://192.168.79.130:31808/` (**use the actual URL from your output**).

Log in to nacos:
```
Username: nacos
Password: nacos
```

1. Open **Configuration Management → Configuration List → costrict** (below the "Configuration Management" heading).
2. Find the `model-config` entry, click **Edit**, and modify the **Configuration Content** according to the instructions — do not touch anything else.
3. Publish after editing; changes take effect in real time automatically.

The following is the configuration reference/example. Note:

**Please follow YAML or JSON format strictly.**

**Please follow YAML or JSON format strictly.**

**Please follow YAML or JSON format strictly.**

When publishing, nacos performs a format check. If the error `Configuration may have syntax errors, are you sure you want to submit?` appears, do **not** submit.

Before configuration, please confirm the model's support:

- The model supports calls in the OpenAI /v1/chat/completions interface format; it doesn't matter if the path (route) is different.
- The model supports at least 16,000 tokens (minimum test context, only to test whether the model works properly).
- The model supports function call (tool calling), meaning the request body supports the `tools` field and `"tool_choice": "auto"`.

```yaml
# Configuration example and explanation — edit this in nacos, do not copy this config directly.
models:
    # Example 1
    # id: the model name visible in the plugin / model list — freely customizable
  - id: Kimi-K2-Moonshot
    # Model information
    publicInfo:
      # Max output tokens, must be smaller than contextWindow (32K is usually sufficient). Use Arabic numerals.
      maxTokens: 32000
      # Context window size provided by your model provider. If the value is less than 16000, switch to a larger model. Use Arabic numerals.
      # Warning: This number cannot be arbitrarily increased. You must fill in the context length that the model actually supports.
      contextWindow: 200000
    # Model key settings
    privateConfig:
      # The real model name provided by your model provider
      convertedName: KimiK1000000
      # Full endpoint path /v1/chat/completions
      addr: http://127.0.0.1:6666/v1/chat/completions
      # Custom headers — add as many as needed
      extraHeaders:
        # The authentication header is generally placed here. Please ask the model provider what the value should be. Please note that you must fill in the actual authentication header required by the requested model; do not use abbreviations or shorthand.
        Authorization: "sk-xxxxxxxx"
      # Whether to skip SSL verification. Only needed when the service uses HTTPS with a self-signed certificate. Ask your model provider.
      skipSSLVerify: false
    # Example 2 — same as Example 1 but with more supplementary notes.
    # Model 2: add as many models as you need, following YAML format strictly.
  - id: Qwen3.5
    # Detailed model configuration options
    publicInfo:
      object: model
      maxTokens: 32000
      contextWindow: 200000
      # Whether image input is supported
      supportsImages: true
      supportsComputerUse: false
      supportsPromptCache: false
      supportsReasoningBudget: false
      requiredReasoningBudget: false
      # Description
      description: Qwen3.5 to glm
      # Quota — this feature is not currently active.
      creditConsumption: 3
      creditDiscount: 1
    privateConfig:
      convertedName: glm-5-tokens
      addr: http://127.0.0.1:32323/v1/chat/completions
      extraHeaders:
        Authorization: sk-***
      skipSSLVerify: false
```
How to test whether the configuration is successful:

Follow the current documentation to complete the subsequent steps. After installing the CoStrict plugin, try having a conversation with the model.

Refer to the documentation: [How to Test the Model](./docs/model-test/How-to-test-model.md)

### Optional: Identity Authentication System Configuration (Casdoor)

<span style="color: red; font-weight: bold;"> If there are no special requirements (e.g., integrating with third-party authentication systems), please skip this step, skip this step, skip this step.</span>

<span style="color: red; font-weight: bold;">For the first testing trial, also skip this step, skip this step, skip this step.</span>

<span style="color: red; font-weight: bold;">If you are unsure whether you should skip this step, please just skip it.</span>

Access the Casdoor management interface at the following address:

```
# The first URL shown after installation completes
http://{COSTRICT_BACKEND}:{PORT_CASDOOR}
```

Basic user setup reference: [Casdoor Basic Settings](./docs/casdoor/casdoor-init-setting.md)

## Client Integration

### CoStrict Plugin Configuration

1. Install the CoStrict VSCode extension
2. Open the "Provider" page in the extension settings
3. Select the API provider as "CoStrict"(The first login may have already selected the default option.)
4. Configure the backend service address(That is, the third URL output by the installation script.):
   ```
   CoStrict Base URL: http://****:****
   ```
5. Click "Login CoStrict" to complete authentication

**Test login credentials**:
```
Username: costrict
Password: 123
```

Detailed installation guide: [CoStrict Download and Installation Documentation](https://costrict.ai/download) (includes `VSCode` and `JetBrains` IDE)

**Service access address**:
```
# The third URL shown after installation completes
Default backend entry: http://{COSTRICT_BACKEND}:{PORT_APISIX_ENTRY}
```

## Others

[More information](./docs/others.md)

## License

This project is open source under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.

## Support and Contribution

- **Issue Reporting**: [GitHub Issues](https://github.com/zgsm-ai/zgsm-backend-deploy/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/zgsm-ai/zgsm-backend-deploy/discussions)
- **Contribution Guidelines**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**CoStrict** - Let AI power your code development journey
