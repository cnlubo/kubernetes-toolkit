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
mkdir -p /opt/k8s/test/ingress-nginx
[ ! -d /opt/k8s/test/ingress-nginx/tomcat ] && mkdir -p /opt/k8s/test/ingress-nginx/tomcat
cd /opt/k8s/test/ingress-nginx/tomcat || exit
info " deploy tomcat-tls-demo ..... "
cat > tomcat-tls-demo.yaml <<EOF
apiVersion:              v1
kind:                    Service
metadata:
  name:                  tomcat-tls
  namespace:             default
spec:
  selector:
    app:                 tomcat
    release:             canary
  ports:
  - name:                http
    targetPort:          8080
    port:                8080
  - name:                ajp
    targetPort:          8009
    port:                8009
---
apiVersion:              apps/v1
kind:                    Deployment
metadata:
  name:                  tomcat-deploy
  namespace:             default
spec:
  replicas:              3
  selector:
    matchLabels:
      app:               tomcat
      release:           canary
  template:
    metadata:
      labels:
        app:             tomcat
        release:         canary
    spec:
      containers:
      - name:            tomcat
        #image:          tomcat:8.5.43-jdk8-openjdk-slim
        image:           tomcat:9.0.22-jdk11-openjdk-slim
        #此镜像在dockerhub上进行下载，需要查看版本是否有变化，hub.docker.com
        ports:
        - name:          http
          containerPort: 8080
          name:          ajp
          containerPort: 8009
EOF

kubectl apply -f tomcat-tls-demo.yaml

info "deploy ingress-tomcat-tls ..... "

cat > ingress-tomcat-tls.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tomcat
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  - hosts:
    - k8s.ak47.com
    secretName: secret-ingress
  rules:
  - host: k8s.ak47.com # 必须为域名
    http:
      paths:
      - backend:
          serviceName: tomcat-tls
          servicePort: 8080
EOF
kubectl apply -f ingress-tomcat-tls.yaml
