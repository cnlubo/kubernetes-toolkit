#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-11 12:20:13
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 22:20:06
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

info "create flanneld system unit ....."
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/flanneld ] && rm -rf /opt/k8s/services/flanneld
mkdir -p /opt/k8s/services/flanneld
cd /opt/k8s/services/flanneld || return
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh

cat >flanneld.service <<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service
[Service]
Type=notify
ExecStart=/opt/k8s/bin/flanneld \\
  -etcd-cafile=/etc/kubernetes/cert/ca.pem \\
  -etcd-certfile=/etc/flanneld/cert/flanneld.pem \\
  -etcd-keyfile=/etc/flanneld/cert/flanneld-key.pem \\
  -etcd-endpoints=${ETCD_ENDPOINTS} \\
  -etcd-prefix=${FLANNEL_ETCD_PREFIX}
ExecStartPost=/opt/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
# Restart=on-failure
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF

info "deploy flanneld systemd unit to all nodes ..... "
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp flanneld.service "${k8s_user:?}@${node_ip}":/opt/k8s/
done
# shellcheck disable=SC1083
mclusters bt {k8s} "sudo mv /opt/k8s/flanneld.service /etc/systemd/system/flanneld.service"

# info "start every node flanneld services ..... "
#  # shellcheck disable=SC1083
# mclusters bt {k8s} "sudo systemctl daemon-reload && sudo systemctl enable flanneld && sudo systemctl restart flanneld"
