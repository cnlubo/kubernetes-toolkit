#!/usr/bin/env bash

cd /u01/tools/kubernetes-toolkit/k8s-master || exit
./apiserver-init.sh
./apiserver-check.sh
