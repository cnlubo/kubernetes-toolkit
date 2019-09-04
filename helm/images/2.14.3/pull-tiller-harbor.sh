#!/bin/bash
source /opt/k8s/bin/environment.sh
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
tiller_version=2.14.3
for node_ip in "${MASTER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host && docker pull ${my_registry}/gcr-io-kubernetes-helm-tiller:v$tiller_version"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/gcr-io-kubernetes-helm-tiller:v$tiller_version gcr.io/kubernetes-helm/tiller:v$tiller_version"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/gcr-io-kubernetes-helm-tiller:v$tiller_version"
  done
