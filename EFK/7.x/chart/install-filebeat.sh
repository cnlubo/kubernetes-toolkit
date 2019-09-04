#!/bin/bash
# shellcheck disable=SC2034
###
# @Author: cnak47
# @Date: 2019-08-06 12:30:15
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-08 23:13:31
# @Description:
###
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
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/filebeat/chart ] && rm -rf /opt/k8s/addons/filebeat/chart
mkdir -p /opt/k8s/addons/filebeat/chart
cd /opt/k8s/addons/filebeat/chart || exit
info " fetch filebeat chart ..... "
helm fetch --untar harborrepo/filebeat --version=7.2.1-0
info "create filebeat-settings.yaml ..... "
cat >filebeat-settings.yaml <<EOF
filebeatConfig:
  filebeat.yml: |
    filebeat.modules:
    - module: system
    - module: coredns
    
    # List of inputs to fetch data.
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
      processors:
      - add_kubernetes_metadata:
          in_cluster: true
          matchers:
          - logs_path:
              logs_path: "/var/log/containers/"
      - drop_fields:
         fields: ["log.offset","input.type"]
    # setup.template.name: "kubernetes"
    # setup.template.pattern: "kubernetes-*"
    # setup.kibana.host: "kibana-kibana:5601"
    # setup.kibana.protocol: "http"
    # setup.dashboards.index: "kubernetes-*"
    # setup.dashboards.enabled: true
    output.elasticsearch:
      hosts: "elasticsearch-master:9200"
      index: "kubernetes-%{[agent.version]}-%{+yyyy.MM.dd}"
    setup.template:
      name: 'kubernetes'
      pattern: 'kubernetes-*'
      enabled: false

extraEnvs:
  - name: ELASTICSEARCH_HOSTS
    value: elasticsearch-master:9200

extraVolumeMounts: |
  - name: varlog
    mountPath: /var/log
    readOnly: true
  - name: dockercontainers
    mountPath: /data/k8s/docker/data/containers
    readOnly: true
  - name: kuberneteslog
    mountPath: /data/k8s/k8s/logs
    readOnly: true
    
extraVolumes: |
  - name: kuberneteslog
    hostPath: 
        path: /data/k8s/k8s/logs
  - name: varlog
    hostPath: 
        path: /var/log
  - name: dockercontainers
    hostPath: 
        path: /data/k8s/docker/data/containers

image: "docker.elastic.co/beats/filebeat"
imageTag: "7.2.1"
# How long to wait for Filebeat pods to stop gracefully
terminationGracePeriod: 30

EOF
# --dry-run --debug \
info " install filebeat ..... "
helm install \
    --name filebeat \
    --namespace logging \
    -f filebeat-settings.yaml \
    filebeat
