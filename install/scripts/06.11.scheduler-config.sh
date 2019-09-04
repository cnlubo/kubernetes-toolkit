#!/usr/bin/env bash

cd /u01/tools/kubernetes-toolkit/k8s-master || exit
./scheduler-init.sh
./scheduler-check.sh
