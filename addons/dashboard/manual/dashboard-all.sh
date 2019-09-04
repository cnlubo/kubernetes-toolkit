#!/usr/bin/env bash
./dashboard-install.sh
#./gen-dashboard-csr.sh
./ingress/gen-dashboard-secret.sh
./ingress/gen-dashboard-ingress.sh
