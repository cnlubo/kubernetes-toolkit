#!/usr/bin/env bash
cd /opt/k8s/addons/coredns/test || exit
#kubectl delete -f pod-nginx.yaml
kubectl delete -f dnsutils-ds.yml
kubectl delete -f my-nginx.yaml
kubectl delete service my-nginx
