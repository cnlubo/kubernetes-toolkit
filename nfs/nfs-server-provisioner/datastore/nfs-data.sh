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
[ ! -d /opt/k8s/nfs ] && mkdir -p /opt/k8s/nfs
[ -d /opt/k8s/nfs/nfs-data ] && rm -rf /opt/k8s/nfs/nfs-data
mkdir -p /opt/k8s/nfs/nfs-data
cd /opt/k8s/nfs/nfs-data || exit
info "create nfs-data-pv.yaml ..... "
cat > nfs-data-pv.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-nfs-server-provisioner-0
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /opt/data-nfs-server-provisioner-0
  claimRef:
    namespace: default
    name: data-nfs-server-nfs-server-provisioner-0
EOF
kubectl create -f nfs-data-pv.yaml
cat > nfs-data-pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-nfs-server-nfs-server-provisioner-0
spec:
  storageClassName: ""
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
EOF
kubectl create -f nfs-data-pvc.yaml
