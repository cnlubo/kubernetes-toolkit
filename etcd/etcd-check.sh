#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-10 22:01:03
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 22:03:07
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

info "check etcd cluster status ....."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
info "check etcd services status ....."

# shellcheck disable=SC1083
mclusters bt {k8s} "sudo systemctl status etcd | grep Active"

# 验证Etcd集群可用性
info "check etcd cluster health status ....."
ETCDCTL_API=3 etcdctl \
    --endpoints="$ETCD_ENDPOINTS" \
    --cacert=/etc/kubernetes/cert/ca.pem \
    --cert=/etc/etcd/cert/etcd.pem \
    --key=/etc/etcd/cert/etcd-key.pem \
    endpoint health

info "query etcd cluster members list ....."
ETCDCTL_API=3 etcdctl \
    --endpoints="$ETCD_ENDPOINTS" \
    --cacert=/etc/kubernetes/cert/ca.pem \
    --cert=/etc/etcd/cert/etcd.pem \
    --key=/etc/etcd/cert/etcd-key.pem \
    member list
info "query etcd cluster leader ....."
ETCDCTL_API=3 /opt/k8s/bin/etcdctl \
    -w table --cacert=/etc/kubernetes/cert/ca.pem \
    --cert=/etc/etcd/cert/etcd.pem \
    --key=/etc/etcd/cert/etcd-key.pem \
    --endpoints="${ETCD_ENDPOINTS}" endpoint status
