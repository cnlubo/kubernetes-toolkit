#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-11 14:11:50
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-19 23:29:35
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

# http://www.keepalived.org
keepalived_version=2.0.18
info "keepalived-$keepalived_version install...."
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
# cd /u01/src || return
cd /tmp || return
#runAsRoot yum install -y gcc gcc-c++ make libnl-devel rpm-build libnfnetlink-devel
if [ ! -f keepalived-$keepalived_version.tar.gz ]; then
    src_url=http://www.keepalived.org/software/keepalived-$keepalived_version.tar.gz
    wget $src_url
fi
openssl_install_dir=/usr/local/software/openssl-1.1.1
# shellcheck disable=SC2029
for node_ip in "${MASTER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    scp /tmp/keepalived-$keepalived_version.tar.gz "${k8s_user:?}@${node_ip}":/u01/src/
    ssh "${k8s_user:?}@${node_ip}" "cd /u01/src/ && rm -rf  keepalived-$keepalived_version && tar xvf keepalived-$keepalived_version.tar.gz"
    ssh "${k8s_user:?}@${node_ip}" "sudo yum install -y gcc gcc-c++ make libnl-devel \
    rpm-build libnfnetlink-devel libnftnl-devel libmnl-devel"
    # ssh "$k8s_user@${node_ip}" "export LIBRARY_PATH=${openssl_install_dir:?}/lib:$LIBRARY_PATH \
    ssh "$k8s_user@${node_ip}" "LDFLAGS="$LDFLAGS -L $openssl_install_dir/lib" \
     &&export $LDFLAGS \
     &&CPPFLAGS="$CPPFLAGS -I $openssl_install_dir/include" \
     &&export $CPPFLAGS \
     &&cd /u01/src/keepalived-$keepalived_version \
     &&sudo rm -rf /usr/local/keepalived \
     &&./configure --prefix=/usr/local/keepalived \
     &&make -j $(nproc) && sudo make install "
    echo ">>> configure keepalived ..... "
    ssh "$k8s_user@${node_ip}" " sudo mkdir -p /etc/keepalived \
     && sudo cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf \
     && sudo cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/keepalived \
     && sudo systemctl enable keepalived"
done

# [ -d keepalived-$keepalived_version ] && rm -rf keepalived-$keepalived_version
# tar xvf keepalived-$keepalived_version.tar.gz
# cd keepalived-$keepalived_version || return
# openssl_install_dir=/usr/local/software/openssl-1.1.1
# export LIBRARY_PATH=$openssl_install_dir/lib:$LIBRARY_PATH
# [ -d /usr/local/keepalived ] && runAsRoot rm -rf /usr/local/keepalived
# ./configure --prefix=/usr/local/keepalived
# make -j "$(nproc)"
# runAsRoot make install

# # configure keepalived
# runAsRoot mkdir -p /etc/keepalived
# # keepalived default conf /etc/keepalived/keepalived.conf
# runAsRoot cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
# runAsRoot cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/keepalived
# # runAsRoot cp $build_src/keepalived-$keepalived_version/keepalived/etc/init.d/keepalived /etc/rc.d/init.d/keepalived
# runAsRoot systemctl enable keepalived
