#!/usr/bin/env bash

cd /u01/tools/kubernetes-toolkit/k8s-master || exit
./controller-manager-init.sh
./controller-manager-check.sh
