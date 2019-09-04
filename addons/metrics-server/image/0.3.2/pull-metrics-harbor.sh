#!/bin/bash
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s

source /opt/k8s/bin/environment.sh
for node_ip in "${WORKER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/gcr-io-google_containers-metrics-server-amd64:v0.3.2"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/k8s-gcr-io-addon-resizer:1.8.5"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/gcr-io-google_containers-metrics-server-amd64:v0.3.2 \
        gcr.io/google_containers/metrics-server-amd64:v0.3.2"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/k8s-gcr-io-addon-resizer:1.8.5 \
        k8s.gcr.io/addon-resizer:1.8.5"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/gcr-io-google_containers-metrics-server-amd64:v0.3.2"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/k8s-gcr-io-addon-resizer:1.8.5"

done
