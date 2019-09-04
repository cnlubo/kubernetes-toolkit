#!/bin/bash
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host

docker tag quay.io/kubernetes_incubator/nfs-provisioner:v2.2.1-k8s1.12 \
    ${my_registry}/quay-io-kubernetes_incubator-nfs-provisioner:v2.2.1-k8s1.12
docker tag quay.io/external_storage/nfs-client-provisioner:v3.1.0-k8s1.11 \
    ${my_registry}/quay-io-external_storage-nfs-client-provisioner:v3.1.0-k8s1.11

docker push ${my_registry}/quay-io-kubernetes_incubator-nfs-provisioner:v2.2.1-k8s1.12
docker push ${my_registry}/quay-io-external_storage-nfs-client-provisioner:v3.1.0-k8s1.11
