OpenShift Log Forwarding to Splunk
==================================

This repository contains assets to forward container logs from an OpenShift Container Platform 4.3+ to Splunk.

## Overview

OpenShift contains a container [log aggregation feature](https://docs.openshift.com/container-platform/4.4/logging/config/cluster-logging-external.html) built on the ElasticSearch, Fluentd and Kibana (EFK) stack. Support is available (Tech Preview as of 4.3/4.4) to send logs generated on the platform to external targets using the Fluentd forwarder feature with output in Splunk using the HTTP Event Collector (HEC). 

The assets contained in this repository support demonstrating this functionality by establishing a non persistent deployment of Splunk to OpenShift in a namespace called `splunk` and sending application container logs to an index in Splunk called `openshift`.

## Prerequisites

The following prerequisites must be satisfied prior to deploying this integration

* OpenShift Container Platform 4.3 with Administrative access
* Base Cluster logging installed
* Tools
  * OpenShift Command Line Tool
  * [Git](https://git-scm.com/)
  * [Helm](https://helm.s/)
  * [OpenSSL](https://www.openssl.org) (Optional)

## Components

The primary assets contained within this repository is a Helm Chart to deploy LogForwarding. Please refer to the [values.yaml](charts/openshift-logforwarding-splunk/values.yaml) file for the customizing the installation. 

### SSL Communication

#### Fluentd

By default, SSL communication between the platform deployed Fluentd instances and the LogForwarding instance is not enabled It can be enabled by setting the `forwarding.fluentd.ssl=true` value. A default certificate and private key is available for use by default (CN=openshift-logforwarding-splunk.openshift-logging.svc). Otherwise, certificates can be provided by setting the `forwarding.fluentd.caFile` and `forwarding.fluentd.keyFile` to a path relative to the chart.

#### Splunk

Communication between the Fluentd Forwarder and Splunk can be exchanged using certificates. The certificate file can be referenced by setting the `forwarding.splunk.caFile` value.

By default, certificate verification is disabled between the two components. It can be enabled by specifying `forwarding.splunk.insecure=false`

## Splunk HEC Token

A HEC token is used to communicate between the Fluentd forwarder and Splunk. It is required and can be provided in the `forwarding.splunk.token` value.

## Installation and Deployment

With all of the prerequisites met and an overview of the components provided in this repository, execute the following commands to deploy the solution:

1. Login to OpenShift with a user with `cluster-admin` permissions
2. Deploy Splunk

```
$ ./splunk-install.sh
```

3. Deploy the log forwarding Helm chart by providing the value of the HEC token along with any additional values

```
$ helm install --namespace=openshift-logging openshift-logforwarding-splunk charts/openshift-logforwarding-splunk/ --set forwarding.splunk.token=<token>
```

4. Annotate the `ClusterLogging` instance

```
$ oc annotate clusterlogging -n openshift-logging instance clusterlogging.openshift.io/logforwardingtechpreview=enabled
```

5. Verify that you can view logs in Splunk

   1. Login to Splunk by first accessing the Splunk route

   ```
   $ echo "https://$(oc get routes -n splunk splunk -o jsonpath='{.spec.host}')"
   ```

   2. Search for OpenShift logs in the `openshift` namespace

   Search Query: `index=openshift`

