#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Extra Images into local harbor k8s ......"
echo " metrics-server "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host
docker tag gcr.io/google_containers/metrics-server-amd64:v0.3.2 \
 ${my_registry}/gcr-io-google_containers-metrics-server-amd64:v0.3.2
docker tag k8s.gcr.io/addon-resizer:1.8.5 \
 ${my_registry}/k8s-gcr-io-addon-resizer:1.8.5
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/gcr-io-google_containers-metrics-server-amd64:v0.3.2
docker push ${my_registry}/k8s-gcr-io-addon-resizer:1.8.5
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
