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
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/metrics-server/manual ] && rm -rf /opt/k8s/addons/metrics-server/manual
mkdir -p /opt/k8s/addons/metrics-server/manual
cd /opt/k8s/addons/metrics-server/manual || exit
git clone https://github.com/kubernetes-incubator/metrics-server.git
cd metrics-server/deploy/1.8+/ ||exit
cp metrics-server-deployment.yaml{,.orig}
cat > /tmp/temp_file.yaml <<EOF
        command:
            - /metrics-server
            - --logtostderr
            - --metric-resolution=30s
            - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
EOF
sed -i '/imagePullPolicy: Always/r /tmp/temp_file.yaml' metrics-server-deployment.yaml
rm -rf /tmp/temp_file.yaml
cp resource-reader.yaml{,.orig}
sed -i '/  - pods/a\  - pods/stats' resource-reader.yaml
# 授予kube-system:metrics-server ServiceAccount访问kubelet API的权限
info "create auth-kubelet.yaml ....."
cat > auth-kubelet.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:system:kubelet-api-admin
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kubelet-api-admin
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
EOF
info "metrics-server install ..... "
kubectl create -f ./
