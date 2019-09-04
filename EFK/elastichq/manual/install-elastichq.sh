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
[ ! -d /opt/k8s/addons/es-hq/manual ] && mkdir -p /opt/k8s/addons/es-hq/manual
cd /opt/k8s/addons/es-hq/manual || exit

export es_connect_host="http://elasticsearch-client:9200"

info " deploy elasticsearch-HQ ..... "
cat > k8s-es-hq.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: es-hq
  namespace: logging
  labels:
    app: elasticsearch-HQ
    release: elasticsearch-HQ
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch-HQ
      release: elasticsearch-HQ
  template:
    metadata:
      labels:
        app: elasticsearch-HQ
        release: elasticsearch-HQ
    spec:
      containers:
      - name: es-hq
        image: elastichq/elasticsearch-hq:release-v3.5.0
        env:
        - name: HQ_DEFAULT_URL
          value: $es_connect_host
        resources:
          limits:
            cpu: 0.5
        ports:
        - containerPort: 5000
          name: http
---
apiVersion: v1
kind: Service
metadata:
  name: es-hq
  namespace: logging
  labels:
    app: elasticsearch-HQ
    release: elasticsearch-HQ
spec:
  selector:
    app: elasticsearch-HQ
    release: elasticsearch-HQ
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: 5000
    protocol: TCP

EOF
kubectl apply -f k8s-es-hq.yaml
