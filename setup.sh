#!/bin/bash
set -e

NDK_VERSION="r26d"
NDK_ZIP="android-ndk-${NDK_VERSION}-linux.zip"
NDK_DIR="$PWD/android-ndk-${NDK_VERSION}"
NDK_URL="https://dl.google.com/android/repository/${NDK_ZIP}"

PACKAGES=(build-essential clang llvm make cmake pkg-config autoconf automake libtool unzip curl wget git python3)

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        sudo apt-get install -y "$pkg"
    fi
done

if [ ! -d "$NDK_DIR" ]; then
    if [ ! -f "$NDK_ZIP" ]; then
        wget -q --show-progress "$NDK_URL"
    fi
    unzip -q "$NDK_ZIP"
fi

export ANDROID_NDK="$NDK_DIR"
export TOOLCHAIN="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64"
export PATH="$TOOLCHAIN/bin:$PATH"

ls "$TOOLCHAIN/bin" | grep -q clang || { echo "Toolchain missing!"; exit 1; }

echo "NDK setup done"
echo "ANDROID_NDK=$ANDROID_NDK"
echo "TOOLCHAIN=$TOOLCHAIN"

