#!/usr/bin/env bash
cd /u01/tools/kubernetes-toolkit/addons/coredns || exit
./coredns-install.sh
./coredns-check.sh
