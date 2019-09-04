#!/bin/bash
# shellcheck disable=SC2034
###
 # @Author: cnak47
 # @Date: 2019-07-27 17:21:42
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-05 23:31:39
 # @Description: 
###
# https://github.com/elastic/helm-charts
# helm repo add elastic https://helm.elastic.co

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
[ -d /opt/k8s/addons/elasticsearch ] && rm -rf /opt/k8s/addons/elasticsearch
mkdir -p /opt/k8s/addons/elasticsearch
cd /opt/k8s/addons/elasticsearch || exit
info " fetch elasticsearch chart ..... "
helm fetch --untar harborrepo/elasticsearch --version=7.2.1-0
info "create elasticsearch-storageclass ..... "
cat > es-storageclass.yaml <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: es-storageclass
#---provisioner 需要和 NFS-Provisioner 服务提供者提供的配置的保持一致---
provisioner: cluster.local/nfs-client-nfs-client-provisioner
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF
kubectl apply -f es-storageclass.yaml

info "create elasticsearch-settings.yaml ..... "
cat > elasticsearch-settings.yaml <<EOF
nodeGroup: "master"
masterService: ""
imageTag: "7.2.1"
volumeClaimTemplate:
  storageClassName: "es-storageclass"
  resources:
    requests:
      storage: 10Gi

EOF
#   --dry-run --debug \
info " install elasticsearch..... "
helm install \
  --name elasticsearch \
  --namespace logging \
  -f elasticsearch-settings.yaml \
  elasticsearch
