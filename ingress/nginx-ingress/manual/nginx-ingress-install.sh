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
for node_name in "${EDGENODE_NAMES[@]}"
do
    echo ">>> ${node_name}"
    # 打标签指定edgenode 节点
    kubectl label --overwrite nodes ${node_name} edgenode=true
done
[ ! -d /opt/k8s/addons/ingress-nginx/manual ] && mkdir -p /opt/k8s/addons/ingress-nginx/manual
cd /opt/k8s/addons/ingress-nginx/manual || exit
info "modify yaml files ..... "
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/namespace.yaml \
-O namespace.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/configmap.yaml \
-O configmap.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/rbac.yaml \
-O rbac.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/with-rbac.yaml \
-O with-rbac.yaml
cp with-rbac.yaml{,.orig}
cat > /tmp/temp_file.yaml <<EOF
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: ${edgenode_label:?}
                operator: In
                values:
                - "true"
EOF
sed -i '/nginx-ingress-serviceaccount/r /tmp/temp_file.yaml' with-rbac.yaml
rm -rf /tmp/temp_file.yaml
sed -i "s@replicas: 1@replicas: ${edgenode_counts:?}@1" with-rbac.yaml
cat > service-ingress-nginx.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
 type: LoadBalancer
 externalIPs:
   - ${egenode_vip:?}
 externalTrafficPolicy: Local
 healthCheckNodePort: 0
 ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
    - name: https
      port: 443
      targetPort: 443
      protocol: TCP
 selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
EOF
info " install ingress-nginx ....."
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f rbac.yaml
kubectl apply -f with-rbac.yaml
kubectl apply -f service-ingress-nginx.yaml
info "install ingress-nginx finish ..... "

# kubectl delete -f namespace.yaml
# kubectl delete -f configmap.yaml
# kubectl delete -f rbac.yaml
# kubectl delete -f with-rbac.yaml
# kubectl delete -f  service-ingress-nginx.yaml
# 进入nginx-ingress-controller进行查看是否注入了nginx的配置
#kubectl exec -n ingress-nginx -it nginx-ingress-controller-6bd7c597cb-6pchv -- /bin/bash
#www-data@nginx-ingress-controller-6bd7c597cb-6pchv:/etc/nginx$ cat nginx.conf
#  kubectl -n ingress-nginx log -f $(kubectl -n ingress-nginx get pods | grep ingress | head -1 | cut -f 1 -d " ")
