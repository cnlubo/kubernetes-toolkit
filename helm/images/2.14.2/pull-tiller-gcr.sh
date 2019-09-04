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
docker pull gcr.io/kubernetes-helm/tiller:v2.14.2
