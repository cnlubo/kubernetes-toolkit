#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/elasticsearch
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=1.30.0
helm fetch --untar stable/elasticsearch
helm package -u --version=$chart_version elasticsearch
rm -rf elasticsearch
