#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-09 12:39:28
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 22:18:47
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

info "deploy to all nodes ....."
# shellcheck disable=SC1091
# shellcheck disable=SC2029
source /opt/k8s/bin/environment.sh
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    ssh "${k8s_user:?}@${node_ip}" "sudo mkdir -p /etc/flanneld/cert && sudo chown -R $k8s_user /etc/flanneld"
    scp /opt/k8s/certs/flanneld/flanneld*.pem "$k8s_user@${node_ip}":/etc/flanneld/cert
done
