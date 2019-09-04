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
for node_name in "${EDGENODE_NAMES[@]}"
do
    echo ">>> ${node_name}"
    # 打标签指定edgenode 节点
    kubectl label --overwrite nodes ${node_name} edgenode=true
done
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/ingress-nginx/chart ] && rm -rf /opt/k8s/addons/ingress-nginx/chart
mkdir -p /opt/k8s/addons/ingress-nginx/chart
cd /opt/k8s/addons/ingress-nginx/chart|| exit
info " fetch nginx-ingress chart ..... "
# helm repo update
helm fetch --untar harborrepo/nginx-ingress
info "create nginx-ingress-settings.yaml ..... "

cat > nginx-ingress-settings.yaml <<EOF
controller:
 replicaCount: ${edgenode_counts:?}
 metrics:
  enabled: true
 service:
   annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "10254"
   externalIPs:
   - ${egenode_vip:?}
 affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: ${edgenode_label:?}
          operator: In
          values:
          - "true"

defaultBackend:
 affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: ${edgenode_label:?}
          operator: In
          values:
          - "true"

EOF
# 测试配置文件  --dry-run --debug
helm install \
  --name k8s-ingress \
  --namespace ingress-nginx \
  -f nginx-ingress-settings.yaml \
  nginx-ingress
info "install ingress-nginx finish ..... "
