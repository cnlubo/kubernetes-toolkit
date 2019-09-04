#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-11 14:11:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-15 09:56:56
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

# http://www.haproxy.org/
haproxy_version=2.0.4
haproxy_main_version=2.0
info "haproxy-$haproxy_version install...."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
cd /u01/src || return
#runAsRoot yum install -y pcre pcre-devel gcc gcc-c++ autoconf automake systemd-devel libnl-devel rpm-build libnfnetlink-devel
if [ ! -f /u01/src/haproxy-$haproxy_version.tar.gz ]; then
    src_url=https://www.haproxy.org/download/$haproxy_main_version/src/haproxy-$haproxy_version.tar.gz
    wget $src_url
fi
openssl_install_dir=/usr/local/software/openssl-1.1.1
# shellcheck disable=SC2029
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp haproxy-$haproxy_version.tar.gz "${k8s_user:?}@${node_ip}":/u01/src/
    ssh "${k8s_user:?}@${node_ip}" "cd /u01/src/ && tar xf haproxy-$haproxy_version.tar.gz"
    ssh "${k8s_user:?}@${node_ip}" "sudo yum install -y pcre pcre-devel gcc gcc-c++ autoconf automake systemd-devel libnl-devel rpm-build libnfnetlink-devel"
    ssh "$k8s_user@${node_ip}" "export LIBRARY_PATH=${openssl_install_dir:?}/lib:$LIBRARY_PATH \
     && cd /u01/src/haproxy-$haproxy_version \
     && make TARGET=linux-glibc ARCH=x86_64 PREFIX=/usr/local/haproxy USE_PCRE=1 USE_SYSTEMD=1 \
     && sudo rm -rf /usr/local/haproxy \
     && sudo make install PREFIX=/usr/local/haproxy"
    ssh "$k8s_user@${node_ip}" "sudo groupadd haproxy && sudo useradd -g haproxy haproxy -s /sbin/nologin"
    echo ">>> configure haproxy ..... "
    ssh "$k8s_user@${node_ip}" "sudo mkdir -p /var/lib/haproxy && sudo mkdir -p /etc/haproxy \
    && sudo chown -R haproxy /var/lib/haproxy \
    && sudo chown -R haproxy /usr/local/haproxy/ \
    && sudo chown -R haproxy /etc/haproxy/ \
    && sudo  rm -rf /usr/sbin/haproxy \
    && sudo ln -s /usr/local/haproxy/sbin/haproxy /usr/sbin/ \
    && sudo chown haproxy /usr/sbin/haproxy"
    echo ">>> haproxy-$haproxy_version install success ..... "
done

# cd haproxy-$haproxy_version || return
#openssl_install_dir=/usr/local/software/openssl-1.1.1
#export LIBRARY_PATH=$openssl_install_dir/lib:$LIBRARY_PATH
# make TARGET=linux-glibc ARCH=x86_64 PREFIX=/usr/local/haproxy USE_PCRE=1 USE_SYSTEMD=1
# [ -d /usr/local/haproxy ] && runAsRoot rm -rf /usr/local/haproxy
# runAsRoot make install PREFIX=/usr/local/haproxy
# id haproxy >/dev/null 2>&1
# if [ $? -eq 0 ]; then
#     warn "[ system user(haproxy) already exists !!!]"
# else
#     info "create haproxy user ....."
#     runAsRoot groupadd haproxy
#     runAsRoot useradd -g haproxy haproxy -s/sbin/nologin
# fi
# configure haproxy
# runAsRoot mkdir -p /var/lib/haproxy
# runAsRoot chown -R haproxy /var/lib/haproxy
# runAsRoot mkdir -p /etc/haproxy
# runAsRoot chown -R haproxy /usr/local/haproxy/
# runAsRoot chown -R haproxy /etc/haproxy/
# [ -f /usr/sbin/haproxy ] && runAsRoot rm -rf /usr/sbin/haproxy
# runAsRoot ln -s /usr/local/haproxy/sbin/haproxy /usr/sbin/
# runAsRoot chown haproxy /usr/sbin/haproxy
