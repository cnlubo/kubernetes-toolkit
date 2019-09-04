#!/bin/bash
# https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner
[ ! -d /opt/k8s/helm/charts ] && mkdir -p /opt/k8s/helm/charts
cd /opt/k8s/helm/charts || exit
chart_version=1.2.6
helm fetch --untar stable/nfs-client-provisioner
helm package -u --version=$chart_version nfs-client-provisioner
rm -rf nfs-client-provisioner
