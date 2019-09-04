#!/usr/bin/bash
# shellcheck disable=SC2034
###
# @Author: cnak47
# @Date: 2019-07-10 09:33:08
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-15 10:17:52
# @Description:
###

export k8s_user="ak47"
# 生成 EncryptionConfig 所需的加密 key
ENCRYPTION_KEY=$(/usr/bin/head -c 32 /dev/urandom | base64)
export ENCRYPTION_KEY

# 集群各机器 IP
export NODE_IPS=(10.0.1.17 10.0.1.24 10.0.1.30)
# 集群各 IP 对应的 主机名
export NODE_NAMES=(k8s-node1 k8s-node3 k8s-node4)

# ===============ETCD============================================
ETCD_0=10.0.1.17
ETCD_1=10.0.1.24
ETCD_2=10.0.1.30
# 当前etcd部署的机器名称
# 随便定义,只要能区分不同机器即可
# etcd集群所有机器 IP
export ETCD_NODE_IPS=("${ETCD_0}" "${ETCD_1}" "${ETCD_2}")
export ETCD_NODE_NAMES=(k8s-node1 k8s-node3 k8s-node4)

# etcd 集群间通信的 IP 和端口
export ETCD_NODES=k8s-node1=https://${ETCD_0}:2380,k8s-node3=https://${ETCD_1}:2380,k8s-node4=https://${ETCD_2}:2380
# etcd 集群服务地址列表
export ETCD_ENDPOINTS="https://${ETCD_0}:2379,https://${ETCD_1}:2379,https://${ETCD_2}:2379"
# etcd 数据目录
export ETCD_DATA_DIR="/data/etcd/data"
# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR="/data/etcd/wal"
# ===============ETCD===============================================
# k8s 各组件数据目录
export K8S_DIR="/data/k8s"
# docker 数据目录
export DOCKER_DIR="/data/docker"

## 以下参数一般不需要修改
# TLS Bootstrapping 使用的 Token
#可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
BOOTSTRAP_TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"
# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段

# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
export SERVICE_CIDR="10.254.0.0/16"

# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
export CLUSTER_CIDR="172.30.0.0/16"

# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"

# flanneld 网络配置前缀
export FLANNEL_ETCD_PREFIX="/kubernetes/network"

# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.254.0.1"

# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配)
export CLUSTER_DNS_SVC_IP="10.254.0.2"

# 集群 DNS 域名(末尾不带点号)
export CLUSTER_DNS_DOMAIN="cluster.local"
# 将二进制目录 /opt/k8s/bin 加到 PATH 中
export PATH=/opt/k8s/bin:$PATH

#=========== master 集群 =================================
MASTER_1=10.0.1.17
MASTER_2=10.0.1.24
MASTER_3=10.0.1.30
# master集群各机器IP
export MASTER_IPS=("${MASTER_1}" "${MASTER_2}" "${MASTER_3}")
# 集群各IP对应的主机名数组
export MASTER_NAMES=(k8s-node1 k8s-node3 k8s-node4)
#=========== master 集群 =================================
# kube-apiserver 的 VIP（HA 组件 keepalived 发布的 IP）
export MASTER_VIP=10.0.1.253
# HA 节点，配置 VIP 的网络接口名称
# export VIP_IF="eth0"
export MASTER_VIP_IF="enp12s0"
export BACKUP_VIP_IF="p4p1"
export BACKUP1_VIP_IF="ens33"
# keepalived master server ip
export KEEP_MASTER_IP=10.0.1.24
# keepalived backup servers ip
export KEEP_BACKUP_IPS=(10.0.1.17 10.0.1.30)
export KEEP_BACKUP_IP=10.0.1.17
export KEEP_BACKUP1_IP=10.0.1.30
# ===============worker cluster ===============================================
WORKER_1=10.0.1.17
WORKER_2=10.0.1.24
WORKER_3=10.0.1.30
# WORKER集群各机器IP数组
export WORKER_IPS=("${WORKER_1}" "${WORKER_2}" "${WORKER_3}")
# 集群各IP对应的主机名数组
export WORKER_NAMES=(k8s-node1 k8s-node3 k8s-node4)

# kube-apiserver VIP 地址（HA 组件 haproxy 监听 8443 端口）
export KUBE_APISERVER="https://${MASTER_VIP}:8443"
# ==================edgenode===================================================
# 边缘节点标签
edgenode_label="edgenode"
# 边缘节点数量
edgenode_counts=2
edgenode_0=10.0.1.24
edgenode_1=10.0.1.17
egenode_vip=10.0.1.254

# 边缘节点 各机器ip
export EDGENODE_IPS=("${edgenode_0}" "${edgenode_1}")
# 边缘节点各IP对应的主机名数组
export EDGENODE_NAMES=(k8s-node3 k8s-node1)

# ===============================harbor=========================================
harbor_node_ip=10.0.1.30
harbor_https_port=1443
harbor_http_port=8880
# ============================= NFS =============================================
nfs_server_ip=10.0.1.17
nfs_server_name=k8s-node1
nfs_data="/nfs_data"
nfs_ips="10.0.1.0/24"
nfs_client_1=10.0.1.30
nfs_client_2=10.0.1.24
# nfc client各机器IP
export NFS_CLIENT_IPS=("${nfs_client_1}" "${nfs_client_2}")
export NFS_CLIENT_NAMES=(k8s-node4 k8s-node3)
