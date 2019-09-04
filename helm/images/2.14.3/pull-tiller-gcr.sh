#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull tiller Images from k8s.gcr.io ......"
echo " You may need proxy ..... "
echo "====================================================================="
echo ""
# 镜像版本查询
# https://console.cloud.google.com/gcr/images/kubernetes-helm/GLOBAL/tiller?gcrImageListsize=30
echo ""
echo "tiller .... "
tiller_version=2.14.3
docker pull gcr.io/kubernetes-helm/tiller:v$tiller_version
