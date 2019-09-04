#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-10 12:00:10
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 17:55:40
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
# query latest version
# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.14.md
kubectl_version=1.14.5
download_dir=/opt/k8s/download
[ ! -d $download_dir ] && mkdir -p $download_dir
if [ ! -f $download_dir/kubectl ]; then
    # 需要翻墙 可以手工下载放到/opt/k8s/download 目录下
    info "download kubectl-$kubectl_version ...."
    src_url=https://storage.googleapis.com/kubernetes-release/release/v$kubectl_version/bin/linux/amd64/kubectl
    # shellcheck disable=2164
    cd $download_dir && {
        curl -LO $src_url
        cd -
    }
fi

info "deploy kubectl to all nodes ....."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp $download_dir/kubectl "${k8s_user:?}@${node_ip}":/opt/k8s/
done
# shellcheck disable=SC1083
mclusters bt {k8s} "sudo mv /opt/k8s/kubectl /usr/local/bin/ && sudo chmod +x /usr/local/bin/kubectl"
