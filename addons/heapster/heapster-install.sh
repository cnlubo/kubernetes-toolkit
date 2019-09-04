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

# 官方heapster的 github https://github.com/kubernetes/heapster
info "download heapster files ..... "
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ ! -d /opt/k8s/heapster ] && mkdir -p /opt/k8s/addons/heapster
cd /opt/k8s/addons/heapster || exit
#wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/grafana.yaml \
#-O grafana.yaml
#wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml \
#-O influxdb.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml \
-O heapster.yaml
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml \
-O heapster-rbac.yaml
#cp grafana.yaml{,.orig}
#echo '  type: NodePort' >> grafana.yaml
cp heapster.yaml{,.orig}
sed -i "s@kubernetes:https://kubernetes.default@kubernetes:https://kubernetes.default?kubeletHttps=true\&kubeletPort=10250\&insecure=true@" \
heapster.yaml
# 如果单独安装heapster 需要注释此行，否则不需要注释
sed -i "s@- --sink=influxdb:http://monitoring-influxdb.kube-system.svc:8086@# - --sink=influxdb:http://monitoring-influxdb.kube-system.svc:8086@" \
heapster.yaml
cp heapster-rbac.yaml{,.orig}
cat << EOF >>heapster-rbac.yaml
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: heapster-kubelet-api
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kubelet-api-admin
subjects:
- kind: ServiceAccount
  name: heapster
  namespace: kube-system
EOF

info "heapster install ..... "
kubectl apply -f .
