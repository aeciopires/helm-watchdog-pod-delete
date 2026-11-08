<!-- TOC -->

- [Requirements](#requirements)
  - [Tools managed by mise](#tools-managed-by-mise)
  - [Install](#install)
  - [Operating system specific instructions](#operating-system-specific-instructions)

<!-- TOC -->

# Requirements

- [Docker](https://docs.docker.com/engine/install/) (required by kind)
- [make](https://www.gnu.org/software/make/), `git`, `curl` and `bash`
- [mise](https://mise.jdx.dev) to install the other tools with the versions pinned in [mise.toml](mise.toml)

## Tools managed by mise

| Tool | Usage |
|------|-------|
| [helm](https://helm.sh) 4 | Lint, template, package, install and push the chart |
| [helm-unittest](https://github.com/helm-unittest/helm-unittest) (Helm plugin) | Unit tests of the templates |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Access the cluster |
| [kind](https://kind.sigs.k8s.io) | Local Kubernetes cluster |
| [helm-docs](https://github.com/norwoodj/helm-docs) | Generate the chart README.md |
| [kubeconform](https://github.com/yannh/kubeconform) | Validate the manifests against the Kubernetes schemas |
| [shellcheck](https://www.shellcheck.net) | Lint shell scripts |
| [actionlint](https://github.com/rhysd/actionlint) | Lint the GitHub Actions workflows |
| [trivy](https://trivy.dev) | Security scan of the chart |
| [cosign](https://docs.sigstore.dev) | Sign/verify the chart in the OCI registry |
| [yq](https://github.com/mikefarah/yq) | Handle YAML files |
| [argocd](https://argo-cd.readthedocs.io) CLI | Optional, interact with ArgoCD |

## Install

From the root of the repository:

```bash
make install-deps   # installs mise (if missing), runs "mise trust" and "mise install" and installs the helm-unittest plugin
make check-deps     # checks if all dependencies are installed and if Helm is version 4
```

Activate mise in your shell to use the tools directly (the Makefile uses `mise exec`, so this is optional for `make`):

```bash
# bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
# zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

Reference: https://mise.jdx.dev/getting-started.html

To update a tool, change its version in [mise.toml](mise.toml) and run `mise install`. The CI uses the same file.

## Operating system specific instructions

For **Ubuntu**, follow the instructions to install softwares [softwares-ubuntu](softwares-ubuntu.md)

For **MacOS**, follow the instructions to install softwares [softwares-macos](softwares-macos.md)
