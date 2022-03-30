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

| Tag | Branch | `VERSION` | `DOCKER_TAG` | `EXTRA_DOCKER_TAG` |
|--|--|--|--|--|
|`x.y`||`x.y (build nnn)`|`x.y`||
|`x.y.z`||`x.y.z (build nnn)`|`x.y.z`|`x.y`|
||`release/x.y`|`x.y-dev-rrrrrrr (build nnn)`|`x.y-dev`||
||`master` or `main`|`dev-rrrrrrr (build nnn)`|`dev`||
||`master` or `main` (called with **latest** flag)|`rrrrrrr (build nnn)`|`latest`||
||`preview/some-description`|`some-description-rrrrrrr (build nnn)`|`some-description`||

## Usage

Add a script (`build.sh` or similar) to your repository like to this one:

```bash
#!/bin/bash
set -eo pipefail

# This will load the script from this repository. Make sure to point to a specific commit so the build continues to work
# event if breaking changes are introduced in this repository
source <(curl -s https://raw.githubusercontent.com/manastech/ci-docker-builder/14726d1aa865b754686818b51a9cbefe75da7943/build.sh)

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
  machine: true
  steps:
    - checkout
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
        #   tag-suffix: ""
        #   build-directory: ""
        #   build-options: ""
```

## Functions

### `dockerSetup [--skip-login] [latest]`

Prepares the environment to build the Docker image. After executing this function, the environment
variables `VERSION`, `DOCKER_TAG` and `EXTRA_DOCKER_TAG` will be set.

The optional `--skip-login` will avoid running `docker login`, leaving that up to the user. This is
useful when using a Github Action that logs into Amazon ECR with temporary credentials.

The optinal `latest` flag will set the `DOCKER_TAG` to "latest". This is useful for projects using continuous delivery of the main branch.

Also it will login to the Docker registry using `docker login` and the environment variables
`DOCKER_USER`, `DOCKER_PASS` and `DOCKER_REGISTRY` (optional).

### `dockerBuildAndPush`

Builds the Docker image using `docker build` and push the result to the registry using `docker push`.
By default it builds on the current directory and pushes to the repository specified by the
`DOCKER_REPOSITORY` environment variable.

It can receive these optional arguments:

  * `-r <repo>`: Override the repository where the image is pushed
  * `-s <suffix>`: Override the repository by adding a suffix to the one specified by the environment variable
  * `-t <suffix>`: Append a suffix to the image tags (e.g. `-next`)
  * `-d <dir>`: Build from the specified directory
  * `-o "<options>"`: Options to directly pass to the docker build command

This function can be called several times to build different images within the same build. For example:

```bash
# Build the main image from the root directory
dockerBuildAndPush

# Build an auxiliary image from the "broker" directory
dockerBuildAndPush -s "-broker" -d broker
```

Both images will have the exact same tags.
