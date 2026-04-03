#!/bin/bash
set -e

source setup.sh

PACKAGE_NAME=com.logicodeum.ide
PREFIX="data/data/$PACKAGE_NAME/files/usr"

NDK=$ANDROID_NDK
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
SYSROOT="$TOOLCHAIN/sysroot"

DEPS_DIR="$PWD/deps"

fetch_dep() {
    NAME=$1
    URL=$2

    DEST="$DEPS_DIR/$NAME"

    if [ ! -d "$DEST" ]; then
        echo "[*] Fetching dependency: $NAME"
        mkdir -p "$DEPS_DIR"

        TMP_ZIP="$DEPS_DIR/$NAME.zip"
        wget -O "$TMP_ZIP" "$URL"

        unzip -q "$TMP_ZIP" -d "$DEST"
        rm -f "$TMP_ZIP"

        echo "[✓] $NAME ready at $DEST"
    else
        echo "[=] Using cached dependency: $NAME"
    fi
}


# Dependecy declaration
LIBCXX_NAME="libcxx"
LIBCXX_URL="https://github.com/Innovative-cst-debug/libcpp/releases/download/1.0/libcpp.zip"

fetch_dep "$LIBCXX_NAME" "$LIBCXX_URL"

# Build function
build() {
    ARCH=$1

    case $ARCH in
        arm64) TARGET=aarch64-linux-android; API=24 ;;
        arm)   TARGET=armv7a-linux-androideabi; API=21 ;;
        x86)   TARGET=i686-linux-android; API=21 ;;
        x86_64) TARGET=x86_64-linux-android; API=24 ;;
        *) exit 1 ;;
    esac

    export CC="$TOOLCHAIN/bin/${TARGET}${API}-clang"
    export CXX="$TOOLCHAIN/bin/${TARGET}${API}-clang++"
    export AR="$TOOLCHAIN/bin/llvm-ar"

    BUILD_DIR="build-$ARCH"
    INSTALL_DIR="$PWD/$BUILD_DIR/install/$PREFIX"

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    rsync -a \
        --exclude='android-ndk-*' \
        --exclude='build-*' \
        --exclude='deps' \
        ../ .

    LIBCXX_ROOT="$DEPS_DIR/$LIBCXX_NAME"
    LIBCXX_LIB="$LIBCXX_ROOT/build-$ARCH/install/$PREFIX/lib"

    export CFLAGS="--sysroot=$SYSROOT -fPIC -DANDROID"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="--sysroot=$SYSROOT -L$LIBCXX_LIB -lc++_shared"

    $CXX $CFLAGS -I. -c posix_spawn.cpp -o posix_spawn.o
    $CXX $LDFLAGS -shared posix_spawn.o -o libandroid-spawn.so
    $AR rcu libandroid-spawn.a posix_spawn.o

    mkdir -p "$INSTALL_DIR/include" "$INSTALL_DIR/lib"

    cp posix_spawn.h "$INSTALL_DIR/include/spawn.h"
    cp libandroid-spawn.a "$INSTALL_DIR/lib/"
    cp libandroid-spawn.so "$INSTALL_DIR/lib/"

    cd ..

    echo "[✓] Build successful for $ARCH"
    echo "    Install path: $INSTALL_DIR"
    echo
}

# Build all architectures
for arch in arm64 arm x86 x86_64; do
    build $arch
done

echo "[✓] Build complete"
