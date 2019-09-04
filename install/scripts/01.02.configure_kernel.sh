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
# runs the given command as root (detects if we are root already)
runAsRoot() {
  local CMD="$*"

  if [ $EUID -ne 0 ]; then
    CMD="sudo $CMD"
  fi

  $CMD
}

info "enable User namespaces"
/usr/sbin/grubby --args="user_namespace.enable=1" --update-kernel="$(/usr/sbin/grubby --default-kernel)"
info "load kernel modules"
modprobe br_netfilter
modprobe ip_vs
info " config kernel arguments ....."

[ ! -d /opt/k8s ] && mkdir -p /opt/k8s
[ ! -d /opt/k8s/config/kernel ] && mkdir -p /opt/k8s/config/kernel
cd /opt/k8s/config/kernel || exit
cat > k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
# https://github.com/moby/moby/issues/31208
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
EOF
cp /opt/k8s/config/kernel/k8s.conf /etc/sysctl.d/
sysctl -p /etc/sysctl.d/k8s.conf
