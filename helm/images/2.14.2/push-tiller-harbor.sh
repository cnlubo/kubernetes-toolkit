#!/bin/bash
# harbor_host=10.0.1.24
# my_registry=$harbor_host/k8s
# docker login $harbor_host
# docker tag gcr.io/kubernetes-helm/tiller:v2.12.1 \
#     ${my_registry}/gcr-io-tiller:v2.12.1
# docker push ${my_registry}/gcr-io-tiller:v2.12.1
#!/bin/bash
echo ""
echo "=========================================================="
echo "Push Extra Images into local harbor k8s ......"
echo " helm tiller "
echo "=========================================================="
echo ""
echo "docker tag to harbor k8s ..."
harbor_host=10.0.1.24:1443
my_registry=$harbor_host/k8s
docker login $harbor_host
docker tag gcr.io/kubernetes-helm/tiller:v2.14.2 ${my_registry}/gcr-io-kubernetes-helm-tiller:v2.14.2
echo ""
echo "=========================================================="
echo "push images into harbor ..... "
echo ""
docker push ${my_registry}/gcr-io-kubernetes-helm-tiller:v2.14.2
echo ""
echo "=========================================================="
echo "Push Images FINISHED."
echo "=========================================================="

echo ""
