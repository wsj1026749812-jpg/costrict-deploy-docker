apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-etcd-data-pv
spec:
  capacity:
    storage: {{K8S_PVC_ETCD_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/etcd
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-redis-data-pv
spec:
  capacity:
    storage: {{K8S_PVC_REDIS_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/redis
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-postgres-data-pv
spec:
  capacity:
    storage: {{K8S_PVC_POSTGRES_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/postgres
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-portal-data-pv
spec:
  capacity:
    storage: {{K8S_PVC_PORTAL_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/portal
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-chat-rag-logs-pv
spec:
  capacity:
    storage: {{K8S_PVC_CHATRAG_LOGS_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/chat-rag-logs
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-oidc-auth-logs-pv
spec:
  capacity:
    storage: {{K8S_PVC_OIDC_AUTH_LOGS_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/oidc-auth-logs
    type: DirectoryOrCreate
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - "{{K8S_STATEFUL_NODE_NAME}}"
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{K8S_NAMESPACE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: etcd-data
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_ETCD_SIZE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-data
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_REDIS_SIZE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_POSTGRES_SIZE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: portal-data
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_PORTAL_SIZE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: chat-rag-logs
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_CHATRAG_LOGS_SIZE}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oidc-auth-logs
  namespace: {{K8S_NAMESPACE}}
spec:
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{K8S_PVC_OIDC_AUTH_LOGS_SIZE}}
---
apiVersion: v1
kind: Service
metadata:
  name: etcd
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: etcd
  ports:
    - name: client
      port: 2379
      targetPort: 2379
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: etcd
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: etcd
  template:
    metadata:
      labels:
        app: etcd
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: etcd
          image: {{IMAGE_ETCD}}
          imagePullPolicy: IfNotPresent
          env:
            - name: ALLOW_NONE_AUTHENTICATION
              value: "yes"
            - name: ETCD_ADVERTISE_CLIENT_URLS
              value: "http://127.0.0.1:2379"
            - name: ETCD_LISTEN_CLIENT_URLS
              value: "http://0.0.0.0:2379"
          ports:
            - name: client
              containerPort: 2379
          volumeMounts:
            - name: etcd-data
              mountPath: /bitnami/etcd
      volumes:
        - name: etcd-data
          persistentVolumeClaim:
            claimName: etcd-data
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: redis
  ports:
    - name: redis
      port: 6379
      targetPort: 6379
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: redis
          image: {{IMAGE_REDIS}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: redis
              containerPort: 6379
          volumeMounts:
            - name: redis-data
              mountPath: /data
      volumes:
        - name: redis-data
          persistentVolumeClaim:
            claimName: redis-data
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
      targetPort: 5432
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: postgres
          image: {{IMAGE_POSTGRES}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
            - name: POSTGRES_DB
              value: "{{POSTGRES_DB}}"
            - name: POSTGRES_USER
              value: "{{POSTGRES_USER}}"
            - name: POSTGRES_PASSWORD
              value: "{{PASSWORD_POSTGRES}}"
          ports:
            - name: postgres
              containerPort: 5432
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
            - name: postgres-initdb
              mountPath: /docker-entrypoint-initdb.d
              readOnly: true
      volumes:
        - name: postgres-data
          persistentVolumeClaim:
            claimName: postgres-data
        - name: postgres-initdb
          configMap:
            name: costrict-postgres-initdb
---
apiVersion: v1
kind: Service
metadata:
  name: nacos
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: nacos
  ports:
    - name: client
      port: 8848
      targetPort: 8848
    - name: console
      port: 8080
      targetPort: 8080
    - name: grpc
      port: 9848
      targetPort: 9848
    - name: grpc-raft
      port: 9849
      targetPort: 9849
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: nacos
  ports:
    - name: console
      port: 8080
      targetPort: 8080
      nodePort: {{K8S_NODEPORT_NACOS}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nacos
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nacos
  template:
    metadata:
      labels:
        app: nacos
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: nacos
          image: {{IMAGE_NACOS}}
          imagePullPolicy: IfNotPresent
          env:
            - name: MODE
              value: "standalone"
            - name: SPRING_DATASOURCE_PLATFORM
              value: "postgresql"
            - name: DB_SERVICE_HOST
              value: "postgres"
            - name: DB_SERVICE_PORT
              value: "5432"
            - name: DB_SERVICE_DB_NAME
              value: "nacos"
            - name: DB_SERVICE_USER
              value: "{{POSTGRES_USER}}"
            - name: DB_SERVICE_PASSWORD
              value: "{{PASSWORD_POSTGRES}}"
            - name: DB_SERVICE_DB_PARAM
              value: "tcpKeepAlive=true&reWriteBatchedInserts=true&ApplicationName=nacos_java"
            - name: JVM_XMS
              value: "512m"
            - name: JVM_XMX
              value: "512m"
            - name: JVM_XMN
              value: "256m"
            - name: NACOS_AUTH_IDENTITY_KEY
              value: "nacos"
            - name: NACOS_AUTH_IDENTITY_VALUE
              value: "nacos"
            - name: NACOS_AUTH_TOKEN
              value: "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
          ports:
            - name: client
              containerPort: 8848
            - name: console
              containerPort: 8080
            - name: grpc
              containerPort: 9848
            - name: grpc-raft
              containerPort: 9849
---
apiVersion: v1
kind: Service
metadata:
  name: apisix
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: apisix
  ports:
    - name: gateway
      port: 9080
      targetPort: 9080
    - name: admin
      port: 9180
      targetPort: 9180
    - name: prometheus
      port: 9091
      targetPort: 9091
---
apiVersion: v1
kind: Service
metadata:
  name: apisix-gateway-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: apisix
  ports:
    - name: gateway
      port: 9080
      targetPort: 9080
      nodePort: {{K8S_NODEPORT_APISIX}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apisix
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: apisix
  template:
    metadata:
      labels:
        app: apisix
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: apisix
          image: {{IMAGE_APISIX}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: gateway
              containerPort: 9080
            - name: admin
              containerPort: 9180
            - name: prometheus
              containerPort: 9091
          volumeMounts:
            - name: apisix-config
              mountPath: /usr/local/apisix/conf/config.yaml
              subPath: config.yaml
              readOnly: true
      volumes:
        - name: apisix-config
          configMap:
            name: costrict-apisix-config
---
apiVersion: v1
kind: Service
metadata:
  name: model-proxy
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: model-proxy
  ports:
    - name: http
      port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: model-proxy
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: model-proxy
  template:
    metadata:
      labels:
        app: model-proxy
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: model-proxy
          image: {{IMAGE_MODEL_PROXY}}
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
          volumeMounts:
            - name: model-proxy-config
              mountPath: /app/config.yaml
              subPath: config.yaml
      volumes:
        - name: model-proxy-config
          configMap:
            name: costrict-model-proxy-config
---
apiVersion: v1
kind: Service
metadata:
  name: portal
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: portal
  ports:
    - name: http
      port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: portal
  template:
    metadata:
      labels:
        app: portal
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: portal
          image: {{IMAGE_NGINX}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: http
              containerPort: 80
          volumeMounts:
            - name: portal-data
              mountPath: /var/www
            - name: portal-nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
      volumes:
        - name: portal-data
          persistentVolumeClaim:
            claimName: portal-data
        - name: portal-nginx-config
          configMap:
            name: costrict-portal-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: chat-rag
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: chat-rag
  ports:
    - name: http
      port: 8888
      targetPort: 8888
---
apiVersion: v1
kind: Service
metadata:
  name: chat-rag-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: chat-rag
  ports:
    - name: http
      port: 8888
      targetPort: 8888
      nodePort: {{K8S_NODEPORT_CHATRAG}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-rag
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: chat-rag
  template:
    metadata:
      labels:
        app: chat-rag
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: chat-rag
          image: {{IMAGE_CHATRAG}}
          imagePullPolicy: Always
          command: ["/app/chat-rag", "-f", "/app/etc/chat-api.yaml"]
          ports:
            - name: http
              containerPort: 8888
          volumeMounts:
            - name: chat-rag-logs
              mountPath: /data/logs
            - name: chat-rag-config
              mountPath: /app/etc/chat-api.yaml
              subPath: chat-api.yaml
              readOnly: true
            - name: chat-rag-rules
              mountPath: /app/etc/rules.yaml
              subPath: rules.yaml
              readOnly: true
      volumes:
        - name: chat-rag-logs
          persistentVolumeClaim:
            claimName: chat-rag-logs
        - name: chat-rag-config
          configMap:
            name: costrict-chat-rag-config
        - name: chat-rag-rules
          configMap:
            name: costrict-chat-rag-config
---
apiVersion: v1
kind: Service
metadata:
  name: credit-manager
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: credit-manager
  ports:
    - name: http
      port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: credit-manager
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: credit-manager
  template:
    metadata:
      labels:
        app: credit-manager
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: credit-manager
          image: {{IMAGE_CREDIT_MANAGER}}
          imagePullPolicy: IfNotPresent
          command: ["nginx", "-g", "daemon off;"]
          ports:
            - name: http
              containerPort: 80
          volumeMounts:
            - name: credit-manager-config
              mountPath: /config
      volumes:
        - name: credit-manager-config
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: oidc-auth
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: oidc-auth
  ports:
    - name: http
      port: 8080
      targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: oidc-auth-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: oidc-auth
  ports:
    - name: http
      port: 8080
      targetPort: 8080
      nodePort: {{K8S_NODEPORT_OIDC_AUTH}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oidc-auth
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: oidc-auth
  template:
    metadata:
      labels:
        app: oidc-auth
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: oidc-auth
          image: {{IMAGE_OIDC_AUTH}}
          imagePullPolicy: Always
          env:
            - name: SERVER_BASEURL
              value: "{{OIDC_AUTH_EXTERNAL_BASEURL}}"
            - name: PROVIDERS_CASDOOR_CLIENTID
              value: "{{OIDC_AUTH_CLIENT_ID}}"
            - name: PROVIDERS_CASDOOR_CLIENTSECRET
              value: "{{OIDC_AUTH_CLIENT_SECRET}}"
            - name: PROVIDERS_CASDOOR_BASEURL
              value: "{{CASDOOR_EXTERNAL_BASEURL}}"
            - name: PROVIDERS_CASDOOR_INTERNALURL
              value: "{{OIDC_CASDOOR_ADDR}}"
            - name: SMS_ENABLEDTEST
              value: "true"
            - name: SMS_CLIENTID
              value: ""
            - name: SMS_CLIENTSECRET
              value: ""
            - name: SMS_TOKENURL
              value: ""
            - name: SMS_SENDURL
              value: ""
            - name: SYNCSTAR_ENABLED
              value: "false"
            - name: SYNCSTAR_PERSONALTOKEN
              value: ""
            - name: SYNCSTAR_OWNER
              value: "zgsm-ai"
            - name: SYNCSTAR_REPO
              value: "zgsm"
            - name: DATABASE_HOST
              value: "postgres"
            - name: DATABASE_DBNAME
              value: "auth"
            - name: DATABASE_PASSWORD
              value: "{{PASSWORD_POSTGRES}}"
            - name: DATABASE_PORT
              value: "5432"
            - name: DATABASE_USERNAME
              value: "{{POSTGRES_USER}}"
            - name: ENCRYPT_AESKEY
              value: "pUD8mylndVVK7hTNt56VZMkNrppinbNg"
          ports:
            - name: http
              containerPort: 8080
          volumeMounts:
            - name: oidc-auth-logs
              mountPath: /app/logs
      volumes:
        - name: oidc-auth-logs
          persistentVolumeClaim:
            claimName: oidc-auth-logs
---
apiVersion: v1
kind: Service
metadata:
  name: code-completion
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: code-completion
  ports:
    - name: http
      port: 8080
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-completion
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: code-completion
  template:
    metadata:
      labels:
        app: code-completion
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: code-completion
          image: {{IMAGE_CODE_COMPLETION}}
          imagePullPolicy: Always
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: http
              containerPort: 8080
          volumeMounts:
            - name: code-completion-config
              mountPath: /app/config.yaml
              subPath: config.yaml
              readOnly: true
      volumes:
        - name: code-completion-config
          configMap:
            name: costrict-code-completion-config
---
apiVersion: v1
kind: Service
metadata:
  name: casdoor
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: casdoor
  ports:
    - name: http
      port: 8000
      targetPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: casdoor-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: casdoor
  ports:
    - name: http
      port: 8000
      targetPort: 8000
      nodePort: {{K8S_NODEPORT_CASDOOR}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: casdoor
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: casdoor
  template:
    metadata:
      labels:
        app: casdoor
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: casdoor
          image: {{IMAGE_CASDOOR}}
          imagePullPolicy: Always
          env:
            - name: driverName
              value: "postgres"
            - name: dataSourceName
              value: "host=postgres port=5432 user={{POSTGRES_USER}} password={{PASSWORD_POSTGRES}} dbname=casdoor sslmode=disable"
          ports:
            - name: http
              containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: prometheus
  ports:
    - name: http
      port: 9090
      targetPort: 9090
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: prometheus
  ports:
    - name: http
      port: 9090
      targetPort: 9090
      nodePort: {{K8S_NODEPORT_PROMETHEUS}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: prometheus
          image: {{IMAGE_PROMETHEUS}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: http
              containerPort: 9090
          volumeMounts:
            - name: prometheus-config
              mountPath: /etc/prometheus/prometheus.yml
              subPath: prometheus.yml
      volumes:
        - name: prometheus-config
          configMap:
            name: costrict-prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: grafana
  ports:
    - name: http
      port: 3000
      targetPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-nodeport
  namespace: {{K8S_NAMESPACE}}
spec:
  type: NodePort
  selector:
    app: grafana
  ports:
    - name: http
      port: 3000
      targetPort: 3000
      nodePort: {{K8S_NODEPORT_GRAFANA}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      containers:
        - name: grafana
          image: {{IMAGE_GRAFANA}}
          imagePullPolicy: IfNotPresent
          env:
            - name: TZ
              value: "Asia/Shanghai"
          ports:
            - name: http
              containerPort: 3000
          volumeMounts:
            - name: grafana-provisioning-datasources
              mountPath: /etc/grafana/provisioning/datasources
            - name: grafana-provisioning-dashboards
              mountPath: /etc/grafana/provisioning/dashboards
            - name: grafana-dashboards
              mountPath: /var/lib/grafana/dashboards
            - name: grafana-config
              mountPath: /etc/grafana/grafana.ini
              subPath: grafana.ini
      volumes:
        - name: grafana-provisioning-datasources
          configMap:
            name: costrict-grafana-provisioning-datasources
        - name: grafana-provisioning-dashboards
          configMap:
            name: costrict-grafana-provisioning-dashboards
        - name: grafana-dashboards
          configMap:
            name: costrict-grafana-dashboards
        - name: grafana-config
          configMap:
            name: costrict-grafana-config
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: costrict
  namespace: {{K8S_NAMESPACE}}
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: {{K8S_INGRESS_CLASS_NAME}}
  tls:
    - hosts:
        - {{K8S_APISIX_HOST}}
      secretName: {{K8S_APISIX_TLS_SECRET_NAME}}
  rules:
    - host: {{K8S_APISIX_HOST}}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: apisix
                port:
                  number: 9080
