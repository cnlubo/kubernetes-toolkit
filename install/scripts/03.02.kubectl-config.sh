#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-17 20:45:12
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 21:44:20
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

if [ ! -f /opt/k8s/certs/admin/admin.pem ]; then
    error "kubectl certificate not exists !!!"
    kill -9 $$
fi

info "create kubeconfig file ....."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
cd /opt/k8s/certs/admin/ || exit
# 设置集群参数
kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/cert/ca.pem \
    --embed-certs=true \
    --server="${KUBE_APISERVER}" \
    --kubeconfig=kubectl.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=kubectl.kubeconfig
# 设置上下文参数
kubectl config set-context kubernetes \
    --cluster=kubernetes \
    --user=admin \
    --kubeconfig=kubectl.kubeconfig
# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig
if [ -f kubectl.kubeconfig ]; then
    info "deploy kybectl kubeconfig to all nodes ...."
    # shellcheck disable=SC1083
    mclusters bt {k8s} "rm -rf ~/.kube && mkdir -p ~/.kube"
    for node_ip in "${NODE_IPS[@]}"; do
        echo ">>> ${node_ip}"
        scp kubectl.kubeconfig "${k8s_user:?}@${node_ip}":~/.kube/config
    done
    # shellcheck disable=SC1083
    mclusters bt {k8s} "sudo rm -rf /root/.kube && sudo mkdir -p /root/.kube && sudo cp ~/.kube/config /root/.kube/"
else
    error "create kubectl.kubeconfig error !!!!"
fi
