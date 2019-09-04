#!/bin/bash
# https://quay.io/repository/fluentd_elasticsearch/fluentd?tab=tags
echo ""
echo "===================================================================="
echo " Pull Extra Images ......"
echo " fluentd "
echo " You may need a proxy ....."
echo "====================================================================="
echo ""
echo "fluentd images"
echo ""
fluentd_version=2.5.2
docker pull quay.io/fluentd_elasticsearch/fluentd:v$fluentd_version
