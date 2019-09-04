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

info "create test file ....."
[ -d /opt/k8s/work/test ] && rm -rf /opt/k8s/work/test
mkdir -p /opt/k8s/work/test
cd /opt/k8s/work/test || exit
cat > nginx-ds.yml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-ds
  labels:
    app: nginx-ds
spec:
  type: NodePort
  selector:
    app: nginx-ds
  ports:
  - name: http
    port: 80
    targetPort: 80
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.17.1
        ports:
        - containerPort: 80
EOF
kubectl create -f nginx-ds.yml

# 获得nginx-ds的Pod IP
# kubectl get pods  -o wide|grep nginx-ds
# 在所有 Node上分别ping 这三个IP,看是否连通
# source /opt/k8s/bin/environment.sh
# for node_ip in "${WORKER_IPS[@]}"
#   do
#     echo ">>> ${node_ip}"
#     ssh ${node_ip} "ping -c 1 172.30.88.2"
#     ssh ${node_ip} "ping -c 1 172.30.8.2"
#     ssh ${node_ip} "ping -c 1 172.30.41.2"
#   done
# 检查服务IP和端口可达性
# 获得 NodePort 端口 和 service IP
# kubectl get svc |grep nginx-ds
# 在所有Node上curl Service IP
# source /opt/k8s/bin/environment.sh
# for node_ip in "${WORKER_IPS[@]}"
#   do
#     echo ">>> ${node_ip}"
#     ssh ${node_ip} "curl 10.254.34.131"
#   done
# # 输出 nginx 欢迎页面内容
# 检查服务的NodePort可达性
# source /opt/k8s/bin/environment.sh
# for node_ip in "${WORKER_IPS[@]}"
#   do
#     echo ">>> ${node_ip}"
#     ssh ${node_ip} "curl ${node_ip}:8696"
#   done
# # 输出 nginx 欢迎页面内容
