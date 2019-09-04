#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-15 22:42:47
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 12:50:02
# @Description:
###

# shellcheck disable=SC2034
# shellcheck disable=SC2029
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
info "docker systemd unit .... "
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/docker ] && rm -rf /opt/k8s/services/docker
mkdir -p /opt/k8s/services/docker
cd /opt/k8s/services/docker || return
cat >docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target flanneld.service
Wants=network-online.target
# Requires=flanneld.service
[Service]
WorkingDirectory=##DOCKER_DIR##
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd --log-level=error $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
RestartSec=5
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

cat >docker-daemon.json <<EOF
{
    "registry-mirrors": ["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://hub-mirror.c.163.com"],
    "max-concurrent-downloads": 20,
    "live-restore": true,
    "max-concurrent-uploads": 10,
    "debug": true,
    "data-root": "${DOCKER_DIR}/data",
    "exec-root": "${DOCKER_DIR}/exec",
    "log-opts": {
      "max-size": "100m",
      "max-file": "5"
    }
}
EOF

info "deploy files to all worker nodes ..... "

sed -i -e "s|##DOCKER_DIR##|${DOCKER_DIR}|" docker.service
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    ssh "${k8s_user:?}@${node_ip}" "sudo mkdir -p  /etc/docker/ ${DOCKER_DIR}/{data,exec}"
    ssh "${k8s_user:?}@${node_ip}" "sudo chown -R $k8s_user ${DOCKER_DIR}/"
    scp docker-daemon.json docker.service "${k8s_user:?}"@"${node_ip}":/opt/k8s/
    ssh "$k8s_user@${node_ip}" "sudo rm -rf /usr/lib/systemd/system/docker.service && sudo mv /opt/k8s/docker.service /etc/systemd/system/"
    ssh "$k8s_user@${node_ip}" "sudo rm -rf /etc/docker/daemon.json && sudo mv /opt/k8s/docker-daemon.json /etc/docker/daemon.json"
done

info "start every worker node docker service ..... "
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp /u01/tools/kubernetes-toolkit/k8s-worker/remove-docker0.sh "${k8s_user:?}"@"${node_ip}":/opt/k8s/bin/
    ssh "$k8s_user@${node_ip}" "sudo chmod +x /opt/k8s/bin/*.sh"
    ssh "$k8s_user@${node_ip}" "sudo /usr/sbin/iptables -F && sudo /usr/sbin/iptables -X && sudo /usr/sbin/iptables -F -t nat && sudo /usr/sbin/iptables -X -t nat"
    ssh "$k8s_user@${node_ip}" "sudo /usr/sbin/iptables -P FORWARD ACCEPT"
    ssh "$k8s_user@${node_ip}" "sudo /opt/k8s/bin/remove-docker0.sh"
    ssh "$k8s_user@${node_ip}" "sudo systemctl daemon-reload && sudo systemctl disable docker && sudo systemctl enable docker && sudo systemctl restart docker"
done
