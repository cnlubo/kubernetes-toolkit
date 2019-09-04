#!/bin/bash
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
source /opt/k8s/bin/environment.sh
[ ! -d /opt/k8s/certs ] && mkdir -p /opt/k8s/certs
[ -d /opt/k8s/certs/helm ] && rm -rf /opt/k8s/certs/helm
mkdir -p /opt/k8s/certs/helm
cd /opt/k8s/certs/helm || exit
info "create  helm-csr.json ..... "
# helm 客户端证书
cat > helm-csr.json <<EOF
{
  "CN": "helm",
  "hosts": [],
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
  -ca-key=/etc/kubernetes/cert/ca-key.pem  \
  -config=/etc/kubernetes/cert/ca-config.json  \
  -profile=peer helm-csr.json | cfssljson -bare helm

info "create tiller-csr.json ..... "
# tiller 服务端证书请求
cat > tiller-csr.json <<EOF
{
  "CN": "tiller",
  "hosts": [],
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
  -ca-key=/etc/kubernetes/cert/ca-key.pem  \
  -config=/etc/kubernetes/cert/ca-config.json  \
  -profile=peer tiller-csr.json | cfssljson -bare tiller

info "deploy to all workers ..... "
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp tiller*.pem ${k8s_user:?}@${node_ip}:/etc/kubernetes/cert/
  done
