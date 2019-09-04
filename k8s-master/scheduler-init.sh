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
cd /opt/k8s/certs/kube-scheduler || exit
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/cert/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.pem \
  --client-key=kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig

info "deploy kubeconfig to all master nodes ..... "
for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    scp kube-scheduler.kubeconfig ${k8s_user:?}@${node_ip}:/etc/kubernetes/
done

info "create and deploy kube-scheduler.yaml ....."
cd /opt/k8s/certs/kube-scheduler || exit

cat >kube-scheduler.yaml.template <<EOF
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
bindTimeoutSeconds: 600
clientConnection:
  burst: 200
  kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
  qps: 100
enableContentionProfiling: false
enableProfiling: true
hardPodAffinitySymmetricWeight: 1
healthzBindAddress: ##NODE_IP##:10251
leaderElection:
  leaderElect: true
metricsBindAddress: ##NODE_IP##:10251
EOF

node_counts=${#MASTER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
do
    sed -e "s/##NODE_IP##/${MASTER_IPS[i]}/" kube-scheduler.yaml.template > kube-scheduler-${MASTER_IPS[i]}.yaml
done

for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    scp kube-scheduler-${node_ip}.yaml ${k8s_user:?}@${node_ip}:/etc/kubernetes/kube-scheduler.yaml
done

info "create and deploy systemd unit ..... "
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/kube-scheduler ] && rm -rf /opt/k8s/services/kube-scheduler
mkdir -p /opt/k8s/services/kube-scheduler
cd /opt/k8s/services/kube-scheduler || return
cat > kube-scheduler.service.template <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-scheduler
ExecStart=/opt/k8s/bin/kube-scheduler \\
  --config=/etc/kubernetes/kube-scheduler.yaml \\
  --bind-address=##NODE_IP## \\
  --secure-port=10259 \\
  --port=0 \\
  --tls-cert-file=/etc/kubernetes/cert/kube-scheduler.pem \\
  --tls-private-key-file=/etc/kubernetes/cert/kube-scheduler-key.pem \\
  --authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
  --client-ca-file=/etc/kubernetes/cert/ca.pem \\
  --requestheader-allowed-names="" \\
  --requestheader-client-ca-file=/etc/kubernetes/cert/aggregator-ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_DIR}/logs \\
  --v=2
Restart=on-failure
RestartSec=5
User=$k8s_user

[Install]
WantedBy=multi-user.target
EOF

node_counts=${#MASTER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
do
    sed -e "s/##NODE_IP##/${MASTER_IPS[i]}/" kube-scheduler.service.template > kube-scheduler-${MASTER_IPS[i]}.service
done

 info "deploy system unit to every master node ...."
for node_ip in "${MASTER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo mkdir -p ${K8S_DIR}/kube-scheduler && sudo chown -R $k8s_user ${K8S_DIR}/kube-scheduler"
    ssh $k8s_user@${node_ip} "[ ! -d ${K8S_DIR}/logs ]&&sudo mkdir -p ${K8S_DIR}/logs&&sudo chown -R $k8s_user ${K8S_DIR}/logs"
    scp kube-scheduler-${node_ip}.service $k8s_user@${node_ip}:/opt/k8s/kube-scheduler.service
    ssh $k8s_user@${node_ip} "sudo mv /opt/k8s/kube-scheduler.service /etc/systemd/system/kube-scheduler.service"
done

info "start kube-scheduler service ..... "
for node_ip in "${MASTER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl stop kube-scheduler "
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl enable kube-scheduler && sudo systemctl restart kube-scheduler"
done
