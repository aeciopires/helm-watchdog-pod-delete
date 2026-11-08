# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The section of each version is used as the release notes in
[GitHub Releases](https://github.com/aeciopires/helm-watchdog-pod-delete/releases) (`make release-notes`).

## [Unreleased]

## [1.0.0] - 2026-11-08

### Breaking changes

- Kubernetes **>= 1.34** is required (`kubeVersion: ">=1.34.0-0"` in `Chart.yaml`).
- The chart is built, tested and published with **Helm 4**. The chart keeps `apiVersion: v2`, so it can still be installed with Helm 3.
- The container runs as non-root (UID/GID `65534`), with read-only root filesystem, without privilege escalation and without Linux capabilities (Pod Security Standards `restricted`). If you overrode `podSecurityContext` or `securityContext`, review your values.
- `serviceAccount.automount` now defaults to `false`. The token is mounted explicitly by the `kube-api-access` projected volume (`volumes`/`volumeMounts`). If you removed that volume, set `serviceAccount.automount=true`.
- `image.tag` now defaults to `""` and uses `appVersion` of `Chart.yaml` (`1.37.2`).
- The ClusterRole and ClusterRoleBinding are named after the release fullname (before: ServiceAccount name) and are controlled by the new value `rbac.create` (before: `serviceAccount.create`).
- The namespace where the chart is installed is always excluded from monitoring.

### Added

- `rbac.create` value to create the ClusterRole/ClusterRoleBinding independently of `serviceAccount.create`.
- `tests.enabled` value and `helm test` hook that validates the RBAC permissions of the watchdog.
- `livenessProbe` and `readinessProbe` values (disabled by default).
- `values.schema.json` to validate the values (e.g. `checkInterval >= 1`, `errorStatuses` not empty).
- Timestamps and configuration summary in the watchdog logs.
- Chart published as OCI artifact in `oci://ghcr.io/aeciopires/helm-charts`, signed with cosign (keyless).
- `mise.toml` to install the same versions of the tools locally and in the CI.
- Root `Makefile` with `help`, `check-deps`, `install-deps`, tests, kind, ArgoCD and full stack targets.
- `examples/` with kind cluster (1 control-plane + 2 workers), ArgoCD Application and documentation to test everything locally.
- Tests: `helm lint`, unit tests (helm-unittest), `kubeconform` (Kubernetes 1.34 to 1.37), `shellcheck`, `actionlint`, `trivy` and end-to-end tests in kind (with Helm and with ArgoCD).
- `CHANGELOG.md`.

### Changed

- Default image updated to `alpine/kubectl:1.37.2`.
- CI runs only on Semantic Version tags and publishes the release only if all tests pass (static tests + e2e in Kubernetes 1.34, 1.35, 1.36 and 1.37).
- GitHub Actions pinned by commit SHA and with minimum permissions.
- Watchdog configuration is passed to the container as environment variables instead of being interpolated in the script.
- `kubectl delete pod` uses `--wait=false`, so a pod with finalizers does not block the loop.
- Added CPU limit and increased memory request to `32Mi`.
- Documentation updated (Helm 4, OCI, mise, local tests).
- The `Makefile` of `charts/helm-watchdog-pod-delete` was replaced by the `Makefile` in the root of the repository.

### Fixed

- `NOTES.txt` referenced `deploy/<release name>` instead of the real Deployment name.
- The watchdog did not handle `SIGTERM`, so every pod termination waited `terminationGracePeriodSeconds`.
- Empty `livenessProbe`/`readinessProbe` were rendered as `null`.
- ClusterRole name collision when `serviceAccount.create=false` (e.g. ClusterRole named `default`).
- RBAC was not created when using an existing ServiceAccount.
- The watchdog could delete pods of its own namespace when installed outside the namespace `helm-watchdog-pod-delete`.
- An empty `errorStatuses` would match and delete every pod (now rejected).
- Documentation mentioned the `bitnami/kubectl` image.

## [0.3.0] - 2025-10-28

### Changed

- Image changed from `bitnami/kubectl:1.32` to `alpine/kubectl:1.34.1`.
- Added verb `watch` on pods to the ClusterRole.

## [0.2.0] - 2025-03-22

### Added

- `watchdog.clusterRole.rules` value to customize the permissions of the watchdog.

### Changed

- ClusterRole reduced to `get`, `list`, `delete` and `watch` on pods and `get`, `list` on namespaces.
- Log message changed from "Recreating pod" to "Deleting pod".
- Improvements in documentation and ServiceAccount.

## [0.1.2] - 2025-03-21

### Changed

- Improvements in documentation of values and requirements.

## [0.1.1] - 2025-03-20

### Added

- Makefile and publication in Artifact Hub.

### Changed

- Removed `zora-system` from the default excluded namespaces.

## [0.1.0] - 2025-03-20

### Added

- First version of the chart.

[Unreleased]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/1.0.0...HEAD
[1.0.0]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/0.3.0...1.0.0
[0.3.0]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/0.1.2...0.2.0
[0.1.2]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/aeciopires/helm-watchdog-pod-delete/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/aeciopires/helm-watchdog-pod-delete/releases/tag/0.1.0
