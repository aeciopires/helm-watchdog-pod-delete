# helm-watchdog-pod-delete

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)

A Helm chart to delete pods with errors

# Prerequisites

- Install the kubectl, helm and helm-docs commands following the instructions of the file [REQUIREMENTS.md](../../REQUIREMENTS.md).

# Installing the Chart

- Access a Kubernetes cluster.

- Change the values according to the need of the environment in ``helm-watchdog-pod-delete/values.yaml`` file. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

- Clone this repository.

```bash
git clone https://github.com/aeciopires/helm-watchdog-pod-delete
cd helm-watchdog-pod-delete/charts/
```

- Test the installation with command:

```bash
helm upgrade --install helm-watchdog-pod-delete -f helm-watchdog-pod-delete/values.yaml helm-watchdog-pod-delete/ -n helm-watchdog-pod-delete --create-namespace --dry-run
```

- To install/upgrade the chart with the release name `helm-watchdog-pod-delete`:

```bash
helm upgrade --install helm-watchdog-pod-delete -f helm-watchdog-pod-delete/values.yaml helm-watchdog-pod-delete/ -n helm-watchdog-pod-delete --create-namespace
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

## Uninstalling the Chart

To uninstall/delete the `helm-watchdog-pod-delete` deployment:

```bash
helm uninstall helm-watchdog-pod-delete -n helm-watchdog-pod-delete
```

## Parameters

The following tables lists the configurable parameters of the chart and their default values.

Change the values according to the need of the environment in ``helm-watchdog-pod-delete/values.yaml`` file.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"bitnami/kubectl","tag":"1.32"}` | Image configuration. |
| image.pullPolicy | string | `"IfNotPresent"` | Pull policy image |
| image.repository | string | `"bitnami/kubectl"` | Image repository. |
| image.tag | string | `"1.32"` | Image tag. |
| imagePullSecrets | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` | Replica count. |
| resources.limits.memory | string | `"128Mi"` |  |
| resources.requests.cpu | string | `"50m"` |  |
| resources.requests.memory | string | `"10Mi"` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.automount | bool | `true` | Automatically mount a ServiceAccount's API credentials? |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| terminationGracePeriodSeconds | int | `30` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[{"mountPath":"/var/run/secrets/kubernetes.io/serviceaccount","name":"kube-api-access","readOnly":true}]` | Additional volumeMounts on the output Deployment definition. |
| volumes | list | `[{"name":"kube-api-access","projected":{"sources":[{"serviceAccountToken":{"path":"token"}},{"configMap":{"items":[{"key":"ca.crt","path":"ca.crt"}],"name":"kube-root-ca.crt"}}]}}]` | Additional volumes on the output Deployment definition. |
| watchdog | object | `{"checkInterval":120,"errorStatuses":"CrashLoopBackOff|Error|OOMKilled","excludeNamespaces":["default","zora-system","helm-watchdog-pod-delete","kube-system","kube-node-lease","kube-public","gke-managed-cim","gke-managed-filestorecsi","gke-managed-system","gmp-public","gmp-system"],"namespaces":[]}` | Watchdog configuration. |
| watchdog.checkInterval | int | `120` | Interval in seconds to check pods. |
| watchdog.errorStatuses | string | `"CrashLoopBackOff|Error|OOMKilled"` | List of error pod statuses. |
| watchdog.excludeNamespaces | list | `["default","zora-system","helm-watchdog-pod-delete","kube-system","kube-node-lease","kube-public","gke-managed-cim","gke-managed-filestorecsi","gke-managed-system","gmp-public","gmp-system"]` | List of namespaces that should be ignored |
| watchdog.namespaces | list | `[]` | List of namespaces to monitor. If empty, monitor all. |
