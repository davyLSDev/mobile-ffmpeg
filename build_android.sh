#!/usr/bin/env bash
#
# build_android.sh - Build the Android library inside the android_builder Docker container
#
# ... (Usage comments remain the same) ...

set -e

IMAGE_NAME="android_builder"
# NDK_VERSION="21.3.6528147"
# downgrade the ndk version to build 4.2.LTS
NDK_VERSION="17.2.4988734"
CONTAINER_NAME="android_builder_container"

# Detect project root
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure Docker image exists (build if missing)
if ! docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
  echo "🔧 Docker image '$IMAGE_NAME' not found, building it..."
  # Note: You should ensure your Dockerfile is up-to-date before this build command
  docker build -t $IMAGE_NAME "$PROJECT_ROOT"
fi

# cleanup old artifacts function
clean_artifacts() {
    echo "    -> Deleting prebuilt/, .tmp/, android/build/ and build.log"
    rm -f build.log
    # Delete build directories based on .gitignore and known cache locations
    rm -rf prebuilt/ .tmp/ android/build/
}

# Build command options

# 1. Check for the --clean flag
if [[ "$1" == "--clean" ]]; then
    CLEAN_MODE=true
    echo "🧹 Detected --clean parameter. Removing old build artifacts..."
    clean_artifacts
    # Shift arguments so the rest of the script doesn't see '--clean'
    shift
fi

# no --no-output-redirection option is in this older android.sh
# BUILD_CMD="bash ./android.sh --no-output-redirection -d"
BUILD_CMD="bash ./android.sh -d"
if [[ "$1" == "--lts" ]]; then
  BUILD_CMD="bash ./android.sh --lts -d"
fi

# Run interactive shell if requested
if [[ "$1" == "--interactive" ]]; then
  echo "🧑‍💻 Starting interactive shell inside $IMAGE_NAME..."
  docker run --rm -it \
    -v "$PROJECT_ROOT":/workspace \
    --user "$(id -u):$(id -g)" \
    -w /workspace \
    -e HOME=/home/builder \
    -e ANDROID_NDK_ROOT=/opt/android-sdk/ndk/$NDK_VERSION \
    $IMAGE_NAME \
    bash
  exit 0
fi

# Normal build
echo "🚀 Starting Android build inside Docker container..."
docker run --rm -it \
  -v "$PROJECT_ROOT":/workspace \
  --user "$(id -u):$(id -g)" \
  -w /workspace \
  -e HOME=/home/builder \
  -e ANDROID_NDK_ROOT=/opt/android-sdk/ndk/$NDK_VERSION \
  $IMAGE_NAME \
  $BUILD_CMD