OpenShift Log Forwarding to Splunk
==================================

This repository contains assets to forward container logs from an OpenShift Container Platform 4.3+ to Splunk.

## Overview

OpenShift contains a container log aggregation feature built on the ElasticSearch, Fluentd and Kibana (EFK) stack. Support is available (Tech Preview as of 4.3/4.4) to send logs generated on the platform to external targets using the Fluentd forwarder feature with output in Splunk using the HTTP Event Collector (HEC). 

The assets contained in this repository support demonstrating this functionality by establishing a non persistent deployment of Splunk to OpenShift in a namespace called `splunk` and sending application container logs to an index in Splunk called `openshift`.

## Prerequisites

The following prerequisites must be satisfied prior to deploying this integration

* OpenShift Container Platform 4.3 with Administrative access
* Base Cluster logging installed
* Tools
  * OpenShift Command Line Tool
  * Git
  * Helm
  * OpenSSL

## Installation and Deployment

With all of the prerequisites met, execute the following commands to deploy the solution:

1. Login to OpenShift with a user with `cluster-admin` permissions
2. Deploy Splunk

```
$ ./splunk-install.sh
```

3. Deploy log forwarding solution

```
$ ./deploy-log-forwarding.sh
```

4. Verify that you can view logs in Splunk

   1. Login to Splunk by first accessing the Splunk route

   ```
   $ echo "https://$(oc get routes -n splunk splunk -o jsonpath='{.spec.host}')"
   ```

   2. Search for OpenShift logs in the `openshift` namespace

   Search Query: `index=openshift`

## Future State

The following list of items are intended to be incorporated in the future

* Conversion of Log Forwarding from Kustomize based solution to Helm