#!/bin/bash
echo ""
echo "===================================================================="
echo " Pull Extra Images from kubernetesui ......"
echo " dashboard "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo "dashbaord"
echo ""
docker pull kubernetesui/dashboard:v2.0.0-beta2
docker pull kubernetesui/metrics-scraper:v1.0.1
