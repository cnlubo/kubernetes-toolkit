#!/usr/bin/env bash

cd /u01/tools/kubernetes-toolkit/k8s-master/HA || exit
./haproxy-init.sh
./haproxy-check.sh
