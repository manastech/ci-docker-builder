#!/bin/bash

# Unset Travis environment variables
unset TRAVIS

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

CIRCLECI="true"

. ./test-suite.sh
