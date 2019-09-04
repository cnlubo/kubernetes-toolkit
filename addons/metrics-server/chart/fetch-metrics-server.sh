#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/metrics-server
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=2.8.2
helm fetch --untar stable/metrics-server
helm package -u --version=$chart_version metrics-server
rm -rf metrics-server
