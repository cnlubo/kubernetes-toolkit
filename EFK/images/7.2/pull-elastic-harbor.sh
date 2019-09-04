#!/bin/bash
# shellcheck disable=SC2029
###
# @Author: cnak47
# @Date: 2019-08-04 21:33:52
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-05 16:13:45
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
    ssh "${k8s_user:?}@${node_ip}" "docker pull ${my_registry}/elastic-co-elasticsearch-elasticsearch:$elastic_version"
    ssh "${k8s_user:?}@${node_ip}" "docker pull ${my_registry}/elastic-co-kibana-kibana:$elastic_version"

    ssh "${k8s_user:?}@${node_ip}" "docker tag ${my_registry}/elastic-co-elasticsearch-elasticsearch:$elastic_version \
        docker.elastic.co/elasticsearch/elasticsearch:$elastic_version"
    ssh "${k8s_user:?}@${node_ip}" "docker tag ${my_registry}/elastic-co-kibana-kibana:$elastic_version \
        docker.elastic.co/kibana/kibana:$elastic_version"

    ssh "${k8s_user:?}@${node_ip}" "docker rmi -f ${my_registry}/elastic-co-elasticsearch-elasticsearch:$elastic_version"
    ssh "${k8s_user:?}@${node_ip}" "docker rmi -f ${my_registry}/elastic-co-kibana-kibana:$elastic_version"

    # ssh ${k8s_user:?}@${node_ip} "tag ${my_registry}/dduportal-bats:0.4.0
    #    dduportal/bats:0.4.0"
    # ssh ${k8s_user:?}@${node_ip} "docker rmi -f ${my_registry}/dduportal-bats:0.4.0"
done
