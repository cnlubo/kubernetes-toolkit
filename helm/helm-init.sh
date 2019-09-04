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

[ ! -d /opt/k8s/addons ] && mkdir -p /opt/k8s/addons
[ -d /opt/k8s/addons/helm ] && rm -rf /opt/k8s/addons/helm
mkdir -p /opt/k8s/addons/helm
cd /opt/k8s/addons/helm || exit
info "helm-rbac-config.yaml ..... "
cat > helm-rbac-config.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF

kubectl apply -f helm-rbac-config.yaml

info  "helm init, will add tiller pod to k8s......"
# --debug \
helm init \
--upgrade \
--tiller-tls \
--tiller-tls-verify \
--tiller-tls-cert /etc/kubernetes/cert/tiller.pem \
--tiller-tls-key /etc/kubernetes/cert/tiller-key.pem \
--tls-ca-cert /etc/kubernetes/cert/ca.pem \
--service-account tiller \
--stable-repo-url http://mirror.azure.cn/kubernetes/charts/ \
--tiller-namespace kube-system
# http://mirror.azure.cn/kubernetes/charts/ 微软国内chart 镜像

#       --tiller-image {{ tiller_image }} \
#       --stable-repo-url {{ repo_url }}"
#info  "Patch deployment..."
#kubectl -n kube-system patch deployment tiller-deploy \
#-p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
info "helm install success !!! "
helm plugin install https://github.com/chartmuseum/helm-push
#helm version
