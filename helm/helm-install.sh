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
runAsRoot() {
  local CMD="$*"

  if [ $EUID -ne 0 ]; then
    CMD="sudo $CMD"
  fi

  $CMD
}

helm_version=2.14.3
source /opt/k8s/bin/environment.sh
cd /u01/src || exit
if [ ! -f helm-v$helm_version-linux-amd64.tar.gz ]; then
    info "helm-v${helm_version:?} Download ..... "
    src_url="https://get.helm.sh/helm-v$helm_version-linux-amd64.tar.gz"
    wget $src_url
fi
info "verifies the SHA256 for the helm file "
# [ -f /u01/src/helm-v${helm_version:?}-linux-amd64.tar.gz.sha256 ] && rm -rf /u01/src/helm-v${helm_version:?}-linux-amd64.tar.gz.sha256
if [ ! -f helm-v${helm_version:?}-linux-amd64.tar.gz.sha256 ]; then
src_url="https://get.helm.sh/helm-v${helm_version:?}-linux-amd64.tar.gz.sha256"
wget $src_url
fi
helm_download_sha256=$(cat /u01/src/helm-v${helm_version:?}-linux-amd64.tar.gz.sha256)
echo "$helm_download_sha256 helm-v${helm_version:?}-linux-amd64.tar.gz" | sha256sum -c --strict -
rm -rf helm-v${helm_version:?}-linux-amd64.tar.gz.sha256
info "helm-v${helm_version:?} install ..... "
[ -d /u01/src/helm ] && rm -rf /u01/src/helm
mkdir -p /u01/src/helm
tar xf helm-v${helm_version:?}-linux-amd64.tar.gz --strip=1 -C /u01/src/helm

for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "sudo rm -rf /usr/local/bin/helm"
    scp /u01/src/helm/helm ${k8s_user:?}@${node_ip}:/opt/k8s/
    ssh ${k8s_user:?}@${node_ip} "sudo cp /opt/k8s/helm /usr/local/bin/helm"
    ssh ${k8s_user:?}@${node_ip} "rm -rf /opt/k8s/helm"
done
