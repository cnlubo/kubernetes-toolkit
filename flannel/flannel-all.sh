#!/usr/bin/env bash
# shellcheck disable=SC1083
./flannel-install.sh
./flannel-cert.sh
./flannel-init.sh
# 重要:只需要执行一次
./write-etcd.sh

# info "start every node flanneld services ..... "
mclusters bt {k8s} "sudo systemctl daemon-reload && sudo systemctl enable flanneld && sudo systemctl restart flanneld"
./flannel-check.sh
