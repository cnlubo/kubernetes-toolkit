#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Elastic stack into local harbor k8s ......"
echo " elasticsearch kibana "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
elastic_version=6.8.2

docker login $harbor_host
docker tag docker.elastic.co/elasticsearch/elasticsearch:$elastic_version \
 ${my_registry}/elastic-co-elasticsearch-elasticsearch:$elastic_version
 docker tag docker.elastic.co/kibana/kibana:$elastic_version \
  ${my_registry}/elastic-co-kibana-kibana:$elastic_version
# docker tag dduportal/bats:0.4.0 \
#     ${my_registry}/dduportal-bats:0.4.0
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/elastic-co-elasticsearch-elasticsearch:$elastic_version
docker push ${my_registry}/elastic-co-kibana-kibana:$elastic_version
# docker push ${my_registry}/dduportal-bats:0.4.0
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
