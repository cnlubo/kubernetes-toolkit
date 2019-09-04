#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-11 14:11:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-15 10:22:25
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

info "create keepalived master conf ....."
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/keepalived ] && rm -rf /opt/k8s/services/keepalived
mkdir -p /opt/k8s/services/keepalived
cd /opt/k8s/services/keepalived || return
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
cat >keepalived-master.conf <<EOF
global_defs {
    router_id lb-master-105
}

vrrp_script check-haproxy {
    script "killall -0 haproxy"
    interval 5
    weight -30
}

vrrp_instance VI-kube-master {
    state MASTER
    priority 120
    dont_track_primary
    interface ${MASTER_VIP_IF}
    virtual_router_id 68
    advert_int 3
    track_script {
        check-haproxy
    }
    virtual_ipaddress {
        ${MASTER_VIP}
    }
}
EOF

info "create keepalived backup conf ....."

cat >keepalived-backup.conf <<EOF
global_defs {
    router_id lb-backup-105
}

vrrp_script check-haproxy {
    script "killall -0 haproxy"
    interval 5
    weight -30
}

vrrp_instance VI-kube-master {
    state BACKUP
    priority 110
    dont_track_primary
    interface ${BACKUP_VIP_IF}
    virtual_router_id 68
    advert_int 3
    track_script {
        check-haproxy
    }
    virtual_ipaddress {
        ${MASTER_VIP}
    }
}
EOF
cat >keepalived-backup1.conf <<EOF
global_defs {
    router_id lb-backup-105
}

vrrp_script check-haproxy {
    script "killall -0 haproxy"
    interval 5
    weight -30
}

vrrp_instance VI-kube-master {
    state BACKUP
    priority 110
    dont_track_primary
    interface ${BACKUP1_VIP_IF}
    virtual_router_id 68
    advert_int 3
    track_script {
        check-haproxy
    }
    virtual_ipaddress {
        ${MASTER_VIP}
    }
}
EOF
info "deploy master conf to master server .... "
scp keepalived-master.conf "${k8s_user:?}@${KEEP_MASTER_IP:?}":/opt/k8s/
echo ">>> ${KEEP_MASTER_IP}"
ssh "$k8s_user@${KEEP_MASTER_IP}" "sudo mv /opt/k8s/keepalived-master.conf /etc/keepalived/keepalived.conf"
info "deploy backup conf to backup nodes ..... "
# for node_ip in "${KEEP_BACKUP_IPS[@]}"; do
#     echo ">>> ${node_ip}"
#     scp keepalived-backup.conf "$k8s_user@${node_ip}":/opt/k8s/
#     ssh "$k8s_user@${node_ip}" "sudo mv /opt/k8s/keepalived-backup.conf /etc/keepalived/keepalived.conf"
# done
echo ">>> ${KEEP_BACKUP_IP}"
scp keepalived-backup.conf "$k8s_user@${KEEP_BACKUP_IP}":/opt/k8s/
ssh "$k8s_user@${KEEP_BACKUP_IP}" "sudo mv /opt/k8s/keepalived-backup.conf /etc/keepalived/keepalived.conf"

echo ">>> ${KEEP_BACKUP1_IP}"
scp keepalived-backup1.conf "$k8s_user@${KEEP_BACKUP1_IP}":/opt/k8s/keepalived-backup.conf
ssh "$k8s_user@${KEEP_BACKUP1_IP}" "sudo mv /opt/k8s/keepalived-backup.conf /etc/keepalived/keepalived.conf"

echo ">>> ${KEEP_MASTER_IP}"
info "start keepalived service ....."
ssh "$k8s_user@${KEEP_MASTER_IP}" "sudo systemctl restart keepalived"

for node_ip in "${KEEP_BACKUP_IPS[@]}"; do
    echo ">>> ${node_ip}"
    ssh "$k8s_user@${node_ip}" "sudo systemctl restart keepalived"
done
