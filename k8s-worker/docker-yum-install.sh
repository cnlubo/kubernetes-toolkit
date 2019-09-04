#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-15 22:42:47
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 11:21:02
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

docker_version=19.03.1-3.el7
compose_version=1.24.1
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    info " remove old docker-ce install ..... "
    ssh "${k8s_user:?}"@"${node_ip}" "sudo yum -y remove docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate \
    docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine"
    info "docker-ce-$docker_version install ..... "
    ssh "${k8s_user:?}@${node_ip}" "sudo yum install -y yum-utils \
    device-mapper-persistent-data lvm2 yum-plugin-versionlock"
    ssh "${k8s_user:?}@${node_ip}" "sudo yum-config-manager \
    --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
    ssh "${k8s_user:?}@${node_ip}" "sudo yum -y install docker-ce-$docker_version"
    info "lock docker-ce version"
    ssh "${k8s_user:?}@${node_ip}" "sudo yum versionlock add docker-ce&&sudo yum versionlock status"
    ssh "${k8s_user:?}@${node_ip}" "sudo systemctl stop docker&&sudo systemctl disable docker"
    ssh "${k8s_user:?}@${node_ip}" "sudo systemctl start docker&& sudo systemctl enable docker"
    # Executing the Docker Command Without Sudo
    ssh "${k8s_user:?}@${node_ip}" "sudo groupadd docker&&sudo chown root:docker /var/run/docker.sock"
    ssh "${k8s_user:?}@${node_ip}" "sudo usermod -aG docker ${USER}&&sudo systemctl restart docker"
    # info "install docker-compose ...."
    # ssh ${k8s_user:?}@${node_ip} "curl -L 'https://github.com/docker/compose/releases/download/$compose_version/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose"
    # ssh ${k8s_user:?}@${node_ip} "sudo chmod +x /usr/local/bin/docker-compose"
    ssh "${k8s_user:?}@${node_ip}" "docker version"
done
