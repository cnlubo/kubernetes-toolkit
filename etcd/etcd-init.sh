#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-10 22:01:03
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-14 22:06:35
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

info "create etcd system unit ....."
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/etcd ] && rm -rf /opt/k8s/services/etcd
mkdir -p /opt/k8s/services/etcd
cd /opt/k8s/services/etcd || return
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh

cat > etcd.service.template <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
User=${k8s_user:?}
Type=notify
WorkingDirectory=${ETCD_DATA_DIR}
ExecStart=/opt/k8s/bin/etcd \\
  --data-dir=${ETCD_DATA_DIR} \\
  --wal-dir=${ETCD_WAL_DIR} \\
  --name=##NODE_NAME## \\
  --cert-file=/etc/etcd/cert/etcd.pem \\
  --key-file=/etc/etcd/cert/etcd-key.pem \\
  --trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-cert-file=/etc/etcd/cert/etcd.pem \\
  --peer-key-file=/etc/etcd/cert/etcd-key.pem \\
  --peer-trusted-ca-file=/etc/kubernetes/cert/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://##NODE_IP##:2380 \\
  --initial-advertise-peer-urls=https://##NODE_IP##:2380 \\
  --listen-client-urls=https://##NODE_IP##:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://##NODE_IP##:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new \\
  --auto-compaction-mode=periodic \\
  --auto-compaction-retention=1 \\
  --max-request-bytes=33554432 \\
  --quota-backend-bytes=6442450944 \\
  --heartbeat-interval=250 \\
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
# gen every node service file
node_counts=${#ETCD_NODE_IPS[@]}
for (( i=0; i < node_counts; i++ ))
  do
    sed -e "s/##NODE_NAME##/${ETCD_NODE_NAMES[i]}/" -e "s/##NODE_IP##/${ETCD_NODE_IPS[i]}/" etcd.service.template > etcd-${ETCD_NODE_IPS[i]}.service
  done
info "deploy system unit to every node ...."
# shellcheck disable=SC1083
mclusters bt {k8s} "sudo mkdir -p ${ETCD_DATA_DIR} ${ETCD_WAL_DIR} && sudo chown -R $k8s_user /data/etcd && sudo chown -R $k8s_user ${ETCD_DATA_DIR} && sudo chown -R $k8s_user ${ETCD_WAL_DIR}"

for node_ip in "${ETCD_NODE_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp etcd-"${node_ip}".service "$k8s_user@${node_ip}":/opt/k8s/etcd.service
 done
 # shellcheck disable=SC1083
 mclusters bt {k8s} "sudo mv /opt/k8s/etcd.service /etc/systemd/system/etcd.service"


info "start every node etcd services ....."
# for node_ip in "${ETCD_NODE_IPS[@]}"
#   do
#     echo ">>> ${node_ip}"
#     ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl enable etcd && sudo systemctl restart etcd &"
#   done
# shellcheck disable=SC1083
mclusters bt {k8s} "sudo systemctl daemon-reload && sudo systemctl enable etcd && sudo systemctl restart etcd"
