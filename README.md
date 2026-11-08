# helm-watchdog-pod-delete

[![License](https://img.shields.io/badge/license-GPLv3-blue)](https://opensource.org/license/gpl-3-0) ![Kubernetes: >=1.34](https://img.shields.io/badge/Kubernetes-%3E%3D1.34-informational) ![Helm: 4](https://img.shields.io/badge/Helm-4-informational) [![Release Chart](https://github.com/aeciopires/helm-watchdog-pod-delete/actions/workflows/release.yml/badge.svg)](https://github.com/aeciopires/helm-watchdog-pod-delete/actions/workflows/release.yml) [![Downloads](https://img.shields.io/github/downloads/aeciopires/helm-watchdog-pod-delete/total?label=Downloads%20All%20Releases
)](https://tooomm.github.io/github-release-stats/?username=aeciopires&repository=helm-watchdog-pod-delete)

<!-- TOC -->

- [helm-watchdog-pod-delete](#helm-watchdog-pod-delete)
  - [About](#about)
  - [Quick start](#quick-start)
  - [Testing locally](#testing-locally)
  - [Contributing](#contributing)
  - [Important links](#important-links)
  - [Contributors](#contributors)
  - [Maintainers](#maintainers)
  - [License](#license)

<!-- TOC -->

## About

Helm chart to delete pods with errors

Helm chart that periodically deletes pods with errors (e.g. `CrashLoopBackOff`, `Error`, `OOMKilled`), so their controllers can recreate them.

- Supports Kubernetes >= 1.34.
- Built, tested and published with Helm 4.
- Published in the OCI registry `oci://ghcr.io/aeciopires/helm-charts` (signed with cosign) and in the Helm repository `https://aeciopires.github.io/helm-watchdog-pod-delete`.
- Follows [Semantic Versioning](https://semver.org). See [CHANGELOG.md](CHANGELOG.md).

See more information in [charts/helm-watchdog-pod-delete/README.md](charts/helm-watchdog-pod-delete/README.md)

## Quick start

```bash
helm upgrade --install helm-watchdog-pod-delete \
  oci://ghcr.io/aeciopires/helm-charts/helm-watchdog-pod-delete \
  -n helm-watchdog-pod-delete --create-namespace
```

## Testing locally

The tools are managed by [mise](https://mise.jdx.dev) ([mise.toml](mise.toml)) and every task is in the [Makefile](Makefile):

```bash
make help           # list all targets
make install-deps   # install mise, the tools and the helm-unittest plugin
make check-deps     # check the dependencies
make test           # static tests (the same executed by the CI)
make stack-up       # kind (3 nodes) + ArgoCD + local chart deployed by ArgoCD
make stack-down     # remove everything
```

See [examples/README.md](examples/README.md) to test everything locally (kind + ArgoCD + Helm).

## Contributing

1. See [CONTRIBUTING.md](CONTRIBUTING.md) file.
2. See [REQUIREMENTS.md](REQUIREMENTS.md) file.

## Important links

- Open issue, bug or feature request: https://github.com/aeciopires/helm-watchdog-pod-delete/issues
- Ask help: https://github.com/aeciopires/helm-watchdog-pod-delete/discussions
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Releases: https://github.com/aeciopires/helm-watchdog-pod-delete/releases
- OCI registry: https://github.com/aeciopires/helm-watchdog-pod-delete/pkgs/container/helm-charts%2Fhelm-watchdog-pod-delete
- Artifact Hub: https://artifacthub.io/packages/helm/helm-watchdog-pod-delete/helm-watchdog-pod-delete
- Closed issues: https://github.com/aeciopires/helm-watchdog-pod-delete/issues?q=is%3Aissue+is%3Aclosed
- Closed PRs: https://github.com/aeciopires/helm-watchdog-pod-delete/pulls?q=is%3Apr+is%3Aclosed
- Download statistics: https://tooomm.github.io/github-release-stats/?username=aeciopires&repository=helm-watchdog-pod-delete

## Contributors

<a href = "https://github.com/aeciopires/helm-watchdog-pod-delete/graphs/contributors">
  <img src = "https://contrib.rocks/image?repo=aeciopires/helm-watchdog-pod-delete"/>
</a>

Made with [contributors-img](https://contrib.rocks).

<!-- Reference: https://github.com/Tanu-N-Prabhu/myWebsite.io/blob/master/Docs/Displaying%20Contributors%20Image%20on%20README%20files%20with%20no%20Pain!.md#contributors-displayed-by-using-contributors-img-on-the-readmemd-file -->

## Maintainers

- Aécio dos Santos Pires ([linkedin.com/in/aeciopires](https://www.linkedin.com/in/aeciopires))

## License

GPL-3.0 Aécio dos Santos Pires 2025-2026
