#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull ingress-nginx Images ...... "
echo " You may need proxy ..... "
echo "====================================================================="
echo ""
# 镜像版本查询
# https://console.cloud.google.com/gcr/images/kubernetes-helm/GLOBAL/tiller?gcrImageListsize=30
echo ""
echo "kubernetes-ingress-controller .... "
echo ""
ingress_controller_version=0.25.0
docker pull quay.io/kubernetes-ingress-controller/nginx-ingress-controller:${ingress_controller_version:?}
echo "defaultbackend .... "
docker pull k8s.gcr.io/defaultbackend-amd64:1.5
