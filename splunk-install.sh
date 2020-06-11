#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SPLUNK_NAMESPACE=splunk

HELM_CHART_URL="https://github.com/slugstack/splunk-helm-chart"
HELM_CHART_NAME=splunk

SPLUNK_USERNAME="admin"
SPLUNK_PASSWORD="admin123"
SPLUNK_OPENSHIFT_INDEX="openshift"
SPLUNK_HEC_TOKEN="splunk_hec_token"

# Check if OpenShift cli tool is installed
command -v oc >/dev/null 2>&1 || { echo >&2 "OpenShift CLI is required but not installed.  Aborting."; exit 1; } 

# Check if Git is installed
command -v git >/dev/null 2>&1 || { echo >&2 "Git is required but not installed.  Aborting."; exit 1; } 

# Check if Git is installed
command -v helm >/dev/null 2>&1 || { echo >&2 "Helm is required but not installed.  Aborting."; exit 1; } 

oc apply -f ${DIR}/splunk/resources

# Helm Install
if [ ! -d "${DIR}/splunk/helm/charts/splunk-helm-chart" ]; then
  echo "Cloning Helm Chart"
  git clone ${HELM_CHART_URL} ${DIR}/splunk/helm/charts/splunk-helm-chart
fi

cp -f ${DIR}/splunk/helm/route.yaml ${DIR}/splunk/helm/charts/splunk-helm-chart/splunk/templates/

helm upgrade --namespace ${SPLUNK_NAMESPACE} --install -f splunk/helm/splunk_install.yaml ${HELM_CHART_NAME} splunk/helm/splunk-helm-chart/splunk

oc patch -n ${SPLUNK_NAMESPACE} deployment/${HELM_CHART_NAME} --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env/-", "value":  { "name": "SPLUNK_LAUNCH_CONF", "value": "OPTIMISTIC_ABOUT_FILE_LOCKING=1" }  }]'
oc patch -n ${SPLUNK_NAMESPACE} deployment/${HELM_CHART_NAME} --type='json' -p="[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/env/-\", \"value\":  { \"name\": \"SPLUNK_PASSWORD\", \"value\": \"${SPLUNK_PASSWORD}\" }  }]"

sleep 5

SPLUNK_ROUTE=https://$(oc get routes $HELM_CHART_NAME -n ${SPLUNK_NAMESPACE} -o jsonpath={.spec.host})

echo "Waiting for Splunk to become active"
until $(curl -fLk --silent --output /dev/null ${SPLUNK_ROUTE}); do sleep 2; done

SPLUNK_POD=$(oc get -n ${SPLUNK_NAMESPACE} pods -l=app.kubernetes.io/name=splunk -o jsonpath='{.items[-1:].metadata.name}')

OPENSHIFT_INDEX_CREATED=$(oc -n ${SPLUNK_NAMESPACE} exec ${SPLUNK_POD} -- curl -ks -u ${SPLUNK_USERNAME}:${SPLUNK_PASSWORD} -o /dev/null -w "%{http_code}" https://localhost:8089/services/data/indexes/${SPLUNK_OPENSHIFT_INDEX})

if [ ${OPENSHIFT_INDEX_CREATED} -eq 404 ]; then
  echo "Creating OpenShift Index"
  oc exec -n ${SPLUNK_NAMESPACE} ${SPLUNK_POD} -- curl -ks -u ${SPLUNK_USERNAME}:${SPLUNK_PASSWORD} -o /dev/null https://localhost:8089/services/data/indexes -d name=${SPLUNK_OPENSHIFT_INDEX} -d datatype=event
fi

oc exec -n ${SPLUNK_NAMESPACE} ${SPLUNK_POD} -- curl -ks -u ${SPLUNK_USERNAME}:${SPLUNK_PASSWORD} -o /dev/null https://localhost:8089/servicesNS/admin/splunk_httpinput/data/inputs/http/${SPLUNK_HEC_TOKEN} -d indexes=${SPLUNK_OPENSHIFT_INDEX} -d index=${SPLUNK_OPENSHIFT_INDEX}
