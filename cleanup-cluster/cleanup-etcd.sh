#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-08-11 23:03:24
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-11 23:19:11
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
sudo systemctl stop etcd
sudo systemctl disable etcd
info " cleanup files ..... "
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
# 删除 etcd 的工作目录和数据目录
sudo rm -rf "${ETCD_DATA_DIR}" "${ETCD_WAL_DIR}"
# 删除 systemd unit 文件
sudo rm -rf /etc/systemd/system/etcd.service
# 删除程序文件
sudo rm -rf /opt/k8s/bin/etcd
# 删除 x509 证书文件
sudo rm -rf /etc/etcd/cert/*
