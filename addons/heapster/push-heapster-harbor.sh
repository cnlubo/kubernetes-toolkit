#!/bin/bash
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24
my_registry=$harbor_host/k8s
docker login $harbor_host
docker tag k8s.gcr.io/heapster-amd64:v1.5.4 ${my_registry}/k8s-gcr-io-heapster-amd64:v1.5.4
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/k8s-gcr-io-heapster-amd64:v1.5.4
