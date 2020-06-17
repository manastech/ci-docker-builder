#!/bin/bash

# Unset Travis environment variables
unset TRAVIS

buildNumber() {
  GITHUB_RUN_NUMBER="$1"
}

tag() {
  GITHUB_REF="refs/tags/${1}"
}

branch() {
  GITHUB_REF="refs/heads/${1}"
}

commit() {
  GITHUB_SHA="$1"
}

GITHUB_ACTIONS="true"

. ./test-suite.sh
