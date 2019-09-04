#!/bin/bash
harbor_host=10.0.1.24
my_registry=$harbor_host/k8s
docker login $harbor_host
docker pull ${my_registry}/k8s-gcr-io-heapster-amd64:v1.5.4
docker tag ${my_registry}/k8s-gcr-io-heapster-amd64:v1.5.4 \
    k8s.gcr.io/heapster-amd64:v1.5.4
docker rmi -f ${my_registry}/k8s-gcr-io-heapster-amd64:v1.5.4
