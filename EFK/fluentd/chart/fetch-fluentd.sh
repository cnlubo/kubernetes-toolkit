#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/fluentd
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=1.10.0
helm fetch --untar stable/fluentd
helm package -u --version=$chart_version fluentd
rm -rf fluentd
