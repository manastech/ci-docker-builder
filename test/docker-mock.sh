docker() {
  DOCKER_CALLS+=("$*")
}

dockerMockSetUp() {
  unset DOCKER_CALLS
  declare -a DOCKER_CALLS
}
