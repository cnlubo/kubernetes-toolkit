#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull Nfs Images from quay.io ......"
echo " nfs-server-provisioner/nfs-client-provisioner "
echo " You may need proxy ..... "
echo "====================================================================="
echo ""
echo "nfs-server-provisioner"
echo ""
docker pull quay.io/kubernetes_incubator/nfs-provisioner:v2.2.1-k8s1.12
echo ""
echo "nfs-client-provisioner"
echo ""
docker pull quay.io/external_storage/nfs-client-provisioner:v3.1.0-k8s1.11
