#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull Elastic stack Images ......"
echo " elasticsearch kibana "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo " pull images from docker.elastic.co"
echo ""
# https://www.docker.elastic.co/#
# oss版本，不包含X-pack，只有开源的Elasticsearch
#docker pull docker.elastic.co/elasticsearch/elasticsearch-oss
# 基本版本(默认版本)，包含X-pack的基本特性和免费证书
elastic_version=7.2.1
docker pull docker.elastic.co/elasticsearch/elasticsearch:$elastic_version
docker pull docker.elastic.co/kibana/kibana:$elastic_version

# docker pull dduportal/bats:0.4.0
# docker pull busybox:latest
