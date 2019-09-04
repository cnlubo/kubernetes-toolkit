#!/bin/bash
# shellcheck disable=SC2034
# 配置按照 node 数量 自动伸缩 dns 数量
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

[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ ! -d /opt/k8s/addons/coredns ] && mkdir -p /opt/k8s/addons/coredns
cd /opt/k8s/addons/coredns || exit
#https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns-horizontal-autoscaler/dns-horizontal-autoscaler.yaml
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns-horizontal-autoscaler/dns-horizontal-autoscaler.yaml \
-O dns-horizontal-autoscaler.yaml
cp dns-horizontal-autoscaler.yaml{,.orig}
sed -i "s@{{.Target}}@deployment/coredns@" dns-horizontal-autoscaler.yaml
kubectl apply -f dns-horizontal-autoscaler.yaml
# 手动扩容
# kubectl scale deployment coredns --namespace=kube-system --replicas=3
# kubectl -n kube-system get configmap | grep dns
# kubectl -n kube-system get configmap kube-dns-autoscaler -o yaml
