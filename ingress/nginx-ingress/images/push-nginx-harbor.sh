#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Extra Images into local harbor k8s ......"
echo " ingress-nginx "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host
ingress_controller_version=0.25.0
docker tag quay.io/kubernetes-ingress-controller/nginx-ingress-controller:$ingress_controller_version \
${my_registry}/quay-io-nginx-ingress-controller:$ingress_controller_version
docker tag k8s.gcr.io/defaultbackend-amd64:1.5 \
${my_registry}/k8s-gcr-io-defaultbackend-amd64:1.5
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/quay-io-nginx-ingress-controller:$ingress_controller_version
docker push ${my_registry}/k8s-gcr-io-defaultbackend-amd64:1.5
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
