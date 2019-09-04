#!/bin/bash
# shellcheck disable=SC2034
# https://github.com/helm/charts/tree/master/stable/kubernetes-dashboard
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
export dashboard_host="dashboard.ak47.com"
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/dashboard/chart ] && rm -rf /opt/k8s/addons/dashboard/chart
mkdir -p /opt/k8s/addons/dashboard/chart
cd /opt/k8s/addons/dashboard/chart || exit
info " fetch dashboard chart ..... "
# helm repo update
helm fetch --untar harborrepo/kubernetes-dashboard
info "create kubernetes-dashboard-settings.yaml ..... "
cat > kubernetes-dashboard-settings.yaml <<EOF
replicaCount: 2
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
    kubernetes.io/tls-acme: 'true'
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  hosts:
    - $dashboard_host
  tls:
    - secretName: k8s-dashboard-secret
      hosts:
        - $dashboard_host
rbac:
  create: true
  clusterAdminRole: true
serviceAccount:
  create: true
  name: admin
EOF

info " install kubernetes-dashboard ..... "
helm install \
  --name k8s-dashboard \
  --namespace kubernetes-dashboard \
  -f kubernetes-dashboard-settings.yaml \
  kubernetes-dashboard

  info "create secret ..... "
  kubectl create secret generic k8s-dashboard-secret \
  --from-file=tls.key=/opt/k8s/certs/ingress-nginx/ingress-nginx-key.pem \
  --from-file=tls.crt=/opt/k8s/certs/ingress-nginx/ingress-nginx.pem -n kubernetes-dashboard --dry-run -o yaml | kubectl apply -f -
