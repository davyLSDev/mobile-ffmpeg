# Use an Ubuntu base similar to Travis CI's "trusty" (but updated for modern packages)
FROM ubuntu:20.04

LABEL maintainer="Dawson <you@example.com>"
ENV DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Basic dependencies (build tools, android deps, editors)
# --------------------------------------------------
RUN apt-get clean && \
    apt-get update -o Acquire::Retries=5 -o Acquire::http::Timeout="30" && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk \
        git \
        curl \
        wget \
        unzip \
        zip \
        autoconf \
        automake \
        libtool \
        pkg-config \
        cmake \
        gcc \
        g++ \
        make \
        gperf \
        texinfo \
        yasm \
        bison \
        autogen \
        patch \
        sudo \
        vim-tiny \
        ca-certificates \
        && apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Allow Git to trust /workspace directory ownership
RUN git config --system --add safe.directory /workspace


# --------------------------------------------------
# Set up Android SDK and NDK (mimicking Travis)
# --------------------------------------------------
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT

# Download and install command-line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip -q commandlinetools-linux-9477386_latest.zip && \
    rm commandlinetools-linux-9477386_latest.zip && \
    mkdir -p latest && \
    mv cmdline-tools latest/ && \
    echo "sdkmanager installed to:" && find $ANDROID_SDK_ROOT/cmdline-tools/latest -type f -name sdkmanager

# Update PATH
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/cmdline-tools/bin:$ANDROID_SDK_ROOT/platform-tools

# Verify sdkmanager and install required SDK/NDK packages
RUN sdkmanager --sdk_root=$ANDROID_SDK_ROOT --version && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses || true && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platform-tools" \
        "platforms;android-24" \
        "build-tools;28.0.3" \
        "cmake;3.10.2.4988404" \
        "ndk;21.3.6528147"


# --------------------------------------------------
# Accept licenses and install required SDK/NDK components
# --------------------------------------------------
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses || true && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platform-tools" \
        "platforms;android-24" \
        "build-tools;28.0.3" \
        "cmake;3.10.2.4988404" \
        "ndk;21.3.6528147"


# --------------------------------------------------
# Install NASM (same as travis)
# --------------------------------------------------
RUN wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz && \
    tar zxvf nasm-2.14.02.tar.gz && \
    cd nasm-2.14.02 && \
    ./configure && make -j$(nproc) && make install && \
    cd .. && rm -rf nasm-2.14.02*

# --------------------------------------------------
# Default working directory inside container
# --------------------------------------------------
WORKDIR /workspace

# --------------------------------------------------
# Entry point
# --------------------------------------------------
CMD ["/bin/bash"]

