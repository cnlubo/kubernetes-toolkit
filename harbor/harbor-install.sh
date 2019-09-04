#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-17 21:40:55
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 17:57:48
 # @Description: 
 ###

# shellcheck disable=SC2034
# shellcheck disable=SC1091
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
harbor_major_version=1.8.0
harbor_version=1.8.1
info "harbor-v${harbor_version:?} install ..... "
cd /u01/src || exit
if [ ! -f /u01/src/harbor-offline-installer-v$harbor_version.tgz ]; then
    # 需要翻墙
    src_url="https://storage.googleapis.com/harbor-releases/release-$harbor_major_version/harbor-offline-installer-v$harbor_version.tgz"
    wget src_url -O harbor-offline-installer-v$harbor_version.tgz
fi
[ -d /u01/harbor ] && sudo rm -rf /u01/harbor
tar xf harbor-offline-installer-v$harbor_version.tgz
[ -d /u01/harbor ] && sudo rm -rf /u01/harbor
mv harbor /u01/
cd /u01/harbor || exit
source /opt/k8s/bin/environment.sh
info " load docker images ..... "
docker load -i harbor.v$harbor_version.tar.gz
info "modify harbor.yml ..... "
cp harbor.yml{,.orig}
sed -i "s@hostname: reg.mydomain.com@hostname: ${harbor_node_ip:?}@1" harbor.yml
sed -i "/^# https related config/a\https:\n  port: ${harbor_https_port:?}\n  certificate: /etc/harbor/ssl/harbor.pem\n  private_key: /etc/harbor/ssl/harbor-key.pem\n" harbor.yml
sed -i "s@port: 80@port: ${harbor_http_port:?}@1" harbor.yml
sed -i "s@data_volume: /data@data_volume: /data/harbor@1" harbor.yml
cp prepare{,.orig}
sed -i 's@empty_subj = "/"@empty_subj = "/C=/ST=/L=/O=/CN=/"@1' prepare
info " start harbor images ....."
runAsRoot mkdir /harbor_data
runAsRoot chmod 777 /var/run/docker.sock /harbor_data
runAsRoot ./install.sh --with-chartmuseum
