#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-07-09 12:39:28
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 16:52:43
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

k8suser="ak47"
cfssl_version="1.2"
info "install cfssl-$cfssl_version"
runAsRoot mkdir -p /opt/k8s/bin
runAsRoot chown -R $k8suser /opt/k8s
cd /opt/k8s || exit
wget https://pkg.cfssl.org/R$cfssl_version/cfssl_linux-amd64
wget https://pkg.cfssl.org/R$cfssl_version/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R$cfssl_version/cfssl-certinfo_linux-amd64
mv cfssl_linux-amd64 /opt/k8s/bin/cfssl
mv cfssljson_linux-amd64 /opt/k8s/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /opt/k8s/bin/cfssl-certinfo
chmod +x /opt/k8s/bin/*
#export PATH=/opt/k8s/bin:$PATH
