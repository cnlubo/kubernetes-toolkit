#!/usr/bin/env bash

./get-etcd-cert.sh
./get-flanneld-cert.sh
# kubelet cert
./get-admin-cert.sh
# master cert
./get-kubernetes-cert.sh
./get-controller-manager-cert.sh
./get-kube-scheduler-cert.sh
# node cert
./get-proxy-cert.sh
