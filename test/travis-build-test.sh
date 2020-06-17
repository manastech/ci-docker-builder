#!/bin/bash

buildNumber() {
  TRAVIS_BUILD_NUMBER="$1"
}

tag() {
  TRAVIS_TAG="$1"
}

branch() {
  TRAVIS_BRANCH="$1"
}

commit() {
  TRAVIS_COMMIT="$1"
}

TRAVIS="true"

. ./test-suite.sh
