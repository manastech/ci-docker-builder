#!/bin/bash

dockerSetup() {
  if [[ -n "$TRAVIS_TAG" ]]; then
    VERSION="$TRAVIS_TAG (build $TRAVIS_BUILD_NUMBER)"
    DOCKER_TAG="$TRAVIS_TAG"

    if [[ "$DOCKER_TAG" =~ ^([0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
      EXTRA_DOCKER_TAG=${BASH_REMATCH[1]}
    fi
  elif [[ -n "$TRAVIS_BRANCH" ]]; then
    case $TRAVIS_BRANCH in
      master)
        VERSION="dev-${TRAVIS_COMMIT::7} (build $TRAVIS_BUILD_NUMBER)"
        DOCKER_TAG="dev"
        ;;

      release/*)
        VERSION="${TRAVIS_BRANCH##release/}-dev-${TRAVIS_COMMIT::7} (build $TRAVIS_BUILD_NUMBER)"
        DOCKER_TAG="${TRAVIS_BRANCH##release/}-dev"
        ;;
    esac
  fi

  echo "Version: ${VERSION}"

  docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}" "${DOCKER_REGISTRY}"
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

  echo "Pusing ${IMAGE}"
  docker push "${IMAGE}"

  if [[ -n "$EXTRA_DOCKER_TAG" ]]; then
    local EXTRA_IMAGE="${REPO}:${EXTRA_DOCKER_TAG}"
    echo "Tagging also as $EXTRA_IMAGE"
    docker tag "${IMAGE}" "${EXTRA_IMAGE}"

    echo "Pushing ${EXTRA_IMAGE}"
    docker push "${EXTRA_IMAGE}"
  fi
}
