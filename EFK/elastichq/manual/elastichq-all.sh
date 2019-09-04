#!/usr/bin/env bash
./ingress/gen-es-hq-secret.sh
./ingress/gen-es-hq-ingress.sh
./install-elastichq.sh
