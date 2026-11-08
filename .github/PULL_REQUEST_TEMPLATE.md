<!--
Thank you for contributing to this repository. Before you submit this PR we'd like to
make sure you are aware of our technical requirements and best practices:

- https://github.com/aeciopires/helm-watchdog-pod-delete/blob/main/CONTRIBUTING.md
- https://github.com/aeciopires/helm-watchdog-pod-delete/blob/main/REQUIREMENTS.md

Following our best practices right from the start will accelerate the review process and
help get your PR merged quicker.

When updates to your PR are requested, please add new commits and do not squash the
history. This will make it easier to identify new changes. The PR will be squashed
anyways when it is merged. Thanks.

For fast feedback, please @-mention maintainers.
-->

#### What this PR does / why we need it:

#### Which issue this PR fixes
*(optional, in `fixes #<issue number>(, fixes #<issue_number>, ...)` format, will close that issue when PR gets merged)*
  - fixes #

#### Checklist

- [ ] `make test` passes (lint, unittest, kubeconform, shellcheck, actionlint, trivy, docs)
- [ ] `make e2e` passes in the local kind cluster (`make kind-create`)
- [ ] Unit tests added/updated in `charts/helm-watchdog-pod-delete/unittests/`
- [ ] New values documented (`# --` comments) and added to `values.schema.json`
- [ ] `make docs` executed
- [ ] Changes added to the `[Unreleased]` section of `CHANGELOG.md`

#### Special notes for your reviewer:

