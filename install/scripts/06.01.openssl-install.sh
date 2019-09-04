#!/usr/bin/env bash
# shellcheck disable=SC1083
mclusters bt {k8s} "chmod +x /u01/tools/kubernetes-toolkit/centos/openssl.sh"
mclusters bt {k8s} "/u01/tools/kubernetes-toolkit/centos/openssl.sh"
