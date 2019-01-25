#!/bin/bash

# Unset Travis environment variables
unset TRAVIS_BUILD_NUMBER
unset TRAVIS_TAG
unset TRAVIS_BRANCH
unset TRAVIS_COMMIT

buildNumber() {
  CIRCLE_BUILD_NUM="$1"
}

tag() {
  CIRCLE_TAG="$1"
}

branch() {
  CIRCLE_BRANCH="$1"
}

commit() {
  CIRCLE_SHA1="$1"
}

. ./test-suite.sh
