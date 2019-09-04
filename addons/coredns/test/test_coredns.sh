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

info " create test services ..... "
[ ! -d /opt/k8s/addons/coredns/test ] && mkdir -p /opt/k8s/addons/coredns/test
cd /opt/k8s/addons/coredns/test || exit
cat > my-nginx.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.17.1
        ports:
        - containerPort: 80
EOF
kubectl create -f my-nginx.yaml
info "Export Deployment, Create my-nginx service ..... "
kubectl expose deploy my-nginx
info "create dnsutils"
cat > dnsutils-ds.yml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: dnsutils-ds
  labels:
    app: dnsutils-ds
spec:
  type: NodePort
  selector:
    app: dnsutils-ds
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: dnsutils-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  template:
    metadata:
      labels:
        app: dnsutils-ds
    spec:
      containers:
      - name: my-dnsutils
        image: tutum/dnsutils:latest
        command:
          - sleep
          - "3600"
        ports:
        - containerPort: 80
EOF
kubectl create -f dnsutils-ds.yml


# cat > pod-nginx.yaml <<EOF
# apiVersion: v1
# kind: Pod
# metadata:
#   name: nginx
# spec:
#   containers:
#   - name: nginx
#     image: nginx:1.14.2
#     ports:
#     - containerPort: 80
# EOF
# kubectl create -f pod-nginx.yaml

# kubectl get services --all-namespaces -o wide | grep my-nginx
# kubectl exec  nginx -i -t -- /bin/bash
# root@nginx:/ cat /etc/resolv.conf
# apt-get update && apt-get install iputils-ping dnsutils -y
# ping my-nginx
# ping kubernetes
# ping kube-dns.kube-system.svc.cluster.local
# nslookup my-nginx
# nslookup my-nginx.default.svc.cluster.local
# nslookup www.baidu.com
# nslookup kubernetes
