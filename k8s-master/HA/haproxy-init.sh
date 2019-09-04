#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-11 14:11:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-15 00:09:07
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
info "create haproxy system unit ....."
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/haproxy ] && rm -rf /opt/k8s/services/haproxy
mkdir -p /opt/k8s/services/haproxy
cd /opt/k8s/services/haproxy || return
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh

cat >haproxy.service <<EOF
[Unit]
Description=HAProxy Load Balancer
Documentation=man:haproxy(1)
After=syslog.target network.target
#After=syslog.target network-online.target kube-apiserver.service
Wants=network-online.target
[Service]
EnvironmentFile=-/etc/sysconfig/haproxy
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/var/run/haproxy.pid"
ExecStartPre=/usr/sbin/haproxy -f \$CONFIG -c -q
ExecStart=/usr/sbin/haproxy -Ws -f \$CONFIG -p \$PIDFILE
ExecReload=/usr/sbin/haproxy -f \$CONFIG -c -q
ExecReload=/bin/kill -USR2 \$MAINPID
KillMode=mixed
Restart=always
Type=notify

# The following lines leverage SystemD's sandboxing options to provide
# defense in depth protection at the expense of restricting some flexibility
# in your setup (e.g. placement of your configuration files) or possibly
# reduced performance. See systemd.service(5) and systemd.exec(5) for further
# information.

# NoNewPrivileges=true
# ProtectHome=true
# If you want to use 'ProtectSystem=strict' you should whitelist the PIDFILE,
# any state files and any other files written using 'ReadWritePaths' or
# 'RuntimeDirectory'.
# ProtectSystem=true
# ProtectKernelTunables=true
# ProtectKernelModules=true
# ProtectControlGroups=true
# If your SystemD version supports them, you can add: @reboot, @swap, @sync
# SystemCallFilter=~@cpu-emulation @keyring @module @obsolete @raw-io

[Install]
WantedBy=multi-user.target
EOF

info "deploy haproxy systemd unit to all master nodes ..... "
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp haproxy.service "${k8s_user:?}@${node_ip}":/opt/k8s/
    ssh "$k8s_user@${node_ip}" "sudo mv /opt/k8s/haproxy.service /etc/systemd/system/haproxy.service"
done

info "create haproxy.cfg ..... "
cat >haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot  /usr/local/haproxy
    stats socket /var/run/haproxy-admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    nbproc 1

defaults
    log     global
    timeout connect 5000
    timeout client  10m
    timeout server  10m

listen  admin_stats
    bind 0.0.0.0:10080
    mode http
    log 127.0.0.1 local0 err
    stats refresh 30s
    stats uri /status
    stats realm welcome login\ Haproxy
    stats auth admin:123456
    stats hide-version
    stats admin if TRUE

listen kube-master
    bind 0.0.0.0:8443
    mode tcp
    option tcplog
    balance source
    server $MASTER_1 $MASTER_1:6443 check inter 2000 fall 2 rise 2 weight 1
    server $MASTER_2 $MASTER_2:6443 check inter 2000 fall 2 rise 2 weight 1
    server $MASTER_3 $MASTER_3:6443 check inter 2000 fall 2 rise 2 weight 1
EOF

info "deploy haproxy.cfg to all master nodes ..... "
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp haproxy.cfg "$k8s_user@${node_ip}":/opt/k8s/
    ssh "$k8s_user@${node_ip}" "sudo mv /opt/k8s/haproxy.cfg /etc/haproxy/ && sudo chown -R haproxy /etc/haproxy/"
done

info "start every node haproxy services ..... "
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    ssh "$k8s_user@${node_ip}" "sudo systemctl daemon-reload && sudo systemctl enable haproxy && sudo systemctl restart haproxy"
done
