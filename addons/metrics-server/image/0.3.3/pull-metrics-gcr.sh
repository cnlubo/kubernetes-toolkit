#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull Extra Images from kubernetesui ......"
echo " metrics-server "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo " metrics-server "
echo ""
docker pull k8s.gcr.io/metrics-server-amd64:v0.3.3
#docker pull k8s.gcr.io/addon-resizer:1.8.5
