#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/metrics-server
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=1.11.0
helm fetch --untar stable/nginx-ingress
helm package -u --version=$chart_version nginx-ingress
rm -rf nginx-ingress
