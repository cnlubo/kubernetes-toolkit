#!/usr/bin/env bash

cd /opt/k8s/certs/admin || exit
openssl pkcs12 -export -out admin.pfx -inkey admin-key.pem -in admin.pem \
    -certfile /etc/kubernetes/cert/ca.pem
