#!/bin/bash
# shellcheck disable=SC2034
###
 # @Author: cnak47
 # @Date: 2019-08-05 23:11:19
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-06 12:30:41
 # @Description: 
###
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
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh
export kibana_host="kibana.ak47.com"
[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/kibana/chart ] && rm -rf /opt/k8s/addons/kibana/chart
mkdir -p /opt/k8s/addons/kibana/chart
cd /opt/k8s/addons/kibana/chart || exit
info " fetch kibana chart ..... "
helm fetch --untar harborrepo/kibana --version=7.2.1-0
info "create kibana-settings.yaml ..... "
cat > kibana-settings.yaml <<EOF
elasticsearchHosts: "http://elasticsearch-master:9200"
replicas: 1
imageTag: "7.2.1"
kibanaConfig:
    kibana.yml: |
      server.name: kibana
      server.host: "0"
      elasticsearch.hosts: http://elasticsearch-master:9200
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
    kubernetes.io/tls-acme: 'true'
  hosts:
    - $kibana_host
  tls:
    - secretName: k8s-kibana-secret
      hosts:
        - $kibana_host

EOF

info " install kibana ..... "
helm install \
  --name kibana \
  --namespace logging \
  -f kibana-settings.yaml \
  kibana
  info "create secret ..... "
  kubectl create secret generic k8s-kibana-secret \
  --from-file=tls.key=/opt/k8s/certs/ingress-nginx/ingress-nginx-key.pem \
  --from-file=tls.crt=/opt/k8s/certs/ingress-nginx/ingress-nginx.pem -n logging --dry-run -o yaml | kubectl apply -f -
