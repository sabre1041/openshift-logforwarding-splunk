#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

OVERLAY=${OVERLAY:-default}

if [ ! -f "${DIR}/log-forwarding/overlays/${OVERLAY}/server.crt" ]; then
  echo "Creating Log Forwarding Certificate"
  openssl req -x509 -newkey rsa:4096 -keyout "${DIR}/log-forwarding/overlays/${OVERLAY}/server.key" -out "${DIR}/log-forwarding/overlays/${OVERLAY}/server.crt" -nodes -days 365 -subj '/CN=log-forwarding-splunk.svc' 
fi

oc apply -k "${DIR}/log-forwarding/overlays/${OVERLAY}/"