#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/nfs-server-provisioner
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=0.3.0
helm fetch --untar stable/nfs-server-provisioner
helm package -u --version=$chart_version nfs-server-provisioner
rm -rf nfs-server-provisioner
