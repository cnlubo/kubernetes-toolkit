#!/usr/bin/env bash

cd /u01/tools/kubernetes-toolkit/k8s-master/HA || exit
./keepalived-init.sh
./keepalived-check.sh
