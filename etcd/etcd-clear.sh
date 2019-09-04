#!/bin/bash
# shellcheck disable=SC1083
# clean etcd

# stop etcd service
mclusters bt {k8s} "sudo systemctl stop etcd && sudo systemctl disable etcd"

# cleanup files
# 删除 etcd 的工作目录和数据目录
mclusters bt {k8s} "sudo rm -rf /data/k8s/etcd"
# 删除 systemd unit 文件
mclusters bt {k8s} "sudo rm -rf /etc/systemd/system/etcd.service"
# 删除程序文件
mclusters bt {k8s} "sudo rm -rf /opt/k8s/bin/etcd*"
# 删除 x509 证书文件
mclusters bt {k8s} "sudo rm -rf /etc/etcd/cert/*"
