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
info "create kubeconfig ..... "
cd /opt/k8s/certs/kube-proxy || exit
source /opt/k8s/bin/environment.sh
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

info "deploy kubeconfig to all worker nodes ..... "
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp kube-proxy.kubeconfig ${k8s_user:?}@${node_ip}:/etc/kubernetes/
  done

info "create kube-proxy.config ..... "
cat > kube-proxy-config.yaml.template <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  burst: 200
  kubeconfig: "/etc/kubernetes/kube-proxy.kubeconfig"
  qps: 100
bindAddress: ##NODE_IP##
healthzBindAddress: ##NODE_IP##:10256
metricsBindAddress: ##NODE_IP##:10249
enableProfiling: true
clusterCIDR: ${CLUSTER_CIDR}
hostnameOverride: ##NODE_NAME##
mode: "ipvs"
portRange: ""
kubeProxyIPTablesConfiguration:
  masqueradeAll: false
kubeProxyIPVSConfiguration:
  scheduler: rr
  excludeCIDRs: []
EOF

info "deploy kube-proxy.config ..... "
worker_counts=${#WORKER_IPS[@]}
for (( i=0; i < $worker_counts; i++ ))
  do
    echo ">>> ${WORKER_NAMES[i]}"
    sed -e "s/##NODE_NAME##/${WORKER_NAMES[i]}/" -e "s/##NODE_IP##/${WORKER_IPS[i]}/" kube-proxy-config.yaml.template > kube-proxy-${WORKER_NAMES[i]}.config.yaml
    scp kube-proxy-${WORKER_NAMES[i]}.config.yaml $k8s_user@${WORKER_IPS[i]}:/etc/kubernetes/kube-proxy.config.yaml
  done
info "create kube-proxy systemd unit ..... "
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/kube-proxy ] && rm -rf /opt/k8s/services/kube-proxy
mkdir -p /opt/k8s/services/kube-proxy
cd /opt/k8s/services/kube-proxy || return
cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-proxy
ExecStart=/opt/k8s/bin/kube-proxy \\
  --config=/etc/kubernetes/kube-proxy.config.yaml \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_DIR}/logs \\
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

info "deploy systemd unit ..... "
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp kube-proxy.service $k8s_user@${node_ip}:/opt/k8s/
    ssh $k8s_user@${node_ip} "sudo mv /opt/k8s/kube-proxy.service /etc/systemd/system/"
  done
info "start kube-proxy service ..... "
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo mkdir -p ${K8S_DIR}/kube-proxy&&sudo chown -R $k8s_user ${K8S_DIR}/kube-proxy"
    ssh $k8s_user@${node_ip} "[ ! -d ${K8S_DIR}/logs ]&&sudo mkdir -p ${K8S_DIR}/logs&&sudo chown -R $k8s_user ${K8S_DIR}/logs"
    ssh  $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl disable kube-proxy && sudo systemctl enable kube-proxy && sudo systemctl restart kube-proxy"
  done
