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
[ -d /opt/k8s/addons/dashboard/manual ] && rm -rf /opt/k8s/addons/dashboard/manual
mkdir -p /opt/k8s/addons/dashboard/manual
cd /opt/k8s/addons/dashboard/manual || exit
dashboard_version=2.0.0-beta2
info "dashboard-$dashboard_version install ...."
# Before installing the new beta, remove the previous version by deleting its namespace
kubectl delete ns kubernetes-dashboard
src_url="https://raw.githubusercontent.com/kubernetes/dashboard/v$dashboard_version/aio/deploy/recommended.yaml"
wget $src_url -O kubernetes-dashboard.yaml
cp kubernetes-dashboard.yaml{,.orig}
# echo '  type: NodePort' >> kubernetes-dashboard.yaml
sed -i "s@replicas: 1@replicas: 2@1" kubernetes-dashboard.yaml
kubectl create -f kubernetes-dashboard.yaml

info "create user (name:admin) ...."
cat > dashboard-admin-user.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kubernetes-dashboard
EOF
kubectl create -f dashboard-admin-user.yaml
