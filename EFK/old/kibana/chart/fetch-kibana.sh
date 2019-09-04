#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/kibana
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=3.2.3
helm fetch --untar stable/kibana
helm package -u --version=$chart_version kibana
rm -rf kibana
