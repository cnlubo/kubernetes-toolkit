#!/usr/bin/env bash
cd /u01/tools/kubernetes-toolkit/k8s-worker || exit
./docker-yum-install.sh
./docker-init.sh
./docker-check.sh
./docker-compose-install.sh
