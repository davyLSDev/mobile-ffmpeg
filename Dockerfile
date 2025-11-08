# Use an Ubuntu base similar to Travis CI's "trusty" (but updated for modern packages)
FROM ubuntu:20.04

LABEL maintainer="Dawson Tennant <davy.lsdev@gmail.com>"
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
        libncurses5 \
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
        python3 \
        python3-pip \
        vim-tiny \
        ca-certificates \
        && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# CRITICAL FIX for older NDKs (like r17c): Install libtinfo.so.5 dependency
# This library is required by the older NDK clang/toolchain executables.
    
# Ensure 'python' command points to the installed 'python3' executable
RUN which python3 && ln -sf $(which python3) /usr/local/bin/python

# --------------------------------------------------
# Default working directory inside container
# --------------------------------------------------
WORKDIR /workspace

# Allow Git to trust /workspace directory ownership
RUN git config --system --add safe.directory /workspace

# --------------------------------------------------
# Set up Android SDK and NDK (mimicking Travis)
# --------------------------------------------------
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
RUN groupadd -r builder && useradd -r -g builder -u 1000 builder
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
        "platforms;android-28" \
        "build-tools;28.0.3" \
        "cmake;3.10.2.4988404" \
        "ndk;17.2.4988734"
# downgraded to build v4.2.LTS from:        "ndk;21.3.6528147"

# Grant write access to the entire SDK folder for all users.
# This ensures that ANY user, including the one imported via '--user', 
# can install or update components.
RUN chmod -R a+rwX /opt/android-sdk

# 1. Define a standard, non-root user (builder) and its home directory
# The fixed UID (1000) here is for internal consistency, but its ID won't match Bob's for example.
# We keep it simple and non-root.
RUN (getent group builder || groupadd -r builder) && \
    (getent passwd builder || useradd -r -g builder -u 1000 builder)

# 2. Create the home directory that the '-e HOME' flag will point to.
RUN mkdir -p /home/builder/.gradle && \
    chown -R builder:builder /home/builder

# 3. CRITICAL STEP: Grant write permissions to the HOME and Workspace directories 
# for 'others' (the anonymous host UID, i.e., Bob).
# This is required so Bob (UID 1002) can write his cache to this directory.
RUN chmod -R a+rwX /home/builder /workspace

# --------------------------------------------------
# Accept licenses and install required SDK/NDK components
# --------------------------------------------------
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses || true && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platform-tools" \
        "platforms;android-28" \
        "build-tools;28.0.3" \
        "cmake;3.10.2.4988404" \
        "ndk;17.2.4988734"
# downgraded from:        "ndk;21.3.6528147"

# --------------------------------------------------
# Install NASM (same as travis)
# --------------------------------------------------
RUN wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz && \
    tar zxvf nasm-2.14.02.tar.gz && \
    cd nasm-2.14.02 && \
    ./configure && make -j$(nproc) && make install && \
    cd .. && rm -rf nasm-2.14.02*

# --------------------------------------------------
# Entry point
# --------------------------------------------------
CMD ["/bin/bash"]
