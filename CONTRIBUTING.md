<!-- TOC -->

- [Contributing](#contributing)
  - [Development workflow](#development-workflow)
  - [Versioning (Semantic Versioning)](#versioning-semantic-versioning)
  - [For code maintainers only](#for-code-maintainers-only)

<!-- TOC -->

# Contributing

- Configure authentication on your Github account to use the SSH protocol instead of HTTP. Watch this tutorial to learn how to set up: https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
- Install all packages and binaries following this [tutorial](REQUIREMENTS.md) (`make install-deps`).

- Create a fork this repository.
- Clone the forked repository to your local system:

```bash
git clone FORKED_REPOSITORY
```

- Add the address for the remote original repository:

```bash
git remote -v
git remote add upstream git@github.com:aeciopires/helm-watchdog-pod-delete.git
git remote -v
```

- Configure your profile:

```bash
git config --local user.email "you@example.com"

git config --local user.name "Your Name"
```

- Create a branch. Example:

```bash
git checkout -b BRANCH_NAME
```

- Make sure you are on the correct branch using the following command. The branch in use contains the '*' before the name.

```bash
git branch
```

- Make your changes and tests to the new branch (see [Development workflow](#development-workflow)).

- Commit the changes to the branch.
- Push files to repository remote with command:

```bash
git push --set-upstream origin BRANCH_NAME
```

- Create Pull Request (PR) to the `main` branch. See this [tutorial](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)
- Update the content with the suggestions of the reviewer (if necessary).
- After your pull request is merged to the `main` branch, update your local clone:

```bash
git checkout main
git pull upstream main
```

- Clean up after your pull request is merged with command:

```bash
git branch -d BRANCH_NAME
```

- Then you can update the ``main`` branch in your forked repository.

```bash
git push origin main
```

- And push the deletion of the feature branch to your GitHub repository with command:

```bash
git push --delete origin BRANCH_NAME
```

- To keep your fork in sync with the original repository, use these commands:

```bash
git pull upstream main
git push origin main
```

Reference:
- https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/

## Development workflow

All tasks are in the [Makefile](Makefile) (`make help` lists them):

```bash
make check-deps     # check the dependencies (Helm 4, kind, ...)
make docs           # regenerate charts/helm-watchdog-pod-delete/README.md after changing values.yaml, Chart.yaml or README.md.gotmpl
make test           # lint, template, unittest, kubeconform, shellcheck, actionlint, security (trivy), docs-check
make mermaid        # validate the Mermaid diagrams of all Markdown files (requires docker)
make kind-create    # kind cluster with 3 nodes + local OCI registry
make e2e            # end-to-end test with Helm 4
make argocd-install # install ArgoCD in kind
make e2e-argocd     # end-to-end test with ArgoCD
make stack-down     # remove the cluster
```

See [examples/README.md](examples/README.md) for details.

Best practices:

- Add or update unit tests in `charts/helm-watchdog-pod-delete/unittests/` for every change in the templates.
- Add a values file in `charts/helm-watchdog-pod-delete/ci/` to cover new combinations of values (used by lint, template, kubeconform and trivy).
- Document new values with `# --` comments (helm-docs) and update `values.schema.json`.
- Keep the default values secure (Pod Security Standards `restricted`, least privilege RBAC). Every finding accepted in [.trivyignore](.trivyignore) must have a justification.
- Never put secrets in the repository.
- Add your changes to the `[Unreleased]` section of [CHANGELOG.md](CHANGELOG.md).

## Versioning (Semantic Versioning)

The chart follows [Semantic Versioning 2.0.0](https://semver.org): `MAJOR.MINOR.PATCH`.

| Change | Example | When |
|--------|---------|------|
| **MAJOR** | `1.4.2` -> `2.0.0` | Incompatible changes: values renamed/removed, behavior changed, minimum Kubernetes version raised, resources renamed. Users must review their values. Document them in the `Upgrading` section of `README.md.gotmpl`. |
| **MINOR** | `1.4.2` -> `1.5.0` | New backward compatible features (e.g. new values with defaults that keep the current behavior). |
| **PATCH** | `1.4.2` -> `1.4.3` | Backward compatible bug fixes, documentation and image updates without behavior change. |
| Pre-release | `1.5.0-rc.1` | Versions for tests. They are not marked as `latest` in GitHub Releases. |

Rules:

- The version is defined in `version` of [Chart.yaml](charts/helm-watchdog-pod-delete/Chart.yaml).
- The git tag MUST be exactly the chart version, without `v` prefix (e.g. `1.0.0`). The CI fails if they are different.
- [CHANGELOG.md](CHANGELOG.md) MUST have a section `## [x.y.z]` for the version. It is used as the release notes.
- `appVersion` is the version of kubectl (image `alpine/kubectl`) and does not follow the chart version.

## For code maintainers only

The CI ([.github/workflows/release.yml](.github/workflows/release.yml)) runs **only when a SemVer tag is pushed**. It runs:

1. **Static tests**: `make version-check TAG=<tag>` and `make test`.
2. **E2E tests**: kind clusters with Kubernetes 1.34, 1.35, 1.36 and 1.37 (`make e2e`), and ArgoCD (`make e2e-argocd`).
3. **Release** (only if all tests pass):
   - GitHub Release `helm-watchdog-pod-delete-<version>` + Helm repository in GitHub Pages (chart-releaser).
   - OCI registry: `oci://ghcr.io/aeciopires/helm-charts/helm-watchdog-pod-delete:<version>`, signed with cosign (keyless).
   - Release notes from `CHANGELOG.md`.

To generate a new release of the helm chart, follow these instructions:

- Review and merge the opened PRs.
- Create a branch. Example:

```bash
git checkout -b release-x.y.z
```

- Define the new version following [Versioning (Semantic Versioning)](#versioning-semantic-versioning).
- Change the ``version`` parameter in ``charts/helm-watchdog-pod-delete/Chart.yaml`` and the ``artifacthub.io/changes`` annotation.
- Move the changes of `[Unreleased]` to a new section `## [x.y.z] - YYYY-MM-DD` in ``CHANGELOG.md`` and update the links at the end of the file.
- Update the documentation and run all tests locally:

```bash
make docs
make version-check
make test
make kind-create
make e2e
make argocd-install
make e2e-argocd
make stack-down
```

- Commit the changes, push the branch and create a Pull Request (PR) to the `main` branch.
- After the PR is merged, update your local clone and create the tag (the same value of the chart version):

```bash
git checkout main
git pull upstream main

make version-check TAG=x.y.z
git tag -a x.y.z -m "Release x.y.z"
git push upstream x.y.z
```

- Follow the pipeline in https://github.com/aeciopires/helm-watchdog-pod-delete/actions. If a test fails, nothing is published: fix the problem, delete the tag (`git push upstream :refs/tags/x.y.z && git tag -d x.y.z`) and create it again.
- To keep your fork in sync with the original repository, use these commands:

```bash
git pull upstream main
git pull upstream main --tags

git push origin main
git push origin main --tags
```

Requirements of the GitHub repository (configured once):

- **Settings > Actions > General > Workflow permissions**: the workflow requests its own permissions (`contents`, `packages` and `id-token` only in the release job).
- **GitHub Pages** published from the `gh-pages` branch.
- After the first OCI publication, make the package `helm-charts/helm-watchdog-pod-delete` **public** in https://github.com/aeciopires?tab=packages and link it to this repository.

References:

- https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/
- https://semver.org
- https://keepachangelog.com
- https://helm.sh/docs/topics/registries/
