#!/usr/bin/env bash
cd /u01/tools/kubernetes-toolkit/helm || exit
./get-helm-cert.sh
./helm-install.sh
./helm-init.sh
./helm-client-init.sh
