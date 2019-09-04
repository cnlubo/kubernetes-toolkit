#!/bin/bash
harbor_host=10.0.1.24
my_registry=$harbor_host/k8s
docker login $harbor_host

docker pull ${my_registry}/k8s-gcr-metrics-server-amd64:v0.3.1
docker tag ${my_registry}/k8s-gcr-metrics-server-amd64:v0.3.1 \
    k8s.gcr.io/metrics-server-amd64:v0.3.1
docker rmi -f ${my_registry}/k8s-gcr-metrics-server-amd64:v0.3.1

docker pull ${my_registry}/k8s-gcr-io-addon-resizer:1.8.3
docker tag ${my_registry}/k8s-gcr-io-addon-resizer:1.8.3 \
    k8s.gcr.io/addon-resizer:1.8.3
docker rmi -f ${my_registry}/k8s-gcr-io-addon-resizer:1.8.3
