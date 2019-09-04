#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-11 14:11:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 22:49:23
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

k8s_server_version=1.14.5
cd /u01/src || return
info "kubernetes-server-v$k8s_server_version install ..... "
if [ ! -f kubernetes-server-linux-amd64.tar.gz ]; then
    info "download kubernetes-server-v$k8s_server_version ..... "
    # 需要翻墙
    wget https://dl.k8s.io/v$k8s_server_version/kubernetes-server-linux-amd64.tar.gz
fi
tar -xzf kubernetes-server-linux-amd64.tar.gz
cd kubernetes || return
tar -xzf kubernetes-src.tar.gz
info "deploy kubernetes-server files to all master nodes ..... "
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp server/bin/* "${k8s_user:?}@${node_ip}":/opt/k8s/bin/
    ssh "${k8s_user:?}@${node_ip}" "chmod +x /opt/k8s/bin/*"
done
