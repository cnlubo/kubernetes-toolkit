#!/usr/bin/env bash
# 启动repo服务
helm_path=$(which helm)
helm_pid=$(sudo pidof $helm_path)
helm_data_path="/opt/k8s/helm/charts"
[ ! -d $helm_data_path ] && mkdir -p $helm_data_path
if [ -z "$helm_pid" ]; then
    cd $helm_data_path || exit
    nohup $helm_path serve --address 0.0.0.0:8879 --repo-path $helm_data_path >/dev/null 2>log &
else
    echo -e "helm already running."
fi
exit 0
