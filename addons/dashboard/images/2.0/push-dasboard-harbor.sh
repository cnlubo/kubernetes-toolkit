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
docker tag kubernetesui/dashboard:v2.0.0-beta2 ${my_registry}/kubernetesui-dashboard:v2.0.0-beta2
docker tag kubernetesui/metrics-scraper:v1.0.1 \
    ${my_registry}/kubernetesui-metrics-scraper:v1.0.1
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/kubernetesui-dashboard:v2.0.0-beta2
docker push ${my_registry}/kubernetesui-metrics-scraper:v1.0.1
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
