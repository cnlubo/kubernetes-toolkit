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
info "regen kube-apiserver systemd unit ..... "
cd /opt/k8s/services/apiserver || exit
cp kube-apiserver.service.template{,.orig}
cat > kube-apiserver.service.template <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target etcd.service flanneld.service

[Service]
ExecStart=/opt/k8s/bin/kube-apiserver \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --anonymous-auth=false \\
  --experimental-encryption-provider-config=/etc/kubernetes/encryption-config.yaml \\
  --advertise-address=##NODE_IP## \\
  --bind-address=##NODE_IP## \\
  --insecure-port=0 \\
  --authorization-mode=Node,RBAC \\
  --runtime-config=api/all \\
  --enable-bootstrap-token-auth \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=${NODE_PORT_RANGE} \\
  --tls-cert-file=/etc/kubernetes/cert/kubernetes.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kubernetes-key.pem \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --kubelet-client-certificate=/etc/kubernetes/cert/kubernetes.pem \\
  --kubelet-client-key=/etc/kubernetes/cert/kubernetes-key.pem \\
  --service-account-key-file=/etc/kubernetes/cert/ca-key.pem \\
  --etcd-cafile=/etc/kubernetes/cert/ca.pem \\
  --etcd-certfile=/etc/kubernetes/cert/kubernetes.pem \\
  --etcd-keyfile=/etc/kubernetes/cert/kubernetes-key.pem \\
  --etcd-servers=${ETCD_ENDPOINTS} \\
  --enable-swagger-ui=true \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/kube-apiserver-audit.log \\
  --event-ttl=1h \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=/var/log/kubernetes \\
  --v=2 \\
  --requestheader-client-ca-file=/etc/kubernetes/cert/aggregator-ca.pem \\
  --requestheader-allowed-names=aggregator \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --proxy-client-cert-file=/etc/kubernetes/cert/aggregator.pem \\
  --proxy-client-key-file=/etc/kubernetes/cert/aggregator-key.pem \\
  --runtime-config=api/all=true
Restart=on-failure
RestartSec=5
Type=notify
User=${k8s_user:?}
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
#   --requestheader-allowed-names="" \\
info "deploy kube-apiserver systemd unit to all master nodes ....."
node_counts=${#MASTER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
  do
    sed -e "s/##NODE_NAME##/${MASTER_NAMES[i]}/" -e "s/##NODE_IP##/${MASTER_IPS[i]}/" kube-apiserver.service.template > kube-apiserver-${MASTER_IPS[i]}.service
done

for node_ip in "${MASTER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo mkdir -p /var/log/kubernetes && sudo chown -R $k8s_user /var/log/kubernetes"
    scp kube-apiserver-${node_ip}.service $k8s_user@${node_ip}:/opt/k8s/kube-apiserver.service
    ssh $k8s_user@${node_ip} "sudo mv /opt/k8s/kube-apiserver.service /etc/systemd/system/"
  done
info "start kube-apiserver service ..... "
for node_ip in "${MASTER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl restart kube-apiserver"
  done
