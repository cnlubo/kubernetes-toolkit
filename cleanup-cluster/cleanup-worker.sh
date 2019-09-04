#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-08-11 22:01:00
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 13:08:00
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

info " stop related services ..... "
sudo systemctl stop kubelet kube-proxy flanneld docker
sudo systemctl disable kubelet kube-proxy flanneld docker
info " cleanup files ....."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
# umount kubelet 和 docker 挂载的目录
# mount | grep "${K8S_DIR}" | awk '{print $3}' | xargs sudo umount
# 删除 kubelet 工作目录
sudo rm -rf "${K8S_DIR}"/kubelet
# 删除 docker 工作目录
sudo rm -rf "${DOCKER_DIR}"
# 删除 flanneld 写入的网络配置文件
sudo rm -rf /var/run/flannel/
# 删除 docker 的一些运行文件
sudo rm -rf /var/run/docker/
# 删除 systemd unit 文件
sudo rm -rf /etc/systemd/system/{kubelet,docker,flanneld,kube-proxy}.service
# 删除程序文件
# sudo rm -rf /opt/k8s/bin/*
# 删除证书文件
sudo rm -rf /etc/flanneld/cert /etc/kubernetes/cert
info " cleanup iptables .... "
sudo iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
info " cleanup network bridge ..... "
sudo ip link del flannel.1
sudo ip link del docker0
# delete pods log
sudo rm -rf /var/log/pods
sudo rm -rf /var/log/containers
