#!/bin/bash
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s

source /opt/k8s/bin/environment.sh
for node_ip in "${WORKER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/quay-io-kubernetes_incubator-nfs-provisioner:v2.2.1-k8s1.12 \
        &&docker pull ${my_registry}/quay-io-external_storage-nfs-client-provisioner:v3.1.0-k8s1.11"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/quay-io-kubernetes_incubator-nfs-provisioner:v2.2.1-k8s1.12 \
    quay.io/kubernetes_incubator/nfs-provisioner:v2.2.1-k8s1.12 \
    &&docker tag ${my_registry}/quay-io-external_storage-nfs-client-provisioner:v3.1.0-k8s1.11 \
        quay.io/external_storage/nfs-client-provisioner:v3.1.0-k8s1.11"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/quay-io-kubernetes_incubator-nfs-provisioner:v2.2.1-k8s1.12 \
        &&docker rmi -f ${my_registry}/quay-io-external_storage-nfs-client-provisioner:v3.1.0-k8s1.11"
done
