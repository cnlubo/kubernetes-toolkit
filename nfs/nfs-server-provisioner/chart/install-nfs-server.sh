#!/bin/bash
# shellcheck disable=SC2034
# https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner
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
[ -d /opt/k8s/addons/nfs-server-provisioner ] && rm -rf /opt/k8s/addons/nfs-server-provisioner
mkdir -p /opt/k8s/addons/nfs-server-provisioner
cd /opt/k8s/addons/nfs-server-provisioner || exit
info " fetch nfs-server-provisioner chart ..... "
# helm repo update
helm fetch --untar harborrepo/nfs-server-provisioner

info "create nfs-server-provisioner-settings.yaml ..... "
cat > nfs-server-provisioner-settings.yaml <<EOF

persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 100Gi

storageClass:
  create: true
  defaultClass: false
  name: nfs
  reclaimPolicy: Delete

EOF

info " install nfs-server-provisioner ..... "
helm install \
  --name nfs-server \
  --namespace default \
  -f nfs-server-provisioner-settings.yaml \
  nfs-server-provisioner
