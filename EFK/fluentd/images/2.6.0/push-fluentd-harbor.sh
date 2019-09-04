#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Extra Images into local harbor k8s ......"
echo " fluentd "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host

docker tag quay.io/fluentd_elasticsearch/fluentd:v2.6.0 \
 ${my_registry}/quay-io-fluentd_elasticsearch-fluentd:v2.6.0
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/quay-io-fluentd_elasticsearch-fluentd:v2.6.0
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
