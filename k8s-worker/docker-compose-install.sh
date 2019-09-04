#!/bin/bash
# shellcheck disable=SC2034
###
# @Author: cnak47
# @Date: 2019-07-17 12:37:42
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 10:49:06
# @Description:
###

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

compose_version=1.24.1
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
cd /u01/src || return
info "docker-compose-v$compose_version install ..... "
[ -f docker-compose-Linux-x86_64 ] && rm -rf docker-compose-Linux-x86_64
wget -c https://github.com/docker/compose/releases/download/1.24.1/docker-compose-Linux-x86_64

for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp docker-compose-Linux-x86_64 "${k8s_user:?}"@"${node_ip}":/opt/k8s/docker-compose
    ssh "${k8s_user:?}"@"${node_ip}" "sudo mv /opt/k8s/docker-compose /usr/local/bin/docker-compose"
    ssh "${k8s_user:?}"@"${node_ip}" "sudo chmod +x /usr/local/bin/docker-compose"
    ssh "${k8s_user:?}"@"${node_ip}" "docker-compose --version"
done
