#! /bin/bash
# Build script for the GitHub Action
set -xeo pipefail

# Collect action inputs to pass as command options
SETUP_OPTS=""
[ "$INPUT_SKIP_LOGIN" = "true" ] && SETUP_OPTS="$SETUP_OPTS --skip-login"
[ "$INPUT_LATEST" = "true" ]     && SETUP_OPTS="$SETUP_OPTS latest"

BUILD_OPTS=""
[ -z $INPUT_REPOSITORY ]        || BUILD_OPTS="$BUILD_OPTS -r $INPUT_REPOSITORY"
[ -z $INPUT_REPOSITORY_SUFFIX ] || BUILD_OPTS="$BUILD_OPTS -s $INPUT_REPOSITORY_SUFFIX"
[ -z $INPUT_TAG_SUFFIX ]        || BUILD_OPTS="$BUILD_OPTS -t $INPUT_TAG_SUFFIX"
[ -z $INPUT_BUILD_DIRECTORY ]   || BUILD_OPTS="$BUILD_OPTS -d $INPUT_BUILD_DIRECTORY"

# Loads the script from this repository
source ./build.sh

# Prepare the build
dockerSetup $SETUP_OPTS

# Write a VERSION file for the footer
echo $VERSION > VERSION

# Build and push the Docker image
dockerBuildAndPush $BUILD_OPTS -o "$INPUT_BUILD_OPTIONS"
