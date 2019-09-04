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

[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/metrics-server/chart ] && rm -rf /opt/k8s/addons/metrics-server/chart
mkdir -p /opt/k8s/addons/metrics-server/chart
cd /opt/k8s/addons/metrics-server/chart || exit
info " fetch metrics-server chart ..... "
helm repo update
helm fetch --untar harborrepo/metrics-server
info "create metrics-server-settings.yaml ..... "
cat > metrics-server-settings.yaml <<EOF
args:
  - --logtostderr
  - --metric-resolution=30s
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
resources:
  limits:
    cpu: 100m
    memory: 300Mi
  requests:
    cpu: 5m
    memory: 50Mi
replicas: 2

EOF

info " install metrics-server ..... "
helm install \
  --name metrics-server \
  --namespace kube-system \
  -f metrics-server-settings.yaml \
  metrics-server
