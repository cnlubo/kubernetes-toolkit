###
 # @Author: cnak47
 # @Date: 2019-07-30 12:03:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-07 13:26:07
 # @Description: 
###
#!/bin/bash
# shellcheck disable=SC2034
# Color Palette
RESET='\033[0m'
BOLD='\033[1m'
## Foreground
BLACK='\033[38;5;0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
BLUE='\033[38;5;4m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
WHITE='\033[38;5;7m'
## Background
ON_BLACK='\033[48;5;0m'
ON_RED='\033[48;5;1m'
ON_GREEN='\033[48;5;2m'
ON_YELLOW='\033[48;5;3m'
ON_BLUE='\033[48;5;4m'
ON_MAGENTA='\033[48;5;5m'
ON_CYAN='\033[48;5;6m'
ON_WHITE='\033[48;5;7m'

MODULE="$(basename $0)"

stderr_print() {
    printf "%b\\n" "${*}" >&2
}
log() {
stderr_print "[${BLUE}${MODULE} ${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S ")${RESET}] ${*}"
}
info() {

  log "${GREEN}INFO ${RESET} ==> ${*}"
}
warn() {

  log "${YELLOW}WARN ${RESET} ==> ${*}"
}
error() {
  log "${RED}ERROR${RESET} ==> ${*}"
}

source /opt/k8s/bin/environment.sh
[ ! -d /opt/k8s/addons/fluentd/manual ] && mkdir -p /opt/k8s/addons/fluentd/manual
cd /opt/k8s/addons/fluentd/manual || exit
info "fluentd-es-config.yaml ....."
cat > fluentd-es-config.yaml <<EOF
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluentd-es-config
  namespace: logging
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
data:
  system.conf: |-
    <system>
      root_dir /tmp/fluentd-buffers/
    </system>
  #------Kubernetes 容器日志收集配置------
  containers.input.conf: |-
    <source>
      @id fluentd-containers.log
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/es-containers.log.pos
      tag raw.kubernetes.*
      read_from_head true
      <parse>
        @type multi_format
        <pattern>
          format json
          time_key time
          time_format %Y-%m-%dT%H:%M:%S.%NZ
        </pattern>
        <pattern>
          format /^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$/
          time_format %Y-%m-%dT%H:%M:%S.%N%:z
        </pattern>
      </parse>
    </source>
    # Detect exceptions in the log output and forward them as one log entry
    <match raw.kubernetes.**>
      @id raw.kubernetes
      @type detect_exceptions
      remove_tag_prefix raw
      message log
      stream stream
      multiline_flush_interval 5
      max_bytes 500000
      max_lines 1000
    </match>
    # Concatenate multi-line logs
    <filter **>
      @id filter_concat
      @type concat
      key message
      multiline_end_regexp /\n$/
      separator ""
    </filter>

    # Enriches records with Kubernetes metadata
    <filter kubernetes.**>
      @id filter_kubernetes_metadata
      @type kubernetes_metadata
    </filter>

    # Fixes json fields in Elasticsearch
    <filter kubernetes.**>
      @id filter_parser
      @type parser
      key_name log
      reserve_data true
      remove_key_name_field true
      <parse>
        @type multi_format
        <pattern>
          format json
        </pattern>
        <pattern>
          format none
        </pattern>
      </parse>
    </filter>


  system.input.conf: |-
    <source>
      @id journald-docker
      @type systemd
      matches [{ "_SYSTEMD_UNIT": "docker.service" }]
      <storage>
        @type local
        persistent true
        path /var/log/journald-docker.pos
      </storage>
      read_from_head true
      tag docker
    </source>
    <source>
      @id journald-container-runtime
      @type systemd
      matches [{ "_SYSTEMD_UNIT": "{{ fluentd_container_runtime_service }}.service" }]
      <storage>
        @type local
        persistent true
        path /var/log/journald-container-runtime.pos
      </storage>
      read_from_head true
      tag container-runtime
    </source>
    <source>
      @id journald-kubelet
      @type systemd
      matches [{ "_SYSTEMD_UNIT": "kubelet.service" }]
      <storage>
        @type local
        persistent true
        path /var/log/journald-kubelet.pos
      </storage>
      read_from_head true
      tag kubelet
    </source>
    <source>
      @id journald-node-problem-detector
      @type systemd
      matches [{ "_SYSTEMD_UNIT": "node-problem-detector.service" }]
      <storage>
        @type local
        persistent true
        path /var/log/journald-node-problem-detector.pos
      </storage>
      read_from_head true
      tag node-problem-detector
    </source>
    <source>
      @id kernel
      @type systemd
      matches [{ "_TRANSPORT": "kernel" }]
      <storage>
        @type local
        persistent true
        path /var/log/kernel.pos
      </storage>
      <entry>
        fields_strip_underscores true
        fields_lowercase true
      </entry>
      read_from_head true
      tag kernel
    </source>

  output.conf: |-
    <match **>
      @id elasticsearch
      @type elasticsearch
      @log_level info
      type_name _doc
      include_tag_key true
      host elasticsearch-client
      port 9200
      logstash_format true
      time_as_integer true
      logstash_prefix kubernetes
      <buffer>
        @type file
        path /var/log/fluentd-buffers/kubernetes.system.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 5
        flush_interval 10s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 20M
        queue_limit_length 100
        overflow_action block
        # compress gzip               #开启gzip提高日志采集性能
        # reconnect_on_error true
      </buffer>
    </match>
EOF

info "fluentd-rbac.yaml ..... "
cat > fluentd-rbac.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd-es
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups:
  - ""
  resources:
  - "namespaces"
  - "pods"
  verbs:
  - "get"
  - "watch"
  - "list"
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd-es
  labels:
    k8s-app: fluentd-es
    addonmanager.kubernetes.io/mode: Reconcile
subjects:
- kind: ServiceAccount
  name: fluentd-es
  namespace: logging
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: fluentd-es
  apiGroup: ""

EOF

info "fluenntd-priorityclass.yaml ..... "
cat > fluenntd-priorityclass.yaml <<EOF
apiVersion: scheduling.k8s.io/v1beta1
kind: PriorityClass
metadata:
  name: fluentd-priority
value: 1000000
globalDefault: false
description: ""
EOF

info "fluentd-ds.yaml ..... "
cat > fluentd-ds.yaml <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-es
  namespace: logging
  labels:
    k8s-app: fluentd-es
    version: v2.6.0
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-es
      version: v2.6.0
  template:
    metadata:
      labels:
        k8s-app: fluentd-es
        version: v2.6.0
      #此注解确保如果节点被驱逐，fluentd不会被驱逐
      #支持关键的基于pod注释的优先级方案。
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      priorityClassName: fluentd-priority # 给 Fluentd 设置优先级资源
      serviceAccountName: fluentd-es          # 给 Fluentd 分配权限账户
      #设置容忍所有污点，这样可以收集所有节点日志如 Master 节点一般都被设污，不设置无法在其节点启动 fluentd。
      tolerations:
      - operator: "Exists"

      containers:
      - name: fluentd-es
        image: quay.io/fluentd_elasticsearch/fluentd:v2.6.0
        env:
        - name: FLUENTD_ARGS
          value: --no-supervisor -q     #不启用管理，-q 命令用平静时期于减少warn级别日志（-qq：减少error日志）
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: dockercontainers
          mountPath: /data/k8s/docker/data/containers
        - name: kuberneteslog
          mountPath: /data/k8s/k8s/logs
          readOnly: true
        - name: config-volume
          mountPath: /etc/fluent/config.d
      terminationGracePeriodSeconds: 30      #Kubernetes 将会给应用发送SIGTERM信号,用来优雅地关闭应用
      volumes:
      - name: kuberneteslog                  #将 Kubernetes 节点服务器日志目录挂入
        hostPath:
          path: /data/k8s/k8s/logs
      - name: varlog
        hostPath:
          path: /var/log
      - name: dockercontainers         #挂入 Docker 容器日志目录
        hostPath:
          path: /data/k8s/docker/data/containers
      - name: config-volume                  #挂入 Fluentd 的配置参数
        configMap:
          name: fluentd-es-config
EOF
kubectl apply -f fluentd-es-config.yaml
kubectl apply -f fluentd-rbac.yaml
kubectl apply -f fluenntd-priorityclass.yaml
kubectl apply -f fluentd-ds.yaml
