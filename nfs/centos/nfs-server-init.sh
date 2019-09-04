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

source /opt/k8s/bin/environment.sh
info "configure NFS server"
echo ">>> ${nfs_server_name:?}"
# 设置 NFS 服务开机启动
ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo yum install nfs-utils -y \
&&sudo systemctl enable rpcbind&&sudo systemctl enable nfs"
# 启动 NFS 服务
ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo systemctl start rpcbind \
&&sudo systemctl start nfs"
# 防火墙需要打开 rpc-bind 和 nfs 的服务
# ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo firewall-cmd --zone=public --permanent \
# --add-service=rpc-bind"
# ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo firewall-cmd --zone=public --permanent \
# --add-service=mountd"
# ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo firewall-cmd --zone=public --permanent --add-service=nfs&&sudo firewall-cmd --reload"
# 在服务端配置一个共享目录
ssh ${k8s_user:?}@${nfs_server_ip:?} "[ -f ${nfs_data:?} ] && sudo rm -rf ${nfs_data:?}"
ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo mkdir -p ${nfs_data:?} && sudo chmod 755 ${nfs_data:?}"
echo "${nfs_data:?}     ${nfs_ips:?}(rw,sync,no_root_squash,no_all_squash)" >exports
ssh ${k8s_user:?}@${nfs_server_ip:?} "[ -f /etc/exports ] &&sudo rm -rf /etc/exports"
scp exports ${k8s_user:?}@${nfs_server_ip:?}:/opt/k8s/
ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo mv /opt/k8s/exports /etc/"
ssh ${k8s_user:?}@${nfs_server_ip:?} "sudo systemctl restart nfs && sudo showmount -e localhost"
rm -rf exports
