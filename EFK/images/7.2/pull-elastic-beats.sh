#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-08-06 10:08:44
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-06 11:47:03
# @Description:
###
# https://github.com/elastic/beats
echo ""
echo "===================================================================="
echo " Pull Elastic beats Images ......"
echo " Auditbeat Filebeat Heartbeat Journalbeat Metricbeat Packetbeat "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo " pull images from docker.elastic.co"
echo ""
elastic_version=7.2.1
docker pull docker.elastic.co/beats/filebeat:$elastic_version
docker pull docker.elastic.co/beats/journalbeat:$elastic_version
docker pull docker.elastic.co/beats/metricbeat:$elastic_version
