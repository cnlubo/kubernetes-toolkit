#!/usr/bin/env bash
cd /opt/k8s/addons/heapster || exit
kubectl delete -f .

# kubectl get sa/heapster --namespace kube-system
# kubectl get clusterrolebindings/heapster-kubelet-api --namespace kube-system
# kubectl delete sa/heapster --namespace kube-system
# kubectl delete clusterrolebindings/heapster-kubelet-api --namespace kube-system
# kubectl --namespace kube-system delete svc,deployment,rc,rs -l task=monitoring
