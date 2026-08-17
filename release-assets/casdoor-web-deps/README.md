Casdoor web offline dependency package
======================================

Files:

- `casdoor-web-node_modules-20260817.tar.gz`: preferred offline package. It contains `node_modules`, `package.json`, and `yarn.lock`.
- `casdoor-web-yarn-cache-v6-20260817.tar.gz`: Yarn v1 cache backup package.

Recommended offline build flow
------------------------------

1. Copy `casdoor-web-node_modules-20260817.tar.gz` to the internal machine.
2. Extract it in the Casdoor `web` directory:

```bash
cd /path/to/casdoor/web
tar -xzf /path/to/casdoor-web-node_modules-20260817.tar.gz
```

3. Build frontend assets:

```bash
NODE_OPTIONS="--max-old-space-size=4096" yarn run build
```

4. Repackage based on the existing Casdoor runtime image from the Casdoor source root:

```dockerfile
# Dockerfile.web-replace
FROM registry.byd.com/public/dicode/zgsm/casdoor:OLD_TAG

USER root
RUN rm -rf /web/build
COPY --chown=1000:1000 web/build /web/build
USER 1000
```

```bash
cd /path/to/casdoor
docker build -f Dockerfile.web-replace \
  -t registry.byd.com/public/dicode/zgsm/casdoor:NEW_TAG \
  .
```

If Casdoor backend code also changed, add the rebuilt server binary too:

```dockerfile
FROM registry.byd.com/public/dicode/zgsm/casdoor:OLD_TAG

USER root
RUN rm -rf /web/build
COPY --chown=1000:1000 server_linux_amd64 /server
COPY --chown=1000:1000 web/build /web/build
RUN chmod +x /server
USER 1000
```

Optional Yarn cache flow
------------------------

Use this only if you want Yarn to run an offline install instead of directly using `node_modules`.

```bash
mkdir -p ~/.cache/yarn
tar -C ~/.cache/yarn -xzf /path/to/casdoor-web-yarn-cache-v6-20260817.tar.gz

cd /path/to/casdoor/web
yarn install --offline --frozen-lockfile --network-timeout 1000000
NODE_OPTIONS="--max-old-space-size=4096" yarn run build
```
