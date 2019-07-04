#!/bin/bash

dockerSetup() {
  TAG=${TRAVIS_TAG:-$CIRCLE_TAG}
  BRANCH=${TRAVIS_BRANCH:-$CIRCLE_BRANCH}
  BUILD_NUMBER=${TRAVIS_BUILD_NUMBER:-$CIRCLE_BUILD_NUM}
  COMMIT=${TRAVIS_COMMIT:-$CIRCLE_SHA1}

  if [[ -n "$TAG" ]]; then
    VERSION="$TAG (build $BUILD_NUMBER)"
    DOCKER_TAG="$TAG"

    if [[ "$DOCKER_TAG" =~ ^([0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
      EXTRA_DOCKER_TAG=${BASH_REMATCH[1]}
    fi
  elif [[ -n "$BRANCH" ]]; then
    case $BRANCH in
      master)
        VERSION="dev-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="dev"
        ;;

      staging)
        VERSION="stg-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="stg"
        ;;

      stable)
        VERSION="stable-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="stable"
        ;;

      release/*)
        VERSION="${BRANCH##release/}-dev-${COMMIT::7} (build $BUILD_NUMBER)"
        DOCKER_TAG="${BRANCH##release/}-dev"
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
