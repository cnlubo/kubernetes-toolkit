#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/kubernetes-dashboard
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=1.7.1
helm fetch --untar stable/kubernetes-dashboard
helm package -u --version=$chart_version kubernetes-dashboard
rm -rf kubernetes-dashboard
