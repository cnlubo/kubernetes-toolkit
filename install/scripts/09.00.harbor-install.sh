#!/usr/bin/env bash
cd /u01/tools/kubernetes-toolkit/harbor || exit
./get-harbor-cert.sh
./harbor-install.sh
./docker-client-init.sh
