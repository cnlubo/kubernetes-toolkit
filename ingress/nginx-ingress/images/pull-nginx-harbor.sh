#!/bin/bash
source /opt/k8s/bin/environment.sh
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
ingress_controller_version=0.25.0

for node_ip in "${EDGENODE_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/quay-io-nginx-ingress-controller:$ingress_controller_version"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/k8s-gcr-io-defaultbackend-amd64:1.5"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/quay-io-nginx-ingress-controller:$ingress_controller_version quay.io/kubernetes-ingress-controller/nginx-ingress-controller:${ingress_controller_version:?}"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/k8s-gcr-io-defaultbackend-amd64:1.5 k8s.gcr.io/defaultbackend-amd64:1.5"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/quay-io-nginx-ingress-controller:$ingress_controller_version"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/k8s-gcr-io-defaultbackend-amd64:1.5"

done
