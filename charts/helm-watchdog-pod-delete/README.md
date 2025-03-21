# helm-watchdog-pod-delete

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square)  [![Downloads](https://img.shields.io/github/downloads/aeciopires/helm-watchdog-pod-delete/total?label=Downloads%20All%20Releases
)](https://tooomm.github.io/github-release-stats/?username=aeciopires&repository=helm-watchdog-pod-delete)

A Helm chart to delete pods with errors

# Table of Contents
<!-- TOC -->

- [helm-watchdog-pod-delete](#helm-watchdog-pod-delete)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Installing the Chart](#installing-the-chart)
  - [Grant Identity Permissions in GKE (Workload Identity)](#grant-identity-permissions-in-gke-workload-identity)
- [Uninstalling the Chart](#uninstalling-the-chart)
- [Changelog](#changelog)
- [Motivation and use cases](#motivation-and-use-cases)
  - [Problem Statement](#problem-statement)
  - [Solution](#solution)
  - [Use Cases](#use-cases)
- [How It Works](#how-it-works)
- [Parameters](#parameters)

<!-- TOC -->

# Prerequisites

- Install the kubectl, helm and helm-docs commands following the instructions of the file [REQUIREMENTS.md](../../REQUIREMENTS.md).

# Installing the Chart

- Access a Kubernetes cluster.

- Change the values according to the need of the environment in ``helm-watchdog-pod-delete/values.yaml`` file. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

Add Helm repository:

```bash
helm repo add helm-watchdog-pod-delete https://aeciopires.github.io/helm-watchdog-pod-delete
```

Update the list helm charts available for installation. This is recommend prior to installation/upgrade:

```bash
helm repo update
```

Get all versions of helm chart:

```bash
helm search repo helm-watchdog-pod-delete/helm-watchdog-pod-delete -l
```

- Test the installation with command:

```bash
helm upgrade --install helm-watchdog-pod-delete -f values.yaml helm-watchdog-pod-delete/helm-watchdog-pod-delete -n helm-watchdog-pod-delete --create-namespace --dry-run
```

- To install/upgrade the chart with the release name `helm-watchdog-pod-delete`:

```bash
helm upgrade --install helm-watchdog-pod-delete -f values.yaml helm-watchdog-pod-delete/helm-watchdog-pod-delete -n helm-watchdog-pod-delete --create-namespace
```

See logs of pod with the follow command:

```bash
kubectl logs -f deploy/helm-watchdog-pod-delete -n helm-watchdog-pod-delete
```

## Grant Identity Permissions in GKE (Workload Identity)

In GKE, access to the cluster may be managed by Workload Identity (instead of the default Kubernetes ServiceAccounts).

To fix this:

- Enable Workload Identity (if required)
- If Workload Identity is enabled in GKE, the Kubernetes ServiceAccount must be linked to a Google Cloud ServiceAccount:

```bash
# Link the Kubernetes ServiceAccount to the GCP ServiceAccount
gcloud iam service-accounts add-iam-policy-binding \
GCP_SERVICE_ACCOUNT@PROJECT.iam.gserviceaccount.com \
--role roles/iam.workloadIdentityUser \
--member "serviceAccount:PROJECT.svc.id.goog[helm-watchdog-pod-delete/helm-watchdog-pod-delete]"
```

- Replace:
  - GCP_SERVICE_ACCOUNT with the Google Cloud ServiceAccount.
  - PROJECT with your project ID.

- This allows the container to use correct credentials within the cluster.

# Uninstalling the Chart

To uninstall/delete the `helm-watchdog-pod-delete` deployment:

```bash
helm uninstall helm-watchdog-pod-delete -n helm-watchdog-pod-delete
```

# Changelog

See https://github.com/aeciopires/helm-watchdog-pod-delete/releases

# Motivation and use cases

## Problem Statement

In Kubernetes, applications running as Pods may sometimes enter an undesired state such as ``CrashLoopBackOff`` or ``Error``. This can happen due to various reasons like memory leaks, unhandled exceptions, or external dependencies failing.

By default, Kubernetes restarts **containers** inside a Pod but does not recreate the entire **Pod** itself. This can lead to issues where the Pod remains stuck in a broken state and requires manual intervention.

Additionally, ``sidecars`` and ``initContainers`` can introduce challenges:

- ``Sidecar containers`` may fail, but Kubernetes only restarts the main application container, leaving the Pod in a partially functional state.
- ``InitContainers`` run only during Pod creation, so if they depend on external services that were unavailable at the time, the Pod can become stuck.
- ``Race conditions with external dependencies`` (e.g., external secrets, databases, message brokers, or API services) may cause startup failures that require a full Pod restart.

## Solution

The **Helm Watchdog Pod Restart** is a lightweight monitoring solution that:

- Periodically monitors all Pods in specified namespaces.
- Detects Pods that are in a CrashLoopBackOff or Error state.
- Automatically deletes these Pods, triggering a fresh restart.
- Supports monitoring all namespaces or a specific list of namespaces.
- Allows excluding certain namespaces (e.g., kube-system, monitoring).
- Ensures sidecar containers and initContainers are properly restarted when needed.
- Helps mitigate race conditions by ensuring Pods are recreated when external dependencies become available.
- Runs as a Kubernetes Deployment using a bitnami/kubectl container.
- Uses Helm for easy deployment and configuration.

## Use Cases

This solution is useful for:

- Ensuring high availability of applications by automatically recovering failed Pods.
- Reducing manual intervention, avoiding the need for SREs/DevOps engineers to manually restart Pods.
- Handling intermittent failures in microservices-based architectures.
- Automating Pod recovery in multi-tenant clusters where different teams manage different namespaces.
- Fixing issues with ``sidecars`` and ``initContainers`` by ensuring Pods are fully restarted instead of remaining in a partially functional state.
- Resolving race conditions caused by unavailable external dependencies at startup, ensuring that Pods retry initialization when dependencies are ready.

# How It Works

The watchdog runs as a single Deployment in Kubernetes.

It continuously checks for Pods in a CrashLoopBackOff or Error state.

When it finds a failed Pod, it deletes it, allowing Kubernetes to schedule a new Pod (if managed by ReplicaSet, Deployment, DemonSet or StatefulSet).

The monitoring interval and namespace filtering can be configured via Helm values.

# Parameters

The following tables lists the configurable parameters of the chart and their default values.

Change the values according to the need of the environment in ``helm-watchdog-pod-delete/values.yaml`` file.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity configurations. Reference: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| fullnameOverride | string | `""` | Completely replaces the rest of the logic in the template. Reference: https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"bitnami/kubectl","tag":"1.32"}` | Image configuration. |
| image.pullPolicy | string | `"IfNotPresent"` | Pull policy image |
| image.repository | string | `"bitnami/kubectl"` | Image repository. |
| image.tag | string | `"1.32"` | Image tag. |
| imagePullSecrets | list | `[]` | Reference to one or more secrets to be used when pulling images.  For example:  imagePullSecrets:    - name: "image-pull-secret" |
| nameOverride | string | `""` | Replaces the name of the chart in the Chart.yaml file, when this is used to construct Kubernetes object names. Reference: https://stackoverflow.com/questions/63838705/what-is-the-difference-between-fullnameoverride-and-nameoverride-in-helm |
| nodeSelector | object | `{}` | nodeSelector configurations. Reference: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ |
| podAnnotations | object | `{}` | Annotations to add to the pods |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{}` | Pod security configurations |
| replicaCount | int | `1` | Replica count. |
| resources | object | `{"limits":{"memory":"128Mi"},"requests":{"cpu":"50m","memory":"10Mi"}}` | Resource requests and limits for the pod |
| securityContext | object | `{}` | Security Context configurations. Reference: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| terminationGracePeriodSeconds | int | `30` | Time to wait pod delete. Reference: https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-terminating-with-grace |
| tolerations | list | `[]` | Tolerations configurations. Reference: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| volumeMounts | list | `[{"mountPath":"/var/run/secrets/kubernetes.io/serviceaccount","name":"kube-api-access","readOnly":true}]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[{"name":"kube-api-access","projected":{"sources":[{"serviceAccountToken":{"path":"token"}},{"configMap":{"items":[{"key":"ca.crt","path":"ca.crt"}],"name":"kube-root-ca.crt"}}]}}]` | Additional volumes on the output Deployment definition. |
| watchdog | object | `{"checkInterval":120,"errorStatuses":"CrashLoopBackOff|Error|OOMKilled","excludeNamespaces":["default","helm-watchdog-pod-delete","kube-system","kube-node-lease","kube-public","gke-managed-cim","gke-managed-filestorecsi","gke-managed-system","gmp-public","gmp-system"],"namespaces":[]}` | Watchdog configuration. |
| watchdog.checkInterval | int | `120` | Interval in seconds to check pods. |
| watchdog.errorStatuses | string | `"CrashLoopBackOff|Error|OOMKilled"` | List of error pod statuses. |
| watchdog.excludeNamespaces | list | `["default","helm-watchdog-pod-delete","kube-system","kube-node-lease","kube-public","gke-managed-cim","gke-managed-filestorecsi","gke-managed-system","gmp-public","gmp-system"]` | List of namespaces that should be ignored |
| watchdog.namespaces | list | `[]` | List of namespaces to monitor. If empty, monitor all. |
