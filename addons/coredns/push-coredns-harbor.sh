#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Extra Images into local harbor k8s ......"
echo " Coredns/dashboard/metrics-server "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host
docker tag k8s.gcr.io/coredns:1.3.1 ${my_registry}/k8s-gcr-io-coredns:1.3.1
docker tag k8s.gcr.io/cluster-proportional-autoscaler-amd64:1.6.0 \
    ${my_registry}/k8s-gcr-io-cluster-proportional-autoscaler-amd64:1.6.0
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/k8s-gcr-io-coredns:1.3.1
docker push ${my_registry}/k8s-gcr-io-cluster-proportional-autoscaler-amd64:1.6.0
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
