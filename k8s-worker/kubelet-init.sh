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

info "create bootstrap kubeconfig ....."
[ ! -d /opt/k8s/certs/kubelet ] && mkdir -p /opt/k8s/certs/kubelet
cd /opt/k8s/certs/kubelet || return
source /opt/k8s/bin/environment.sh

for node_name in "${WORKER_NAMES[@]}"
  do
    echo ">>> ${node_name}"
    # create  token
     BOOTSTRAP_TOKEN=$(kubeadm token create \
      --description kubelet-bootstrap-token \
      --groups system:bootstrappers:${node_name} \
      --kubeconfig ~/.kube/config)
      export BOOTSTRAP_TOKEN
    # 设置集群参数
    kubectl config set-cluster kubernetes \
      --certificate-authority=/etc/kubernetes/cert/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
    # 设置客户端认证参数
    kubectl config set-credentials kubelet-bootstrap \
      --token=${BOOTSTRAP_TOKEN} \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
    # 设置上下文参数
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kubelet-bootstrap \
      --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
    # 设置默认上下文
    kubectl config use-context default --kubeconfig=kubelet-bootstrap-${node_name}.kubeconfig
  done

 info "deploy bootstrap kubeconfig to all worker nodes ..... "

node_counts=${#WORKER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
do
    echo ">>> ${WORKER_NAMES[i]}"
    scp kubelet-bootstrap-${WORKER_NAMES[i]:?}.kubeconfig ${k8s_user:?}@${WORKER_IPS[i]:?}:/etc/kubernetes/kubelet-bootstrap.kubeconfig
done

info "kubelet-config.yaml.template ....."
cat > kubelet-config.yaml.template <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: "##NODE_IP##"
staticPodPath: ""
syncFrequency: 1m
fileCheckFrequency: 20s
httpCheckFrequency: 20s
staticPodURL: ""
port: 10250
readOnlyPort: 0
rotateCertificates: true
serverTLSBootstrap: true
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/etc/kubernetes/cert/ca.pem"
authorization:
  mode: Webhook
registryPullQPS: 0
registryBurst: 20
eventRecordQPS: 0
eventBurst: 20
enableDebuggingHandlers: true
enableContentionProfiling: true
healthzPort: 10248
healthzBindAddress: "##NODE_IP##"
clusterDomain: "${CLUSTER_DNS_DOMAIN}"
clusterDNS:
  - "${CLUSTER_DNS_SVC_IP}"
nodeStatusUpdateFrequency: 10s
nodeStatusReportFrequency: 1m
imageMinimumGCAge: 2m
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
volumeStatsAggPeriod: 1m
kubeletCgroups: ""
systemCgroups: ""
cgroupRoot: ""
cgroupsPerQOS: true
cgroupDriver: cgroupfs
runtimeRequestTimeout: 10m
hairpinMode: promiscuous-bridge
maxPods: 220
podCIDR: "${CLUSTER_CIDR}"
podPidsLimit: -1
resolvConf: /etc/resolv.conf
maxOpenFiles: 1000000
kubeAPIQPS: 1000
kubeAPIBurst: 2000
serializeImagePulls: false
evictionHard:
  memory.available:  "100Mi"
nodefs.available:  "10%"
nodefs.inodesFree: "5%"
imagefs.available: "15%"
evictionSoft: {}
enableControllerAttachDetach: true
failSwapOn: true
containerLogMaxSize: 20Mi
containerLogMaxFiles: 10
systemReserved: {}
kubeReserved: {}
systemReservedCgroup: ""
kubeReservedCgroup: ""
enforceNodeAllocatable: ["pods"]
EOF

info "deploy kubelet-config.yaml ..... "

for node_ip in "${WORKER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    sed -e "s/##NODE_IP##/${node_ip}/" kubelet-config.yaml.template > kubelet-config-${node_ip}.yaml
    scp kubelet-config-${node_ip}.yaml $k8s_user@${node_ip}:/etc/kubernetes/kubelet-config.yaml
done

info "create kubelet systemd unit ....."
[ ! -d /opt/k8s/services ] && mkdir -p /opt/k8s/services
[ -d /opt/k8s/services/kubelet ] && rm -rf /opt/k8s/services/kubelet
mkdir -p /opt/k8s/services/kubelet
cd /opt/k8s/services/kubelet || return
cat > kubelet.service.template <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service
[Service]
WorkingDirectory=${K8S_DIR}/kubelet
ExecStart=/opt/k8s/bin/kubelet \\
  --allow-privileged=true \\
  --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \\
  --cert-dir=/etc/kubernetes/cert \\
  --cni-conf-dir=/etc/cni/net.d \\
  --container-runtime=docker \\
  --container-runtime-endpoint=unix:///var/run/dockershim.sock \\
  --root-dir=${K8S_DIR}/kubelet \\
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \\
  --config=/etc/kubernetes/kubelet-config.yaml \\
  --hostname-override=##NODE_NAME## \\
  --pod-infra-container-image=registry.cn-beijing.aliyuncs.com/k8s_images/pause-amd64:3.1 \\
  --image-pull-progress-deadline=15m \\
  --volume-plugin-dir=${K8S_DIR}/kubelet/kubelet-plugins/volume/exec/ \\
  --alsologtostderr=true \\
  --logtostderr=false \\
  --log-dir=${K8S_DIR}/logs \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

info "deploy kubelet systemd unit ..... "
node_counts=${#WORKER_IPS[@]}
for (( i=0; i < $node_counts; i++ ))
do
    echo ">>> ${WORKER_NAMES[i]}"
    sed -e "s/##NODE_NAME##/${WORKER_NAMES[i]:?}/" kubelet.service.template > kubelet-${WORKER_NAMES[i]:?}.service
    scp kubelet-${WORKER_NAMES[i]:?}.service $k8s_user@${WORKER_IPS[i]:?}:/opt/k8s/kubelet.service
    ssh $k8s_user@${WORKER_IPS[i]:?} "sudo mv /opt/k8s/kubelet.service /etc/systemd/system/"
done

info "grants permissions ..... "
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers
info "start kubelet services ..... "
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh $k8s_user@${node_ip} "sudo mkdir -p ${K8S_DIR}/kubelet&&sudo chown -R $k8s_user ${K8S_DIR}/kubelet"
    ssh $k8s_user@${node_ip} "[ ! -d ${K8S_DIR}/logs ]&&sudo mkdir -p ${K8S_DIR}/logs&&sudo chown -R $k8s_user ${K8S_DIR}/logs"
    ssh $k8s_user@${node_ip} "sudo /usr/sbin/swapoff -a"
    ssh $k8s_user@${node_ip} "sudo systemctl daemon-reload && sudo systemctl enable kubelet && sudo systemctl restart kubelet"
  done
