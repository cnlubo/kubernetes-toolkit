#!/bin/bash
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s

source /opt/k8s/bin/environment.sh
for node_ip in "${WORKER_IPS[@]}"
  do
    echo ">>> ${node_ip}"
    ssh ${k8s_user:?}@${node_ip} "docker login $harbor_host"
    ssh ${k8s_user:?}@${node_ip} "docker pull ${my_registry}/kubernetesui-dashboard:v2.0.0-beta2 \
    &&docker pull ${my_registry}/kubernetesui-metrics-scraper:v1.0.1"
    ssh ${k8s_user:?}@${node_ip} "docker tag ${my_registry}/kubernetesui-dashboard:v2.0.0-beta2 kubernetesui/dashboardv2.0.0-beta2 \
    &&docker tag ${my_registry}/kubernetesui-metrics-scraper:v1.0.1 \
    kubernetesui/metrics-scraper:v1.0.1"
    ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/kubernetesui-dashboard:v2.0.0-beta2 \
    &&docker rmi -f ${my_registry}/kubernetesui-metrics-scraper:v1.0.1"
  done
