#!/bin/bash

function __load_travisci_environment() {
  TAG=${TRAVIS_TAG}
  BRANCH=${TRAVIS_BRANCH}
  BUILD_NUMBER=${TRAVIS_BUILD_NUMBER}
  COMMIT=${TRAVIS_COMMIT}
}

function __load_circleci_environment() {
  TAG=${CIRCLE_TAG}
  BRANCH=${CIRCLE_BRANCH}
  BUILD_NUMBER=${CIRCLE_BUILD_NUM}
  COMMIT=${CIRCLE_SHA1}
}

function __load_github_actions_environment() {
  if [[ $GITHUB_REF == refs/heads/* ]]; then
    BRANCH=${GITHUB_REF#"refs/heads/"}
    TAG=""
  elif [[ $GITHUB_REF == refs/tags/* ]]; then
    TAG=${GITHUB_REF#"refs/tags/"}
    BRANCH=""
  fi
  BUILD_NUMBER=${GITHUB_RUN_NUMBER}
  COMMIT=${GITHUB_SHA}
}

dockerSetup() {
  if [ "$TRAVIS" = "true" ]; then
    __load_travisci_environment
  elif [ "$CIRCLECI" = "true" ]; then
    __load_circleci_environment
  elif [ "$GITHUB_ACTIONS" = "true" ]; then
    __load_github_actions_environment
  else
    echo "Could not detect CI environment"
    exit 1
  fi

  if [ "--skip-login" = "$1" ]
  then
    DO_LOGIN=0
    shift
  elif [ "--skip-login" = "$2" ]
  then
    DO_LOGIN=0
  else
    DO_LOGIN=1
  fi

  if [[ -n "$TAG" ]]; then
    VERSION="$TAG (build $BUILD_NUMBER)"
    DOCKER_TAG="$TAG"

    if [[ "$DOCKER_TAG" =~ ^([0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
      EXTRA_DOCKER_TAG=${BASH_REMATCH[1]}
    fi
  elif [[ -n "$BRANCH" ]]; then
    case $BRANCH in
      master|main)
        case $1 in
          latest)
            VERSION="${COMMIT::7} (build $BUILD_NUMBER)"
            DOCKER_TAG="latest"
            ;;

          *)
            VERSION="dev-${COMMIT::7} (build $BUILD_NUMBER)"
            DOCKER_TAG="dev"
            ;;
        esac
        ;;

      release/*)
        VERSION="${BRANCH##release/}-dev-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="${BRANCH##release/}-dev"
        ;;

      preview/*)
        VERSION="${BRANCH##preview/}-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="${BRANCH##preview/}"
        ;;
    esac
  fi

  echo "Version: ${VERSION}"

  if [ $DO_LOGIN -eq 1 ]
  then
    # See https://stackoverflow.com/a/4775845/641451 for the `<<< "$VARIABLE"` syntax
    docker login --username="${DOCKER_USER}" --password-stdin "${DOCKER_REGISTRY}" <<< "${DOCKER_PASS}"
  fi
}

dockerBuildAndPush() {
  if [[ -z "$DOCKER_TAG" ]]; then
    echo "Not building because DOCKER_TAG is undefined"
    return
  fi

  local REPO=$DOCKER_REPOSITORY
  local DIR="."
  local OPTIND

  while getopts ":r:d:s:" opt "$@"; do
    case ${opt} in
      r)
        REPO=$OPTARG
        ;;

      s)
        REPO="${DOCKER_REPOSITORY}${OPTARG}"
        ;;

      d)
        DIR=$OPTARG
        ;;

      *)
        ;;
    esac
  done

  local IMAGE="${REPO}:${DOCKER_TAG}"

  echo "Building image ${IMAGE} from ${DIR}"
  docker build -t "${IMAGE}" "${DIR}"

  echo "Pushing ${IMAGE}"
  docker push "${IMAGE}"

  if [[ -n "$EXTRA_DOCKER_TAG" ]]; then
    local EXTRA_IMAGE="${REPO}:${EXTRA_DOCKER_TAG}"
    echo "Tagging also as $EXTRA_IMAGE"
    docker tag "${IMAGE}" "${EXTRA_IMAGE}"

    echo "Pushing ${EXTRA_IMAGE}"
    docker push "${EXTRA_IMAGE}"
  fi
}
