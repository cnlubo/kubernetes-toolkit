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
info "create kubeconfig file ..... "
cd /opt/k8s/certs/kube-controller-manager || exit
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.pem \
  --client-key=kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context system:kube-controller-manager \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig

info "deploy kubeconfig to all nodes ..... "
for node_ip in "${MASTER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    scp kube-controller-manager.kubeconfig ${k8s_user:?}@${node_ip}:/etc/kubernetes/
  done
info "create and deploy systemd unit ..... "
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/controller-manager ] && rm -rf /opt/k8s/services/controller-manager
mkdir -p /opt/k8s/services/controller-manager
cd /opt/k8s/services/controller-manager || return
cat > kube-controller-manager.service.template <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-controller-manager
ExecStart=/opt/k8s/bin/kube-controller-manager \\
  --profiling \\
  --bind-address=##NODE_IP## \\
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --authentication-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/etc/kubernetes/cert/ca.pem \\
  --cluster-signing-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --experimental-cluster-signing-duration=876000h \\
  --root-ca-file=/etc/kubernetes/cert/ca.pem \\
  --service-account-private-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --kube-api-qps=1000 \\
  --kube-api-burst=2000 \\
  --leader-elect \\
  --use-service-account-credentials \\
  --concurrent-service-syncs=2 \\
  --concurrent-deployment-syncs=10 \\
  --concurrent-gc-syncs=30 \\
  --node-cidr-mask-size=24 \\
  --pod-eviction-timeout=6m \\
  --terminated-pod-gc-threshold=10000 \\
  --tls-cert-file=/etc/kubernetes/cert/kube-controller-manager.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kube-controller-manager-key.pem \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-allowed-names="" \\
  --requestheader-client-ca-file=/etc/kubernetes/cert/aggregator-ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --feature-gates=RotateKubeletServerCertificate=true \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_DIR}/logs \\
  --secure-port=10252 \\
  --port=0 \\
  --v=2
Restart=on-failure
RestartSec=5
User=$k8s_user

[Install]
WantedBy=multi-user.target
EOF

# gen every node service file
node_counts=${#MASTER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
  do
    sed -e "s/##NODE_IP##/${MASTER_IPS[i]}/" kube-controller-manager.service.template > kube-controller-manager-${MASTER_IPS[i]}.service
  done

info "deploy system unit to every master node ...."
for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo mkdir -p ${K8S_DIR}/kube-controller-manager && sudo chown -R $k8s_user ${K8S_DIR}/kube-controller-manager"
    ssh $k8s_user@${node_ip} "[ ! -d ${K8S_DIR}/logs ]&&sudo mkdir -p ${K8S_DIR}/logs&&sudo chown -R $k8s_user ${K8S_DIR}/logs"
    scp kube-controller-manager-${node_ip}.service $k8s_user@${node_ip}:/opt/k8s/kube-controller-manager.service
    ssh $k8s_user@${node_ip} "sudo mv /opt/k8s/kube-controller-manager.service /etc/systemd/system/kube-controller-manager.service"
done

info "start kube-controller-manager ..... "
for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl stop kube-controller-manager "
    # ssh $k8s_user@${node_ip} "sudo mkdir -p /var/log/kubernetes && sudo chown -R $k8s_user /var/log/kubernetes"
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl enable kube-controller-manager && sudo systemctl restart kube-controller-manager"
done
