#!/usr/bin/env bash
# all node cert
./de-flanneld-cert.sh
# etcd cert
./de-etcd-cert.sh
# master node cert
./de-controller-manager-cert.sh
./de-kubernetes-cert.sh
