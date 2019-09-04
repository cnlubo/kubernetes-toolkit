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
# docker 官方源
# #runAsRoot yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# docker 阿里镜像源
# runAsRoot yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 查找Docker-CE的版本:
# yum list docker-ce.x86_64 --showduplicates | sort -r
info "k8s worker node init ....."
source /opt/k8s/bin/environment.sh
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    info "Install required packages ...."
    ssh ${k8s_user:?}@${node_ip} "sudo yum install -y epel-release"
    ssh $k8s_user@${node_ip} "sudo yum install -y conntrack ipvsadm ipset jq iptables curl sysstat libseccomp && sudo /usr/sbin/modprobe ip_vs "
    ssh $k8s_user@${node_ip} "sudo yum install -y yum-utils device-mapper-persistent-data lvm2 yum-versionlock"
    info "set up the docker-ce repository ...."
    ssh ${k8s_user:?}@${node_ip} "sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
done
