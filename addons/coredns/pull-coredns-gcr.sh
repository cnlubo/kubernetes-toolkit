#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull Extra Images from k8s.gcr.io ......"
echo " Coredns "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo "coredns"
docker pull k8s.gcr.io/coredns:1.3.1
docker pull k8s.gcr.io/cluster-proportional-autoscaler-amd64:1.6.0
