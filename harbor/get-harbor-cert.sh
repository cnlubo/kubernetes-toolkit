#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-17 21:40:55
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 13:28:24
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

[ ! -d /opt/k8s/certs ] && mkdir -p /opt/k8s/certs
[ -d /opt/k8s/certs/harbor ] && rm -rf /opt/k8s/certs/harbor
mkdir -p /opt/k8s/certs/harbor
cd /opt/k8s/certs/harbor || exit
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
info "create harbor-csr.json"
cat > harbor-csr.json <<EOF
{
  "CN": "harbor",
  "hosts": [
    "127.0.0.1",
    "${harbor_node_ip:?}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Beijing",
      "L": "Beijing",
      "O": "ANSHI",
      "OU": "k8s"
    }
  ]
}
EOF
info "create certificate and private key ...."
cfssl gencert -ca=/etc/kubernetes/cert/ca.pem \
  -ca-key=/etc/kubernetes/cert/ca-key.pem \
  -config=/etc/kubernetes/cert/ca-config.json \
  -profile=peer harbor-csr.json | cfssljson -bare harbor
ls harbor*
info "deploy certs ..... "
echo ">>> ${harbor_node_ip}"
ssh "${k8s_user:?}@${harbor_node_ip}" "sudo rm -rf /etc/harbor/ssl && sudo mkdir -p /etc/harbor/ssl && sudo chown -R $k8s_user /etc/harbor/ "
scp /opt/k8s/certs/harbor/harbor*.pem "$k8s_user@${harbor_node_ip}":/etc/harbor/ssl
ssh "${k8s_user:?}@${harbor_node_ip}" "sudo chmod 644 /etc/harbor/ssl/harbor-key.pem"
