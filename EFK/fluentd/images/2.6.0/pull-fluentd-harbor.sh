#!/bin/bash
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s

source /opt/k8s/bin/environment.sh
for node_ip in "${WORKER_IPS[@]}"
do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/quay-io-fluentd_elasticsearch-fluentd:v2.6.0"

    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/quay-io-fluentd_elasticsearch-fluentd:v2.6.0 \
        quay.io/fluentd_elasticsearch/fluentd:v2.6.0"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/quay-io-fluentd_elasticsearch-fluentd:v2.6.0"
done
