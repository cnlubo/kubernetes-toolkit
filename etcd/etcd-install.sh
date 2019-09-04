#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-10 22:01:03
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 21:51:55
 # @Description: 
 ###

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

MODULE="$(basename "$0")"

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

etcd_version=3.3.13
cd /u01/src || return
if [ ! -f etcd-v${etcd_version:?}-linux-amd64.tar.gz ]; then
info "download etcd-$etcd_version ....."
wget https://github.com/coreos/etcd/releases/download/v$etcd_version/etcd-v${etcd_version:?}-linux-amd64.tar.gz
fi
[ -d etcd-v${etcd_version:?}-linux-amd64 ] && rm -rf etcd-v${etcd_version:?}-linux-amd64
tar xvf etcd-v${etcd_version:?}-linux-amd64.tar.gz

info "deploy etcd file to all etcd nodes ....."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
for node_ip in "${ETCD_NODE_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp etcd-v$etcd_version-linux-amd64/etcd* "${k8s_user:?}@${node_ip}":/opt/k8s/bin
done
  # shellcheck disable=SC1083
 mclusters bt {k8s} "chmod +x /opt/k8s/bin/*"
