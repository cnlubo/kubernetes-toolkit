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
export es_hq_host="es-hq.ak47.com"
mkdir -p /opt/k8s/addons/es-hq/manual/ingress
cd /opt/k8s/addons/es-hq/manual/ingress || exit
info "create es-hq ingress  ..... "

cat > ingress-es-hq-tls.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: es-hq-ingress
  namespace: logging
  annotations:
    kubernetes.io/ingress.class: "nginx"
    kubernetes.io/tls-acme: 'true'

spec:
  tls:
  - secretName: k8s-es-hq-secret
    hosts:
    - $es_hq_host

  rules:
  - host: $es_hq_host
    http:
      paths:
      - path: /
        backend:
          serviceName: es-hq
          servicePort: 80
EOF
kubectl apply -f ingress-es-hq-tls.yaml
