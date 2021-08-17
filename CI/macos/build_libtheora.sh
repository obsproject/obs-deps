#!/bin/bash

##############################################################################
# macOS libtheora build script
##############################################################################
#
# This script file can be included in build scripts for macOS or run directly
#
##############################################################################

# Halt on errors
set -eE

_build_product() {
    cd "${PRODUCT_FOLDER}"
    BASE_DIR="$(pwd)"

    if [ "${ARCH}" = "x86_64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_x86_64"
        cd "${BASE_DIR}/build_x86_64"

        step "Configure (x86_64)..."
        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-static \
            --disable-shared --disable-oggtest --disable-vorbistest --disable-examples \
            --prefix="${BUILD_DIR}" --host="x86_64-apple-darwin" CFLAGS="-arch x86_64"
        step "Build (x86_64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "arm64" -o "${ARCH}" = "universal" ]; then
        mkdir -p "${BASE_DIR}/build_arm64"
        cd "${BASE_DIR}/build_arm64"

        step "Configure (arm64)..."
        PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ../configure \
            --enable-static \
            --disable-shared --disable-oggtest --disable-vorbistest --disable-examples \
            --prefix="${BUILD_DIR}" --host="arm-apple-darwin20" CFLAGS="-arch arm64"
        step "Build (arm64)..."
        make -j${PARALLELISM}
    fi

    if [ "${ARCH}" = "universal" ]; then
        step "Create universal binaries..."
        cp -cpR "${BASE_DIR}/build_x86_64" "${BASE_DIR}/build_universal"
        cd "${BASE_DIR}/build_universal"
        lipo -create ../build_x86_64/lib/.libs/libtheoraenc.a ../build_arm64/lib/.libs/libtheoraenc.a -output ./lib/.libs/libtheoraenc.a
        lipo -create ../build_x86_64/lib/.libs/libtheora.a ../build_arm64/lib/.libs/libtheora.a -output ./lib/.libs/libtheora.a
        lipo -create ../build_x86_64/lib/.libs/libtheoradec.a ../build_arm64/lib/.libs/libtheoradec.a -output ./lib/.libs/libtheoradec.a
    fi
}

_install_product() {
    cd "${PRODUCT_FOLDER}/build_${ARCH}"

    step "Install (${ARCH})..."
    make install
}

build-libtheora-main() {
    PRODUCT_NAME="${PRODUCT_NAME:-libtheora}"

    if [ -z "${_RUN_OBS_BUILD_SCRIPT}" ]; then
        CHECKOUT_DIR="$(/usr/bin/git rev-parse --show-toplevel)"
        source "${CHECKOUT_DIR}/CI/include/build_support.sh"
        source "${CHECKOUT_DIR}/CI/include/build_support_macos.sh"

        _check_parameters $*
        _build_checks
    fi

    PRODUCT_URL="https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-${PRODUCT_VERSION:-${CI_PRODUCT_VERSION}}.tar.xz"
    PRODUCT_FILENAME="$(basename "${PRODUCT_URL}")"
    PRODUCT_FOLDER="${PRODUCT_FILENAME%.*.*}"

    if [ -z "${INSTALL}" ]; then
        _add_ccache_to_path
        _build_setup
        _build
    else
        _install_product
    fi
}

build-libtheora-main $*
