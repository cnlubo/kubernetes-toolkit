#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-08-06 11:42:58
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-06 12:04:31
# @Description:
###

echo ""
echo "================================================================="
echo " Push Elastic stack into local harbor k8s ......"
echo " Auditbeat Filebeat Heartbeat Journalbeat Metricbeat Packetbeat "
echo "================================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
elastic_version=7.2.1

docker login $harbor_host
docker tag docker.elastic.co/beats/filebeat:$elastic_version \
    ${my_registry}/elastic-co-beats-filebeat:$elastic_version
docker tag docker.elastic.co/beats/journalbeat:$elastic_version \
    ${my_registry}/elastic-co-beats-journalbeat:$elastic_version
docker tag docker.elastic.co/beats/metricbeat:$elastic_version \
    ${my_registry}/elastic-co-beats-metricbeat:$elastic_version

echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/elastic-co-beats-filebeat:$elastic_version
docker push ${my_registry}/elastic-co-beats-journalbeat:$elastic_version
docker push ${my_registry}/elastic-co-beats-metricbeat:$elastic_version
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
