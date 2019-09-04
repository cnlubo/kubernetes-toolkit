#!/usr/bin/bash
###
# @Author: cnak47
# @Date: 2019-07-10 11:10:03
 # @LastEditors: cnak47
 # @LastEditTime: 2019-08-13 16:47:20
# @Description:
###

# shellcheck disable=SC2034
# shellcheck disable=SC1091
source environment.sh
for node_ip in "${NODE_IPS[@]}"; do
    echo ">>> ${node_ip}"
    # shellcheck disable=SC2154
    scp environment.sh "$k8s_user@${node_ip}":/opt/k8s/bin/
done
# shellcheck disable=SC1083
mclusters bt {k8s} "sudo chmod +x /opt/k8s/bin/*"
