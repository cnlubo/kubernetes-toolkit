#!/bin/bash
# shellcheck disable=SC2029
###
# @Author: cnak47
# @Date: 2019-08-06 11:57:12
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-06 12:06:23
# @Description:
###
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
elastic_version=7.2.1
# shellcheck disable=SC1091
source /opt/k8s/bin/environment.sh

for node_ip in "${WORKER_IPS[@]}"; do
    echo ">>> ${node_ip}"
    ssh "${k8s_user:?}@${node_ip}" "docker login $harbor_host"

    ssh "${k8s_user:?}@${node_ip}" "docker pull ${my_registry}/elastic-co-beats-filebeat:$elastic_version"
    ssh "${k8s_user:?}@${node_ip}" "docker pull docker.elastic.co/beats/filebeat:$elastic_version"

    # ssh "${k8s_user:?}@${node_ip}" "docker tag ${my_registry}/elastic-co-beats-journalbeat:$elastic_version \
    #     docker.elastic.co/beats/journalbeat:$elastic_version"

    # ssh "${k8s_user:?}@${node_ip}" "docker tag ${my_registry}/elastic-co-beats-metricbeat:$elastic_version \
    #     docker.elastic.co/beats/metricbeat:$elastic_version"

    ssh "${k8s_user:?}@${node_ip}" "docker rmi -f ${my_registry}/elastic-co-beats-filebeat:$elastic_version"
    # ssh "${k8s_user:?}@${node_ip}" "docker rmi -f ${my_registry}/elastic-co-beats-journalbeat:$elastic_version"
    # ssh "${k8s_user:?}@${node_ip}" "docker rmi -f ${my_registry}/elastic-co-beats-metricbeat:$elastic_version"

done
