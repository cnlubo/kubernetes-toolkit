#!/bin/bash
# shellcheck disable=SC2034
# https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner
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
[ -d /opt/k8s/addons/nfs-client-provisioner ] && rm -rf /opt/k8s/addons/nfs-client-provisioner
mkdir -p /opt/k8s/addons/nfs-client-provisioner
cd /opt/k8s/addons/nfs-client-provisioner || exit
info " fetch nfs-client-provisioner chart ..... "
# helm repo update
helm fetch --untar harborrepo/nfs-client-provisioner

info "create nfs-client-provisioner-settings.yaml ..... "
cat > nfs-client-provisioner-settings.yaml <<EOF

nfs:
  server: ${nfs_server_ip:?}
  path: ${nfs_data:?}
storageClass:
  create: true
  name: nfs-client

EOF

info " install nfs-client-provisioner ..... "
helm install \
  --name nfs-client \
  -f nfs-client-provisioner-settings.yaml \
  nfs-client-provisioner
