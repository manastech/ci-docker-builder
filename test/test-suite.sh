#!/bin/bash

. ./docker-mock.sh
. ../build.sh

setUp() {
  buildNumber "123"
  tag ""
  branch ""
  commit "0b5a2c59f042a83a94bd46b52fb9ec040743c7a5"

  dockerMockSetUp
  DOCKER_USER="user"
  DOCKER_PASS="pass"
  DOCKER_REGISTRY="registry"
  DOCKER_REPOSITORY="repository"
}

tearDown() {
  unset VERSION
  unset DOCKER_TAG
  unset EXTRA_DOCKER_TAG
}

testTagMajorMinor() {
  tag "1.2"
  dockerSetup > /dev/null

  assertEquals "1.2 (build 123)" "$VERSION"
  assertEquals "1.2" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testTagMajorMinorPatch() {
  tag "1.2.3"
  dockerSetup > /dev/null

  assertEquals "1.2.3 (build 123)" "$VERSION"
  assertEquals "1.2.3" "$DOCKER_TAG"
  assertEquals "1.2" "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testReleaseBranch() {
  branch "release/2.3"
  dockerSetup > /dev/null

  assertEquals "2.3-dev-0b5a2c5 (build 123)" "$VERSION"
  assertEquals "2.3-dev" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testMasterBranch() {
  branch "master"
  dockerSetup > /dev/null

  assertEquals "dev-0b5a2c5 (build 123)" "$VERSION"
  assertEquals "dev" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testMasterBranchAsLatest() {
  branch "master"
  dockerSetup latest

  assertEquals "0b5a2c5 (build 123)" "$VERSION"
  assertEquals "latest" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testBuild() {
  DOCKER_TAG="tag"
  dockerBuildAndPush > /dev/null

  assertEquals "build -t repository:tag ." "${DOCKER_CALLS[0]}"
  assertEquals "push repository:tag" "${DOCKER_CALLS[1]}"
  assertNull "${DOCKER_CALLS[2]}"
}

testBuildWithExtraTag() {
  DOCKER_TAG="tag"
  EXTRA_DOCKER_TAG="extra"
  dockerBuildAndPush > /dev/null

  assertEquals "build -t repository:tag ." "${DOCKER_CALLS[0]}"
  assertEquals "push repository:tag" "${DOCKER_CALLS[1]}"
  assertEquals "tag repository:tag repository:extra" "${DOCKER_CALLS[2]}"
  assertEquals "push repository:extra" "${DOCKER_CALLS[3]}"
  assertNull "${DOCKER_CALLS[4]}"
}

testBuildCustomRepo() {
  DOCKER_TAG="tag"
  dockerBuildAndPush -r myrepo > /dev/null

  assertEquals "build -t myrepo:tag ." "${DOCKER_CALLS[0]}"
  assertEquals "push myrepo:tag" "${DOCKER_CALLS[1]}"
  assertNull "${DOCKER_CALLS[2]}"
}

testBuildRepoSuffix() {
  DOCKER_TAG="tag"
  dockerBuildAndPush -s "-foo" > /dev/null

  assertEquals "build -t repository-foo:tag ." "${DOCKER_CALLS[0]}"
  assertEquals "push repository-foo:tag" "${DOCKER_CALLS[1]}"
  assertNull "${DOCKER_CALLS[2]}"
}

testBuildCustomDir() {
  DOCKER_TAG="tag"
  dockerBuildAndPush -d dir > /dev/null

  assertEquals "build -t repository:tag dir" "${DOCKER_CALLS[0]}"
  assertEquals "push repository:tag" "${DOCKER_CALLS[1]}"
  assertNull "${DOCKER_CALLS[2]}"
}

testBuildCustomRepoCustomDirAndExtraTag() {
  DOCKER_TAG="tag"
  EXTRA_DOCKER_TAG="extra"
  dockerBuildAndPush -r myrepo -d dir > /dev/null

  assertEquals "build -t myrepo:tag dir" "${DOCKER_CALLS[0]}"
  assertEquals "push myrepo:tag" "${DOCKER_CALLS[1]}"
  assertEquals "tag myrepo:tag myrepo:extra" "${DOCKER_CALLS[2]}"
  assertEquals "push myrepo:extra" "${DOCKER_CALLS[3]}"
  assertNull "${DOCKER_CALLS[4]}"
}

testBuildWithoutTags() {
  dockerBuildAndPush > /dev/null
  assertNull "${DOCKER_CALLS[0]}"
}

testStack() {
  tag "1.2.3"
  dockerSetup > /dev/null
  dockerBuildAndPush > /dev/null

  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertEquals "build -t repository:1.2.3 ." "${DOCKER_CALLS[1]}"
  assertEquals "push repository:1.2.3" "${DOCKER_CALLS[2]}"
  assertEquals "tag repository:1.2.3 repository:1.2" "${DOCKER_CALLS[3]}"
  assertEquals "push repository:1.2" "${DOCKER_CALLS[4]}"
  assertNull "${DOCKER_CALLS[5]}"
}

testPreviewBranch() {
  branch "preview/my-feature"
  dockerSetup > /dev/null

  assertEquals "my-feature-0b5a2c5 (build 123)" "$VERSION"
  assertEquals "my-feature" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertNull "${DOCKER_CALLS[1]}"
}

testBuildAndPushPreviewBranch() {
  branch "preview/my-feature"
  dockerSetup > /dev/null
  dockerBuildAndPush > /dev/null

  assertEquals "my-feature-0b5a2c5 (build 123)" "$VERSION"
  assertEquals "my-feature" "$DOCKER_TAG"
  assertNull "$EXTRA_DOCKER_TAG"
  assertEquals "login -u user -p pass registry" "${DOCKER_CALLS[0]}"
  assertEquals "build -t repository:my-feature ." "${DOCKER_CALLS[1]}"
  assertEquals "push repository:my-feature" "${DOCKER_CALLS[2]}"
  assertNull "${DOCKER_CALLS[3]}"
}

SHUNIT_PARENT="test-suite.sh"
. ./shunit2
