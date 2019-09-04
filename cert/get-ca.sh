#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-09 12:39:28
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 17:27:41
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
[ -d /opt/k8s/certs/CA ] && rm -rf /opt/k8s/certs/CA
mkdir -p /opt/k8s/certs/CA
cd /opt/k8s/certs/CA || exit
info "create ca-config.json"

cat > ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "2540400h"
        },
        "profiles": {
            "server": {
                "expiry": "2540400h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "2540400h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "2540400h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
info "create ca-csr.json"
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
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
      "OU": "K8S"
    }
  ]
}
EOF
info "create self-signed root CA certificate and private key .."
export PATH=/opt/k8s/bin:$PATH
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
info "check certificate ....."
openssl x509  -noout -text -in  ca.pem
