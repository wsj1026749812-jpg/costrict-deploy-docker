apiVersion: v1
kind: PersistentVolume
metadata:
  name: costrict-loki-data-pv
spec:
  capacity:
    storage: {{K8S_PVC_LOKI_SIZE}}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  hostPath:
    path: {{K8S_STATIC_PV_BASE_PATH}}/loki
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
kind: PersistentVolumeClaim
metadata:
  name: loki-data
  namespace: {{K8S_NAMESPACE}}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: "{{K8S_STORAGE_CLASS_NAME}}"
  resources:
    requests:
      storage: {{K8S_PVC_LOKI_SIZE}}
  volumeName: costrict-loki-data-pv
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: costrict-loki-config
  namespace: {{K8S_NAMESPACE}}
data:
  loki.yaml: |
    auth_enabled: false

    server:
      http_listen_port: 3100
      grpc_listen_port: 9095

    common:
      path_prefix: /loki
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    schema_config:
      configs:
        - from: 2024-01-01
          store: boltdb-shipper
          object_store: filesystem
          schema: v12
          index:
            prefix: index_
            period: 24h

    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/boltdb-cache
      filesystem:
        directory: /loki/chunks

    compactor:
      working_directory: /loki/compactor
      shared_store: filesystem
      retention_enabled: true
      compaction_interval: 10m
      retention_delete_delay: 2h
      retention_delete_worker_count: 2

    limits_config:
      retention_period: {{LOKI_RETENTION_PERIOD}}
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      ingestion_rate_mb: 16
      ingestion_burst_size_mb: 32
      max_query_length: 168h

    ruler:
      storage:
        type: local
        local:
          directory: /loki/rules
      rule_path: /loki/rules-temp
      ring:
        kvstore:
          store: inmemory
      enable_api: true
---
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    app: loki
  ports:
    - name: http
      port: 3100
      targetPort: 3100
    - name: grpc
      port: 9095
      targetPort: 9095
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
  namespace: {{K8S_NAMESPACE}}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
        kubernetes.io/hostname: "{{K8S_STATEFUL_NODE_NAME}}"
      containers:
        - name: loki
          image: {{IMAGE_LOKI}}
          imagePullPolicy: IfNotPresent
          args:
            - -config.file=/etc/loki/loki.yaml
          ports:
            - name: http
              containerPort: 3100
            - name: grpc
              containerPort: 9095
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: "2"
              memory: 4Gi
          volumeMounts:
            - name: loki-config
              mountPath: /etc/loki/loki.yaml
              subPath: loki.yaml
              readOnly: true
            - name: loki-data
              mountPath: /loki
      volumes:
        - name: loki-config
          configMap:
            name: costrict-loki-config
        - name: loki-data
          persistentVolumeClaim:
            claimName: loki-data
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: promtail
  namespace: {{K8S_NAMESPACE}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: costrict-promtail
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/proxy
      - services
      - endpoints
      - pods
      - namespaces
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: costrict-promtail
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: costrict-promtail
subjects:
  - kind: ServiceAccount
    name: promtail
    namespace: {{K8S_NAMESPACE}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: costrict-promtail-config
  namespace: {{K8S_NAMESPACE}}
data:
  promtail.yaml: |
    server:
      http_listen_port: 3101
      grpc_listen_port: 0

    positions:
      filename: /run/promtail/positions.yaml

    clients:
      - url: http://loki:3100/loki/api/v1/push

    scrape_configs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        pipeline_stages:
          - cri: {}
        relabel_configs:
          - source_labels:
              - __meta_kubernetes_namespace
            action: keep
            regex: {{K8S_NAMESPACE}}
          - source_labels:
              - __meta_kubernetes_pod_node_name
            target_label: node
          - source_labels:
              - __meta_kubernetes_namespace
            target_label: namespace
          - source_labels:
              - __meta_kubernetes_pod_name
            target_label: pod
          - source_labels:
              - __meta_kubernetes_pod_container_name
            target_label: container
          - source_labels:
              - __meta_kubernetes_pod_label_app
            target_label: app
          - source_labels:
              - __meta_kubernetes_pod_uid
              - __meta_kubernetes_pod_container_name
            separator: /
            target_label: __path__
            replacement: /var/log/pods/*$1/*.log
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail
  namespace: {{K8S_NAMESPACE}}
spec:
  selector:
    matchLabels:
      app: promtail
  template:
    metadata:
      labels:
        app: promtail
    spec:
      serviceAccountName: promtail
      nodeSelector:
        {{K8S_NODE_SELECTOR_KEY}}: "{{K8S_NODE_SELECTOR_VALUE}}"
      tolerations:
        - key: node.kubernetes.io/not-ready
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
        - key: node.kubernetes.io/unreachable
          operator: Exists
          effect: NoExecute
          tolerationSeconds: 300
      containers:
        - name: promtail
          image: {{IMAGE_PROMTAIL}}
          imagePullPolicy: IfNotPresent
          args:
            - -config.file=/etc/promtail/promtail.yaml
          env:
            - name: HOSTNAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          volumeMounts:
            - name: config
              mountPath: /etc/promtail/promtail.yaml
              subPath: promtail.yaml
              readOnly: true
            - name: run
              mountPath: /run/promtail
            - name: pods
              mountPath: /var/log/pods
              readOnly: true
            - name: containers
              mountPath: /var/log/containers
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: costrict-promtail-config
        - name: run
          hostPath:
            path: /run/promtail
            type: DirectoryOrCreate
        - name: pods
          hostPath:
            path: /var/log/pods
            type: Directory
        - name: containers
          hostPath:
            path: /var/log/containers
            type: DirectoryOrCreate
