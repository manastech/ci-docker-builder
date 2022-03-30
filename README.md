# ci-docker-builder

This repository hosts a script that can be used to build Docker images during the execution on **Travis**, **CircleCI**
or **Github Actions** and push the result to Docker Hub.

The **name** of the image and the **repository** are set through environment variables that must be set on each environment.

  * `DOCKER_USER` and `DOCKER_PASS`: Username and password used to login to the Docker registry. Make sure the password is
     hidden in the CI settings.
  * `DOCKER_REPOSITORY`: The name of the repository where the image is pushed (i.e.: `organization/image`)
  * `DOCKER_REGISTRY`: Optional. Can be used to push to a custom Docker registry instead of Docker Hub.

The **tag** of the Docker image is calculated depending on the branch and/or tag where the build is being executed acording
to these rules. Also a `VERSION` environment variable is generated that can (and should) be used to display within the
application (for example in the footer).

| Tag     | Branch                                         | `VERSION`                              | Docker tags              |
|---------|------------------------------------------------|----------------------------------------|--------------------------|
| `x.y`   |                                                | `x.y (build nnn)`                      | `x.y`, `latest`          |
| `x.y.z` |                                                | `x.y.z (build nnn)`                    | `x.y.z`, `x.y`, `latest` |
|         | `release/x.y`                                  | `x.y-dev-rrrrrrr (build nnn)`          | `x.y-dev`                |
|         | `main`                                         | `dev-rrrrrrr (build nnn)`              | `dev`                    |
|         | `some-branch` (with DEV_BRANCH=some-branch)    | `dev-rrrrrrr (build nnn)`              | `dev`                    |
|         | `some-branch` (with STABLE_BRANCH=some-branch) | `rc-rrrrrrr (build nnn)`               | `rc`                     |
|         | `preview/some-description`                     | `some-description-rrrrrrr (build nnn)` | `some-description`       |

## Usage

Add a script (`build.sh` or similar) to your repository like to this one:

```bash
#!/bin/bash
set -eo pipefail

# This will load the script from this repository. Make sure to point to a specific commit so the build continues to work
# event if breaking changes are introduced in this repository
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/ef8bdcdf2eae3944de7235b847cb449789aecab7/build.sh)"

# Prepare the build
dockerSetup

# Write a VERSION file for the footer
echo $VERSION > VERSION

# Build and push the Docker image
dockerBuildAndPush
```

### Travis CI
Include these lines within the `.travis.yml` of your project:

```yaml
deploy:
  provider: script
  script: "./build.sh"
  on:
    all_branches: true
```

### Circle CI
Add a job within `.circleci/config.yml` and include it in the workflow (preferrably after the test passes):

```yaml
build:
  docker:
      - image: cimg/base:current
  steps:
    - checkout
    - setup_remote_docker:
          docker_layer_caching: true
    - run: ./.circleci/build.sh
```

Since CircleCI by default doesn't execute on tags, make sure the workflow enables it. For example:

```yaml
workflows:
  version: 2
  test-and-build:
    jobs:
      - test:
          filters:
            branches:
              only: /.*/
            tags:
              only: /.*/
      - build:
          requires:
            - test
          filters:
            branches:
              only: /.*/
            tags:
              only: /.*/
```

### Github Actions

Add a workflow like this in a `.github/workflows/build.yml` file to let the script decide when to build or not:

```yaml
name: Build & Push Docker Image

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    # needs: test # you can declare a `test` job and uncomment this to test the app before building
    env:
      DOCKER_REPOSITORY: 'dockerhub_org/dockerhub_repo'
      DOCKER_USER: ${{ secrets.DOCKER_USER }}
      DOCKER_PASS: ${{ secrets.DOCKER_PASS }}
    steps:
      - uses: actions/checkout@v2
      - name: Build image & push to Docker Hub
        run: ./build.sh
```

Alternatively you may skip the local `build.sh` script and use this repository
as a step action directly.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    # needs: test # you can declare a `test` job and uncomment this to test the app before building
    env:
      DOCKER_REPOSITORY: 'dockerhub_org/dockerhub_repo'
      DOCKER_USER: ${{ secrets.DOCKER_USER }}
      DOCKER_PASS: ${{ secrets.DOCKER_PASS }}
    steps:
      - uses: actions/checkout@v2
      - uses: manastech/ci-docker-builder@<sha1>
        # with:
        #   skip-login: <true|false>
        #   repository: ""
        #   repository-suffix: ""
        #   build-directory: ""
```

## Functions

### `dockerSetup [--skip-login]`

Prepares the environment to build the Docker image. After executing this function, the environment
variables `VERSION`, `DOCKER_TAG` and `EXTRA_DOCKER_TAG` will be set.

It will also login to the Docker registry using `docker login` and the environment variables
`DOCKER_USER`, `DOCKER_PASS` and `DOCKER_REGISTRY` (optional). This behaviour can be avoided
by setting the optional `--skip-login` flag, useful when using a Github Action that logs into
Amazon ECR with temporary credentials.

The function supports two extra environment variables (`DEV_BRANCH` and `STABLE_BRANCH`) to tweak which
branches to consider as development & stable, respectively. `DEV_BRANCH` defaults to `main`, and there's no
default `STABLE_BRANCH`:

```
DEV_BRANCH=develop dockerSetup
STABLE_BRANCH=stable dockerSetup
DEV_BRANCH=master STABLE_BRANCH=stable dockerSetup
```

> **DEPRECATION NOTE:** older versions of the script supported a `latest` flag to generate the `:latest` Docker image tags.
> This flag has been since removed, and the script will fail to notify users if present.

### `dockerBuildAndPush`

Builds the Docker image using `docker build` and push the result to the registry using `docker push`.
By default it builds on the current directory and pushes to the repository specified by the
`DOCKER_REPOSITORY` environment variable.

It can receive these optional arguments:

  * `-r <repo>`: Override the repository where the image is pushed
  * `-s <suffix>`: Override the repository by adding a suffix to the one specified by the environment variable
  * `-d <dir>`: Build from the specified directory

This function can be called several times to build different images within the same build. For example:

```bash
# Build the main image from the root directory
dockerBuildAndPush

# Build an auxiliary image from the "broker" directory
dockerBuildAndPush -s "-broker" -d broker
```

Both images will have the exact same tags.
