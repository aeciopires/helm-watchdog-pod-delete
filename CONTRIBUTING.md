<!-- TOC -->

- [Contributing](#contributing)
  - [For code mainteners only](#for-code-mainteners-only)

<!-- TOC -->

# Contributing

- Configure authentication on your Github account to use the SSH protocol instead of HTTP. Watch this tutorial to learn how to set up: https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
- [OPTIONAL] Install all packages and binaries following this [tutorial](REQUIREMENTS.md).

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

- Make your changes and tests to the new branch.

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

## For code mainteners only

To generate a new release of the helm chart, follow these instructions:

- Review and merge the opened PRs
- Run local tests
- Create a branch. Example:

```bash
git checkout -b BRANCH_NAME
```

Make sure you are on the correct branch using the following command. The branch in use will show with a '*' before the name.

```bash
git branch
```

- Make your changes and tests to the new branch
- Verify the syntax errors using the follow commands:

```bash
cd charts/helm-watchdog-pod-delete
make lint
```

- Analyse the changes of the PRs merged and set a new release using the follow approach:

A **major** version" should be the "dot-release". Example: *1.0.0* -> *1.1.0* is be a **major release update**. Users have to check whether they have to modify their values.yaml, and we need to write a short explanation of what has changed in the ``chart/helm-watchdog-pod-delete/README.md.gotmpl``.

A **minor** is the "dot-dot" release. Example: *1.0.1* -> *1.0.2* is **minor upgrade**, no changes in any APIs, interfaces etc. should be necessary.

- Change the ``version`` parameters (helm chart version) in ``charts/helm-watchdog-pod-delete/Chart.yaml`` file.
- Run the following commands to update the documentation of the helm chart.

```bash
cd charts/helm-watchdog-pod-delete
make docs
```

- Commit the changes to the branch.
- Push files to repository remote with command:

```bash
git push --set-upstream origin BRANCH_NAME
```

- Create Pull Request (PR) to the main branch. See this [tutorial](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)
- Update the content with the suggestions of the reviewer (if necessary).
- After your pull request is merged to the main branch, update your local clone:

```bash
git checkout main
git pull upstream main
```

- Clean up after your pull request is merged with command:

```bash
git branch -d BRANCH_NAME
```

Then you can update the main branch in your forked repository.

```bash
git push origin main
```

And push the deletion of the feature branch to your GitHub repository with command:

```bash
git push --delete origin BRANCH_NAME
```

- Create a new tag to generate a new release of the helm chart using the following commands:

```bash
git tag -a 0.1.2 -m "New release" #example
git push upstream --tags
```

- The before commands will start the pipeline and will generate a new release and tag in standad ``helm-watchdog-pod-delete-0.1.1``.
- To keep your fork in sync with the original repository, use these commands:

```bash
git pull upstream main
git pull upstream main --tags

git push origin main
git push origin main --tags
```

- After this, edit and adjust the text generated automatically for new release and adjust the release notes follow the examples the other releases published in https://github.com/aeciopires/helm-watchdog-pod-delete/releases

References:

- https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/
