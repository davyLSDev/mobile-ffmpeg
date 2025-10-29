#!/usr/bin/env bash
#
# build_android.sh - Build the Android library inside the android_builder Docker container
#
# Usage:
#   ./build_android.sh [--lts] [--interactive]
#
# Examples:
#   ./build_android.sh          # Build main version
#   ./build_android.sh --lts    # Build LTS version
#   ./build_android.sh --interactive   # Open a shell instead of building
#

set -e

IMAGE_NAME="android_builder"
NDK_VERSION="21.3.6528147"
CONTAINER_NAME="android_builder_container"

# Detect project root
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure Docker image exists (build if missing)
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "🔧 Docker image '$IMAGE_NAME' not found, building it..."
  docker build -t $IMAGE_NAME "$PROJECT_ROOT"
fi

# Build command options
BUILD_CMD="bash ./android.sh --no-output-redirection -d"
if [[ "$1" == "--lts" ]]; then
  BUILD_CMD="bash ./android.sh --lts --no-output-redirection -d"
fi

# Run interactive shell if requested
if [[ "$1" == "--interactive" ]]; then
  echo "🧑‍💻 Starting interactive shell inside $IMAGE_NAME..."
  docker run --rm -it \
    -v "$PROJECT_ROOT":/workspace \
    -w /workspace \
    -e ANDROID_NDK_ROOT=/opt/android-sdk/ndk/$NDK_VERSION \
    $IMAGE_NAME \
    bash
  exit 0
fi

# Normal build
echo "🚀 Starting Android build inside Docker container..."
docker run --rm -it \
  -v "$PROJECT_ROOT":/workspace \
  -w /workspace \
  -e ANDROID_NDK_ROOT=/opt/android-sdk/ndk/$NDK_VERSION \
  $IMAGE_NAME \
  $BUILD_CMD

