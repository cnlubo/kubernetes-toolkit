#!/usr/bin/env bash
cd /u01/tools/kubernetes-toolkit/k8s-worker || exit
./kube-proxy-init.sh
# ./kube-proxy-check.sh
